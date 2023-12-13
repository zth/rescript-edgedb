@@directive("#!/usr/bin/env node")

module Path = NodeJs.Path

@module("edgedb/dist/conUtils.js")
external validTlsSecurityValues: array<string> = "validTlsSecurityValues"

@module("edgedb/dist/conUtils.js")
external parseConnectArguments: EdgeDB.Client.connectConfig => promise<
  EdgeDB.Client.normalizedConnectConfig,
> = "parseConnectArguments"

let adapter = EdgeDbGenerator__Utils.adapter
module EdgeDbUtils = EdgeDbGenerator__Utils

let usage = `Usage:
  generate                                                | Generates all EdgeDB code.
    [--output <path>]                                     | Where to emit all generated files.
    [--src <path>]                                        | The source folder for where to look for ReScript files.
    [--watch]                                             | Runs this command in watch mode.
    
  unused-selections                                       | Check if we there are unused selections in your EdgeQL queries.
    [--ci]                                                | Run in CI mode.`

type config = {client: EdgeDB.Client.t}

type errorInFile = {
  startLoc: RescriptEmbedLang.loc,
  endLoc: RescriptEmbedLang.loc,
  errorMessage: string,
}

let isInConfigDir = async () => {
  let bsconfig = Path.resolve([adapter.process.cwd(), "bsconfig.json"])
  let rescriptJson = Path.resolve([adapter.process.cwd(), "rescript.json"])

  try {
    await adapter.fs.access(bsconfig)
    true
  } catch {
  | Exn.Error(_) =>
    try {
      await adapter.fs.access(rescriptJson)
      true
    } catch {
    | Exn.Error(_) => false
    }
  }
}

