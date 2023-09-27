@@directive("#!/usr/bin/env node")

@val
external argv: array<option<string>> = "process.argv"

let args = argv->Array.sliceToEnd(~start=2)->Array.filterMap(arg => arg)

@module("edgedb/dist/conUtils.js")
external validTlsSecurityValues: array<string> = "validTlsSecurityValues"

@module("edgedb/dist/conUtils.js")
external parseConnectArguments: EdgeDB.Client.connectConfig => promise<
  EdgeDB.Client.normalizedConnectConfig,
> = "parseConnectArguments"

let adapter = EdgeDbGenerator__Utils.adapter
module EdgeDbUtils = EdgeDbGenerator__Utils

let isTTY = () => {
  adapter.process.stdin.isTTY && adapter.process.stdout.isTTY
}

let promptForPassword = async (username: string) => {
  if !isTTY() {
    panic(
      `Cannot use --password option in non-interactive mode. ` ++ `To read password from stdin use the --password-from-stdin option.`,
    )
  }

  await adapter.input(`Password for '${username}': `, ~params={silent: true})
}

let readPasswordFromStdin = () => {
  if adapter.process.stdin.isTTY {
    panic(`Cannot read password from stdin: stdin is a TTY.`)
  }

  Promise.make((resolve, _reject) => {
    let data = ref("")
    adapter.process.stdin->EdgeDbUtils.Adapter.onData(chunk => data := data.contents ++ chunk)
    adapter.process.stdin->EdgeDbUtils.Adapter.onEnd(() => resolve(data.contents->String.trimEnd))
  })
}

let debugging = ref(false)
let debug = msg =>
  if debugging.contents {
    Console.debug(msg)
  }

let usage = `Usage:
  generate                                                | Generates all EdgeDB code.
    [--output <path>]                                     | Where to emit all generated files.
    [--src <path>]                                        | The source folder for where to look for ReScript files.
    [--watch]                                             | Runs this command in watch mode.
    
  unused-selections                                       | Check if we there are unused selections in your EdgeQL queries.
    [--ci]                                                | Run in CI mode.`

