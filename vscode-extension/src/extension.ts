import { readFileSync } from "fs";
import path from "path";
import {
  ExtensionContext,
  workspace,
  languages,
  Uri,
  Diagnostic,
  DiagnosticSeverity,
  Range,
  Position,
} from "vscode";

export async function activate(context: ExtensionContext) {
  let currentWorkspacePath = workspace.workspaceFolders?.[0].uri.fsPath;
  if (currentWorkspacePath == null) throw new Error("Init failed.");

  const files = await workspace.findFiles(
    "**/.generator.edgeql.log",
    "**/node_modules/**",
    10
  );

  const watchers = files
    .reduce((uniquePaths: Array<string>, filePath) => {
      const dir = path.dirname(filePath.fsPath);

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
          const contents = readFileSync(
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

export function deactivate() {}