let main = async () => {
  let errors = Map.make()

  let syncErrors = async () => {
    let isInConfigDir = await isInConfigDir()

    if isInConfigDir {
      let errorsFile = Path.resolve([adapter.process.cwd(), "lib", "bs", ".generator.edgeql.log"])
      NodeJs.Fs.writeFileSync(
        errorsFile,
        errors
        ->Map.entries
        ->Iterator.toArray
        ->Array.map(((filePath, errorMap)) =>
          {
            "filePath": filePath,
            "errors": errorMap->Dict.valuesToArray,
          }
        )
        ->Array.reduce(Dict.make(), (dict, curr) => {
          dict->Dict.set(curr["filePath"], curr["errors"])
          dict
        })
        ->JSON.stringifyAny
        ->Option.getWithDefault("")
        ->NodeJs.Buffer.fromString,
      )
    }
  }

  let pruneErrorsForModuleInFile = (~path, ~moduleName) =>
    switch errors->Map.get(path) {
    | None => ()
    | Some(fileErrors) =>
      switch moduleName {
      | None => ()
      | Some(moduleName) => fileErrors->Dict.delete(moduleName)
      }
    }

  let setErrorForModuleInFile = (~path, ~error: errorInFile, ~moduleName) =>
    switch moduleName {
    | Some(moduleName) =>
      switch errors->Map.get(path) {
      | None =>
        let fileErrors = Dict.fromArray([(moduleName, error)])
        errors->Map.set(path, fileErrors)
      | Some(fileErrors) => fileErrors->Dict.set(moduleName, error)
      }
    | None => ()
    }

  let emitter = RescriptEmbedLang.make(
    ~extensionPattern=FirstClass("edgeql"),
    ~cliHelpText=usage,
    ~setup=async ({args}) => {
      let howToGetPassword = switch (
        args->RescriptEmbedLang.CliArgs.hasArg("--password"),
        args->RescriptEmbedLang.CliArgs.hasArg("--password-from-stdin"),
      ) {
      | (true, true) => panic(`Cannot use both --password and --password-from-stdin options`)
      | (true, false) => Some(#PromptPassword)
      | (false, true) => Some(#FromStdin)
      | (false, false) => None
      }

      let options: EdgeDB.Client.connectOptions = {
        concurrency: 5,
        dsn: ?args->RescriptEmbedLang.CliArgs.getArgValue(["-I", "--instance", "--dsn"]),
        credentialsFile: ?args->RescriptEmbedLang.CliArgs.getArgValue(["--credentials-file"]),
        host: ?args->RescriptEmbedLang.CliArgs.getArgValue(["-H", "--host"]),
        port: ?(
          args
          ->RescriptEmbedLang.CliArgs.getArgValue(["-P", "--port"])
          ->Option.flatMap(port => Int.fromString(port))
        ),
        database: ?args->RescriptEmbedLang.CliArgs.getArgValue(["-d", "--database"]),
        user: ?args->RescriptEmbedLang.CliArgs.getArgValue(["-u", "--user"]),
        tlsCAFile: ?args->RescriptEmbedLang.CliArgs.getArgValue(["--tls-ca-file"]),
        tlsSecurity: ?switch args->RescriptEmbedLang.CliArgs.getArgValue(["--tls-security"]) {
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
            Some(await EdgeDbUtils.promptForPassword(username))
          | Some(#FromStdin) => Some(await EdgeDbUtils.readPasswordFromStdin())
          },
        },
      )

      {client: client}
    },
    ~handleOtherCommand=async ({args, command}) => {
      switch command {
      | "unused-selections" =>
        let ci = args->RescriptEmbedLang.CliArgs.hasArg("--ci")

        if !(await isInConfigDir()) {
          Console.error(`Could not find bsconfig.json or rescript.json. This command needs to run in the same directory as bsconfig.json or rescript.json.`)
          adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
        }

        Console.log("Analyzing project... (this might take a while)")

        let results = await UnusedSelections.readReanalyzeOutput()

        UnusedSelections.reportResults(results)

        if ci && results->Array.length > 0 {
          adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
        }
      | _ => ()
      }
    },
    ~generate=async ({config, content, path, location}) => {
      open EdgeDbGenerator

      let moduleName =
        content
        ->String.split("# @name ")
        ->Array.get(1)
        ->Option.getWithDefault("")
        ->String.split(" ")
        ->Array.get(0)
        ->Option.map(EdgeDbGenerator__Utils.capitalizeString)
        ->Option.map(String.trim)

      let types = switch await config.client->AnalyzeQuery.analyzeQuery(content, ~path="") {
      | Ok(types) =>
        pruneErrorsForModuleInFile(~path, ~moduleName)
        types
      | Error(errorMessage) =>
        let error = Utils.Errors.extractFromString(
          errorMessage,
          ~startLoc=(location.start :> Utils.Errors.loc),
        )

        switch error {
        | None =>
          /* Set error loc to generic error */
          let lines = content->String.split("\n")
          let lineCount = ref(0)
          let break = ref(false)
          let loc = ref(None)
          while !break.contents {
            let currentLineCount = lineCount.contents
            lineCount := currentLineCount + 1
            let line = lines->Array.get(currentLineCount)->Option.getWithDefault("")
            if line->String.includes("@name") {
              switch line->String.split("# @name ") {
              | [before, _after] =>
                let col = before->String.length + "# @name "->String.length
                loc :=
                  Some((
                    {
                      Utils.Errors.line: currentLineCount,
                      col,
                    },
                    {
                      Utils.Errors.line: currentLineCount,
                      col: line->String.length,
                    },
                  ))
              | _ => ()
              }
            }

            if lineCount.contents > lines->Array.length {
              break := true
            }
          }

          switch loc.contents {
          | None => ()
          | Some((startLoc, endLoc)) =>
            setErrorForModuleInFile(
              ~path,
              ~error={
                errorMessage,
                startLoc: {
                  line: startLoc.line + location.start.line,
                  col: startLoc.col,
                },
                endLoc: {
                  line: endLoc.line + location.start.line,
                  col: endLoc.col,
                },
              },
              ~moduleName,
            )
          }
        | Some(error) =>
          setErrorForModuleInFile(
            ~path,
            ~error={
              errorMessage: error.text,
              startLoc: {
                line: error.start.line,
                col: error.start.col,
              },
              endLoc: {
                line: error.end.line,
                col: error.end.col,
              },
            },
            ~moduleName,
          )
        }

        let distinctTypes = Set.make()
        distinctTypes->Set.add("type lookAboveForDetails = this_query_has_EdgeQL_errors")
        {
          args: "unit",
          result: "",
          cardinality: ONE,
          query: `/*\n${errorMessage}\n*/`,
          distinctTypes,
        }
      }

      let fileOutput = []
      let (method, returnType, extraInFnArgs, extraInFnApply) = switch types.cardinality {
      | ONE => (
          "singleRequired",
          "promise<result<response, EdgeDB.Error.errorFromOperation>>",
          "",
          "",
        )
      | AT_MOST_ONE => ("single", "promise<option<response>>", ", ~onError=?", ", ~onError?")
      | _ => ("many", "promise<array<response>>", "", "")
      }
      let hasArgs = types.args !== "null"
      let queryText = types.query->String.trim->String.replaceRegExp(%re("/`/g"), "\\`")
      fileOutput->Array.push(
        `let queryText = \`${queryText}\`

${types.distinctTypes->Set.values->Iterator.toArray->Array.joinWith("\n\n")}

let query = (client: EdgeDB.Client.t${hasArgs
            ? `, args: args`
            : ""}${extraInFnArgs}): ${returnType} => {
  client->EdgeDB.QueryHelpers.${method}(queryText${hasArgs ? ", ~args" : ""}${extraInFnApply})
}

let transaction = (transaction: EdgeDB.Transaction.t${hasArgs
            ? `, args: args`
            : ""}${extraInFnArgs}): ${returnType} => {
  transaction->EdgeDB.TransactionHelpers.${method}(queryText${hasArgs
            ? ", ~args"
            : ""}${extraInFnApply})
}`,
      )
      let content = fileOutput->Array.joinWith("")

      // Sync errors
      syncErrors()->Promise.done

      switch moduleName {
      | Some(moduleName) => Ok({RescriptEmbedLang.WithModuleName({content, moduleName})})
      | None => Error("Could not find query name.")
      }
    },
    ~onWatch=async ({config, runGeneration, debug}) => {
      let migrationsCount = ref(-1)

      let checkForSchemaChanges = async () => {
        try {
          debug("[schema change detection] Polling for schema changes...")
          let migrations =
            (await config.client
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

      setInterval(() => {
        checkForSchemaChanges()->Promise.done
      }, 5000)->ignore
    },
  )

  RescriptEmbedLang.runCli(emitter)
}

main()->Promise.done