let main = async () => {
  switch args->List.fromArray {
  | list{"--help" | "-h", ..._rest} => Console.log(usage)
  | list{"unused-selections", ...options} =>
    let args = options->List.toArray
    debugging := args->CliUtils.hasArg("--debug")
    let ci = args->CliUtils.hasArg("--ci")
    let bsconfig =
      adapter.path->EdgeDbGenerator__Utils.Adapter.resolve([adapter.process.cwd(), "bsconfig.json"])
    try {
      // Try to access the directory
      await adapter.fs.access(bsconfig)
    } catch {
    | Exn.Error(_) =>
      Console.error(`Could not find bsconfig.json. This command needs to run in the same directory as bsconfig.json.`)
      adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
    }

    Console.log("Analyzing project... (this might take a while)")

    let results = await UnusedSelections.readReanalyzeOutput()

    UnusedSelections.reportResults(results)

    if ci && results->Array.length > 0 {
      adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
    }
  | list{"generate", ...options} =>
    open EdgeDbGenerator

    let args = options->List.toArray
    debugging := args->CliUtils.hasArg("--debug")

    let root = await findEdgeDbRoot()
    let watch = args->CliUtils.hasArg("--watch")
    let pathToGeneratedDir = switch args->CliUtils.getArgValue(["--output"]) {
    | None =>
      panic(`--output must be set. It controls into what directory all generated files are emitted.`)
    | Some(outputDir) =>
      let joined = adapter.path->EdgeDbUtils.Adapter.join([adapter.process.cwd(), outputDir])
      adapter.path->EdgeDbUtils.Adapter.resolve([joined])
    }
    let src = switch args->CliUtils.getArgValue(["--src"]) {
    | None => panic(`--src must be set. It controls where to look for source ReScript files.`)
    | Some(src) =>
      let joined = adapter.path->EdgeDbUtils.Adapter.join([adapter.process.cwd(), src])
      adapter.path->EdgeDbUtils.Adapter.resolve([joined])
    }

    try {
      // Try to access the directory
      await adapter.fs.access(pathToGeneratedDir)
    } catch {
    | Exn.Error(_) =>
      Console.log(`Output directory did not exist. Creating now...`)
      await adapter.fs.mkdir(pathToGeneratedDir, {recursive: true})
    }

    let howToGetPassword = switch (
      args->CliUtils.hasArg("--password"),
      args->CliUtils.hasArg("--password-from-stdin"),
    ) {
    | (true, true) => panic(`Cannot use both --password and --password-from-stdin options`)
    | (true, false) => Some(#PromptPassword)
    | (false, true) => Some(#FromStdin)
    | (false, false) => None
    }

    let options: EdgeDB.Client.connectOptions = {
      concurrency: 5,
      dsn: ?args->CliUtils.getArgValue(["-I", "--instance", "--dsn"]),
      credentialsFile: ?args->CliUtils.getArgValue(["--credentials-file"]),
      host: ?args->CliUtils.getArgValue(["-H", "--host"]),
      port: ?(
        args->CliUtils.getArgValue(["-P", "--port"])->Option.flatMap(port => Int.fromString(port))
      ),
      database: ?args->CliUtils.getArgValue(["-d", "--database"]),
      user: ?args->CliUtils.getArgValue(["-u", "--user"]),
      tlsCAFile: ?args->CliUtils.getArgValue(["--tls-ca-file"]),
      tlsSecurity: ?switch args->CliUtils.getArgValue(["--tls-security"]) {
      | Some(tlsSec) =>
        if !(validTlsSecurityValues->Array.includes(tlsSec)) {
          panic(
            `Invalid value for --tls-security. Must be one of: ${validTlsSecurityValues
              ->Array.map(x => `"${x}"`)
              ->Array.joinWith(" | ")}`,
          )
        } else {
          switch tlsSec {
          | "insecure" => Some(Insecure)
          | "no_host_verification" => Some(NoHostVerification)
          | "strict" => Some(Strict)
          | "default" => Some(Default)
          | _ => None
          }
        }

      | None => None
      },
    }

    let client = EdgeDB.Client.make(
      ~options={
        ...options,
        password: ?switch howToGetPassword {
        | None => None
        | Some(#PromptPassword) =>
          let username = (
            await parseConnectArguments({
              ...(options :> EdgeDB.Client.connectConfig),
              password: "",
            })
          ).connectionParams.user
          Some(await promptForPassword(username))
        | Some(#FromStdin) => Some(await readPasswordFromStdin())
        },
      },
    )

    let noRoot = root->Option.isNone
    let root = switch root {
    | Some(root) => root
    | None => adapter.process.cwd()
    }

    let runGeneration = async (~files=?) => {
      Console.time("Generated files in")
      await EdgeDbGenerator.generateQueryFiles(
        ~client,
        ~root,
        ~noRoot,
        ~files?,
        ~outputDir=pathToGeneratedDir,
        ~debug=debugging.contents,
      )
      Console.timeEnd("Generated files in")
    }

    if watch {
      open CliBindings

      let migrationsCount = ref(-1)

      let checkForSchemaChanges = async () => {
        try {
          debug("[schema change detection] Polling for schema changes...")
          let migrations =
            (await client
            ->EdgeDB.QueryHelpers.single("select count(schema::Migration)"))
            ->Option.getWithDefault(-1)

          debug(`[schema change detection] Found ${migrations->Int.toString} migrations`)
          let currentMigrationsCount = migrationsCount.contents
          migrationsCount := migrations

          if currentMigrationsCount > -1 && migrations !== migrationsCount.contents {
            Console.log("Detected changes to EdgeDB schema. Regenerating queries...")
            migrationsCount := migrations
            await runGeneration()
          }
        } catch {
        | Exn.Error(_) => ()
        }
      }

      let _pollForSchemaChanges = setInterval(() => {
        checkForSchemaChanges()->Promise.done
      }, 5000)

      await runGeneration()
      Console.log(`Watching for changes in ${src}...`)

      let _theWatcher =
        Chokidar.watcher
        ->Chokidar.watch(
          `${src}/**/*.res`,
          ~options={
            ignored: ["**/node_modules", pathToGeneratedDir],
            ignoreInitial: true,
          },
        )
        ->Chokidar.Watcher.onChange(async file => {
          debug(`[changed]: ${file}`)
          await runGeneration(~files=[file])
        })
        ->Chokidar.Watcher.onAdd(async file => {
          debug(`[added]: ${file}`)
          await runGeneration(~files=[file])
        })
        ->Chokidar.Watcher.onUnlink(async file => {
          debug(`[deleted]: ${file}`)
          // Remove if accompanying generated file if it exists
          let asGeneratedFile = file->EdgeDbGenerator.getOutputBaseFileName ++ ".res"
          let fileBaseName = file->EdgeDbUtils.adapter.path.basename(".res")

          let potentialGeneratedFile = EdgeDbGenerator.filePathInGeneratedDir(
            asGeneratedFile,
            ~outputDir=pathToGeneratedDir,
          )

          if await adapter.exists(potentialGeneratedFile) {
            Console.log(
              `Deleting generated file "${asGeneratedFile}" that belonged to ${fileBaseName}.res...`,
            )
            await adapter.fs.unlink(potentialGeneratedFile)
          }
        })
    } else {
      await runGeneration()
    }

  | _ => Console.log(usage)
  }
}

main()->Promise.done
