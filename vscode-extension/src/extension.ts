import * as childProcess from "child_process";
import * as os from "os";
import * as fs from "fs";
import * as path from "path";
import * as dotenv from "dotenv";
import {
  ExtensionContext,
  workspace,
  languages,
  Uri,
  Diagnostic,
  DiagnosticSeverity,
  Range,
  Position,
  TextDocument,
  window,
  commands,
  env,
} from "vscode";

let tempFilePrefix = "rescript_edgedb_" + process.pid + "_";
let tempFileId = 0;

function createFileInTempDir() {
  let tempFileName = tempFilePrefix + tempFileId + ".res";
  tempFileId = tempFileId + 1;
  return path.join(os.tmpdir(), tempFileName);
}

function findProjectPackageJsonRoot(source: string): null | string {
  let dir = path.dirname(source);
  if (fs.existsSync(path.join(dir, "package.json"))) {
    return dir;
  } else {
    if (dir === source) {
      // reached top
      return null;
    } else {
      return findProjectPackageJsonRoot(dir);
    }
  }
}

async function setupErrorLogWatcher(context: ExtensionContext) {
  const rootFiles = await workspace.findFiles(
    "**/{bsconfig,rescript}.json",
    "**/node_modules/**",
    10
  );

  const watchers = rootFiles
    .reduce((uniquePaths: Array<string>, filePath) => {
      const dir = path.resolve(path.dirname(filePath.fsPath), "lib/bs");

      if (!uniquePaths.includes(dir)) {
        uniquePaths.push(dir);
      }

      return uniquePaths;
    }, [])
    .map((dir) => {
      const watcher = workspace.createFileSystemWatcher(
        `${dir}/.generator.edgeql.log`
      );

      const diagnostics = languages.createDiagnosticCollection("edgedb");

      function syncDiagnostics() {
        try {
          const contents = fs.readFileSync(
            path.resolve(dir, ".generator.edgeql.log"),
            "utf-8"
          );
          const parsed: Record<
            string,
            Array<{
              startLoc: { line: number; col: number };
              endLoc: { line: number; col: number };
              errorMessage: string;
            }>
          > = JSON.parse(contents);

          // Clear diagnostics no longer present
          diagnostics.forEach((uri, _) => {
            const inParsed = parsed[uri.fsPath];
            if (inParsed?.length === 0) {
              diagnostics.delete(uri);
            }
          });

          Object.entries(parsed).forEach(([filePath, errors]) => {
            if (errors.length > 0) {
              diagnostics.set(
                Uri.parse(filePath),
                errors.map(
                  (err) =>
                    new Diagnostic(
                      new Range(
                        new Position(err.startLoc.line, err.startLoc.col),
                        new Position(err.endLoc.line, err.endLoc.col)
                      ),
                      err.errorMessage,
                      DiagnosticSeverity.Error
                    )
                )
              );
            }
          });
        } catch (e) {
          diagnostics.clear();
          console.error(e);
        }
      }

      watcher.onDidChange((_) => {
        syncDiagnostics();
      });

      watcher.onDidCreate((_) => {
        syncDiagnostics();
      });

      watcher.onDidDelete((_) => {
        diagnostics.clear();
      });

      // Initial sync
      syncDiagnostics();

      return {
        watcher,
        diagnostics,
      };
    });

  context.subscriptions.push(
    ...watchers.map(({ watcher }) => ({
      dispose: () => watcher.dispose(),
    }))
  );
}

type dataFromFile = {
  content: string;
  start: { line: number; col: number };
  end: { line: number; col: number };
  tag: string;
};

const edgeqlContent: Map<string, dataFromFile[]> = new Map();

function callRescriptEdgeDBCli(command: string[], cwd: string) {
  const dotEnvLoc = path.join(cwd, ".env");
  const dotEnvExists = fs.existsSync(dotEnvLoc);
  const env = dotEnvExists ? dotenv.config({ path: dotEnvLoc }) : null;

  return childProcess.execFileSync(
    "./node_modules/.bin/rescript-edgedb",
    command,
    {
      cwd: cwd,
      env: {
        ...process.env,
        ...env?.parsed,
      },
    }
  );
}

function updateContent(e: TextDocument) {
  if (e.languageId === "rescript") {
    const text = e.getText();
    const cwd = findProjectPackageJsonRoot(e.fileName);
    if (cwd != null && text.includes("%edgeql(")) {
      const tempFile = createFileInTempDir();
      fs.writeFileSync(tempFile, text);
      try {
        const dataFromCli = callRescriptEdgeDBCli(["extract", tempFile], cwd);
        const data: dataFromFile[] = JSON.parse(dataFromCli.toString());
        edgeqlContent.set(e.fileName, data);
      } catch (e) {
        console.error(e);
      } finally {
        fs.rmSync(tempFile);
      }
    } else {
      edgeqlContent.delete(e.fileName);
    }
  }
}

async function setupCodeActions(context: ExtensionContext) {
  context.subscriptions.push(
    workspace.onDidOpenTextDocument((e) => {
      updateContent(e);
    })
  );
  context.subscriptions.push(
    workspace.onDidCloseTextDocument((e) => {
      updateContent(e);
    })
  );
  context.subscriptions.push(
    workspace.onDidChangeTextDocument((e) => {
      updateContent(e.document);
    })
  );
}

export async function activate(context: ExtensionContext) {
  let currentWorkspacePath = workspace.workspaceFolders?.[0].uri.fsPath;
  if (currentWorkspacePath == null) throw new Error("Init failed.");

  await Promise.all([setupErrorLogWatcher(context), setupCodeActions(context)]);

  context.subscriptions.push(
    commands.registerCommand(
      "vscode-rescript-edgedb-open-ui",
      async (query: string, cwd: string) => {
        const url = JSON.parse(
          callRescriptEdgeDBCli(["ui-url"], cwd).toString()
        );
        const lines = query.trim().split("\n");
        // First line has the comment with the query name, so the second line will have the offset
        const offset = lines[1].match(/^\s*/)?.[0].length ?? 0;
        const offsetAsStr = Array.from({ length: offset })
          .map((_) => " ")
          .join("");

        await env.clipboard.writeText(
          lines
            .map((l) => {
              const leadingWhitespace = l.slice(0, offset);
              if (leadingWhitespace === offsetAsStr) {
                return l.slice(offset);
              }

              return l;
            })
            .join("\n")
        );
        window.showInformationMessage(
          "The EdgeQL query was copied to the clipboard!\nOpening the EdgeDB UI in the browser..."
        );
        env.openExternal(Uri.parse(`${url}/editor`));
      }
    )
  );

  context.subscriptions.push(
    languages.registerCodeActionsProvider(
      {
        language: "rescript",
      },
      {
        provideCodeActions(document, range, _context, _token) {
          const cwd = findProjectPackageJsonRoot(document.fileName);
          const contentInFile = edgeqlContent.get(document.fileName) ?? [];
          const targetWithCursor = contentInFile.find((c) => {
            const start = new Position(c.start.line, c.start.col);
            const end = new Position(c.end.line, c.end.col);
            return (
              range.start.isAfterOrEqual(start) &&
              range.end.isBeforeOrEqual(end)
            );
          });

          if (targetWithCursor != null && cwd != null) {
            return [
              {
                title: "Open the EdgeDB UI query editor",
                command: "vscode-rescript-edgedb-open-ui",
                arguments: [targetWithCursor.content, cwd],
                tooltip: "The EdgeQL query will be copied to the clipboard.",
              },
            ];
          }

          return [];
        },
      }
    )
  );
}

export function deactivate() {}
