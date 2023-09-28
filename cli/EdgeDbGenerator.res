/* Most things in here are (loosely) ported from the existing `edgedb-js` tooling to ReScript. */
open EdgeDbGenerator__Utils
module Fs = NodeJs.Fs
module Path = NodeJs.Path
module Process = NodeJs.Process

let rescriptExtensionPointRegex: RegExp.t = %re("/%edgeql\(`\s*#\s*@name\s+(.+)\s+([^`]+)`\)/g")

@send
external matchAll: (string, RegExp.t) => Iterator.t<array<string>> = "matchAll"

type fileToGenerate = {
  path: string,
  hash: string,
  contents: string,
}

type cardinality =
  | @as(0x6e) NO_RESULT
  | @as(0x6f) AT_MOST_ONE
  | @as(0x41) ONE
  | @as(0x6d) MANY
  | @as(0x4d) AT_LEAST_ONE

let generateSetType = (typ: string, cardinality: cardinality): string => {
  switch cardinality {
  | AT_LEAST_ONE
  | MANY =>
    `array<${typ}>`
  | ONE => typ
  | AT_MOST_ONE => `Null.t<${typ}>`
  | NO_RESULT => panic(`Unexpected cardinality: ${(cardinality :> int)->Int.toString}`)
  }
}

module Codec = {
  type t

  type objectFieldInfo = {
    name: string,
    implicit: bool,
    linkprop: bool,
    cardinality: cardinality,
  }

  @unboxed
  type codecKind =
    | @as("array") Array
    | @as("tuple") Tuple
    | @as("namedtuple") NamedTuple
    | @as("object") Object
    | @as("set") Set
    | @as("scalar") Scalar
    | @as("sparse_object") SparseObject
    | @as("range") Range
    | FutureAddedCodec(string)

  @get external tsType: t => string = "tsType"
  @get external values: t => array<string> = "values"
  @send external getSubcodecs: t => array<t> = "getSubcodecs"
  @send external getFields: t => array<objectFieldInfo> = "getFields"
  @send external getNames: t => array<string> = "getNames"
  @send external getKind: t => codecKind = "getKind"

  @module("edgedb/dist/codecs/codecs.js")
  external nullCodec: t = "NullCodec"

  @module("edgedb/dist/codecs/ifaces.js")
  external scalarCodec: t = "ScalarCodec"

  @module("edgedb/dist/codecs/enum.js")
  external enumCodec: t = "EnumCodec"

  @module("edgedb/dist/codecs/numbers.js")
  external int16Codec: t = "Int16Codec"

  @module("edgedb/dist/codecs/numbers.js")
  external int32Codec: t = "Int32Codec"

  @module("edgedb/dist/codecs/numerics.js")
  external bigintCodec: t = "BigIntCodec"

  @module("edgedb/dist/codecs/object.js")
  external objectCodec: t = "ObjectCodec"

  @module("edgedb/dist/codecs/namedtuple.js")
  external namedTupleCodec: t = "NamedTupleCodec"

  @module("edgedb/dist/codecs/array.js")
  external arrayCodec: t = "ArrayCodec"

  @module("edgedb/dist/codecs/tuple.js")
  external tupleCodec: t = "TupleCodec"

  @module("edgedb/dist/codecs/range.js")
  external rangeCodec: t = "RangeCodec"

  @module("edgedb/dist/codecs/set.js")
  external setCodec: t = "SetCodec"

  let is: (t, t) => bool = %raw(`function instanceOf(a, b) {
    return a instanceof b
  }`)
}

module QueryType = {
  type t = {
    args: string,
    result: string,
    cardinality: cardinality,
    query: string,
    distinctTypes: Set.t<string>,
  }
}

module AnalyzeQuery = {
  type parseResult = (
    cardinality,
    Codec.t,
    Codec.t,
    float,
    Null.t<Uint8Array.t>,
    Null.t<Uint8Array.t>,
  )

  module BaseClientPool = {
    module Connection = {
      type sessionDefaults
      type session
      @module("edgedb/dist/options.js")
      external session: session = "Session"

      @send external getSessionDefaults: session => sessionDefaults = "defaults"

      // Manually mapped from `ord` fn in driver/src/primitives of the edgedb packages
      type outputFormat = | @as(98) BINARY | @as(106) JSON | @as(110) NONE
      type t
      @send
      external _parse: (
        t,
        string,
        outputFormat,
        cardinality,
        sessionDefaults,
      ) => promise<parseResult> = "_parse"
    }
    type defaultOptions

    @module("edgedb/dist/options.js") @new
    external getDefaultOptions: unit => defaultOptions = "Options"

    type t
    module Holder = {
      type t
      @send external _getConnection: t => promise<Connection.t> = "_getConnection"
      @send external release: t => promise<unit> = "release"
    }

    @send external acquireHolder: (t, defaultOptions) => promise<Holder.t> = "acquireHolder"
  }

  @get external getPool: EdgeDB.Client.t => BaseClientPool.t = "pool"

  module WalkCodec = {
    type ctx = {
      optionalNulls: bool,
      distinctTypes: Set.t<string>,
      currentPath: array<string>,
    }

    let polyVariantNameNeedsEscapingRegex: RegExp.t = %re("/^[a-zA-Z0-9_]+$/")

    let rec generateRecord = (
      ~fields: array<Codec.objectFieldInfo>,
      ~subCodecs: array<Codec.t>,
      ~ctx: ctx,
    ) => {
      open Codec

      let name = pathToName(ctx.currentPath)
      let recordDef = `  type ${name} = {\n${fields
        ->Array.mapWithIndex((field, i) => {
          let subCodec = switch (subCodecs->Array.getUnsafe(i), field.cardinality) {
          | (subCodec, ONE | NO_RESULT | AT_MOST_ONE) if subCodec->is(setCodec) =>
            panic("subcodec is SetCodec, but upper cardinality is one")
          | (subCodec, _) if subCodec->is(setCodec) => subCodec->getSubcodecs->Array.getUnsafe(0)
          | (subCodec, _) => subCodec
          }
          `    ${toReScriptPropName(field.name)}${if (
              ctx.optionalNulls && field.cardinality === AT_MOST_ONE
            ) {
              "?"
            } else {
              ""
            }}: ${walkCodec(
              subCodec,
              {
                ...ctx,
                currentPath: {
                  let newPath = ctx.currentPath->Array.copy
                  newPath->Array.push(field.name)
                  newPath
                },
              },
            )->generateSetType(field.cardinality)},`
        })
        ->Array.joinWith("\n")}\n  }`

      ctx.distinctTypes->Set.add(recordDef)
      name
    }
    and walkCodec = (codec: Codec.t, ctx: ctx) => {
      open Codec
      if codec->is(nullCodec) {
        "null"
      } else if codec->is(scalarCodec) {
        if codec->is(enumCodec) {
          `[${codec
            ->values
            ->Array.map(v => {
              let name = polyVariantNameNeedsEscapingRegex->RegExp.test(v) ? v : `"${v}"`
              `#${name}`
            })
            ->Array.joinWith(" | ")}]`
        } else if codec->is(int16Codec) || codec->is(int32Codec) {
          "int"
        } else if codec->is(bigintCodec) {
          "bigint"
        } else {
          switch codec->tsType {
          | "number" => "float"
          | "boolean" => "bool"
          | tsType => tsType
          }
        }
      } else if codec->is(objectCodec) || codec->is(namedTupleCodec) {
        let fields = if codec->is(objectCodec) {
          codec->getFields
        } else {
          codec
          ->getNames
          ->Array.map(name => {
            name,
            cardinality: ONE,
            implicit: false,
            linkprop: false,
          })
        }
        let subCodecs = codec->getSubcodecs
        generateRecord(~fields, ~subCodecs, ~ctx)
      } else if codec->is(arrayCodec) {
        `array<${walkCodec(codec->getSubcodecs->Array.getUnsafe(0), ctx)}>`
      } else if codec->is(tupleCodec) {
        `(${codec
          ->getSubcodecs
          ->Array.map(subCodec => walkCodec(subCodec, ctx))
          ->Array.joinWith(", ")})`
      } else if codec->is(rangeCodec) {
        let subCodec = codec->getSubcodecs->Array.getUnsafe(0)
        if !(subCodec->is(scalarCodec)) {
          panic("expected range subtype to be scalar type")
        } else {
          `EdgeDB.Range.t<${subCodec->tsType}>`
        }
      } else {
        panic(`Unexpected codec kind: ${String.make(codec->getKind)}}`)
      }
    }
  }

  let analyzeQuery = async (client: EdgeDB.Client.t, query: string, ~path): QueryType.t => {
    let pool = client->getPool
    let holder = await pool->BaseClientPool.acquireHolder(BaseClientPool.getDefaultOptions())
    let errorMessage = ref(None)

    let parseResult = try {
      let cxn = await holder->BaseClientPool.Holder._getConnection
      let parseResult =
        await cxn->BaseClientPool.Connection._parse(
          query,
          BINARY,
          MANY,
          BaseClientPool.Connection.session->BaseClientPool.Connection.getSessionDefaults,
        )
      await holder->BaseClientPool.Holder.release
      Some(parseResult)
    } catch {
    | Exn.Error(err) =>
      errorMessage := err->Exn.message
      Console.error(
        `${CliUtils.colorRed(
            "ERROR in file",
          )}: ${path}:\n${errorMessage.contents->Option.getWithDefault("-")}`,
      )
      await holder->BaseClientPool.Holder.release
      None
    }

    switch parseResult {
    | Some((cardinality, inCodec, outCodec, _, _, _)) =>
      let distinctTypes = Set.make()
      let args = WalkCodec.walkCodec(
        inCodec,
        {
          currentPath: ["args"],
          distinctTypes,
          optionalNulls: true,
        },
      )
      let result = WalkCodec.walkCodec(
        outCodec,
        {
          optionalNulls: false,
          currentPath: ["response"],
          distinctTypes,
        },
      )->generateSetType(cardinality)
      {
        result,
        args,
        cardinality,
        query,
        distinctTypes,
      }
    | _ =>
      let distinctTypes = Set.make()
      distinctTypes->Set.add("type lookAboveForDetails = this_query_has_EdgeQL_errors")
      {
        result: "",
        args: "unit",
        cardinality: ONE,
        query: switch errorMessage.contents {
        | None => "/* This query has an unknown EdgeDB error. Please check the query and recompile. */"
        | Some(errorMessage) => `/*\n${errorMessage}\n*/`
        },
        distinctTypes,
      }
    }
  }
}

type queries = {
  name: string,
  query: string,
  types: QueryType.t,
}

let getFileSourceHash = async filePath => {
  switch await ReadFile.readFirstLine(filePath) {
  | Ok(firstLine) => firstLine->String.split("// @sourceHash ")->Array.get(1)
  | Error() => None
  | exception Exn.Error(_) => None
  }
}

let extractQueriesFromReScript = async (fileText: string, ~analyzeQuery) => {
  let queries = await Promise.all(
    fileText
    ->matchAll(rescriptExtensionPointRegex)
    ->Iterator.toArray
    ->Array.map(async match => {
      switch match {
      | [_, name, query] =>
        Some({
          name,
          query,
          types: await analyzeQuery(query),
        })
      | _ => None
      }
    }),
  )

  queries->Array.keepSome
}

let generatedFileSuffix = "__edgeDb"

let makeBaseGeneratedFileName = baseFileName => `${baseFileName}${generatedFileSuffix}`

let filePathInGeneratedDir = (filePath, ~outputDir) => Path.join([outputDir, filePath])

let getOutputBaseFileName = path => {
  let queryFileName = Path.basenameExt(path, ".res")
  let baseFileName = queryFileName
  makeBaseGeneratedFileName(baseFileName)
}

let generateFiles = (~path, ~queries: array<queries>): fileToGenerate => {
  let queryFileName = Path.basenameExt(path, ".res")
  let baseFileName = queryFileName
  let outputBaseFileName = `${baseFileName}__edgeDb`
  let fileOutput = []

  queries->Array.forEach(params => {
    let (method, returnType, extraInFnArgs, extraInFnApply) = switch params.types.cardinality {
    | ONE => (
        "singleRequired",
        "promise<result<response, EdgeDB.Error.errorFromOperation>>",
        "",
        "",
      )
    | AT_MOST_ONE => ("single", "promise<option<response>>", ", ~onError=?", ", ~onError?")
    | _ => ("many", "promise<array<response>>", "", "")
    }
    let hasArgs = params.types.args !== "null"
    let queryText = params.types.query->String.trim->String.replaceRegExp(%re("/`/g"), "\\`")
    fileOutput->Array.push(
      `module ${params.name->capitalizeString} = {
  let queryText = \`${queryText}\`

${params.types.distinctTypes->Set.values->Iterator.toArray->Array.joinWith("\n\n")}

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
  }
}\n\n`,
    )
  })

  let contents = fileOutput->Array.joinWith("")
  let hash = Hash.hashContents(contents)

  {
    path: `${outputBaseFileName}.res`,
    contents: `// @sourceHash ${hash}\n${contents}`,
    hash,
  }
}

let getMatches = (root: string) =>
  adapter.walk(
    root,
    {
      match: [%re("/[^\/]\.res$/")],
      skip: [%re("/node_modules/"), RegExp.fromString(`dbschema\\${Path.sep}migrations`)],
    },
  )

let generateQueryFiles = async (
  ~root,
  ~noRoot,
  ~files=?,
  ~client: EdgeDB.Client.t,
  ~outputDir,
  ~debug,
) => {
  if noRoot {
    if debug {
      Console.warn(
        `No \`edgedb.toml\` found, using process.cwd() as root directory:
   ${root}
`,
      )
    }
  } else if debug {
    Console.log(`Detected project root via edgedb.toml:`)
    Console.log("   " ++ root)
  }

  let (matches, filesInOutputDir) = switch files {
  | None => await Promise.all2((getMatches(root), getMatches(outputDir)))
  | Some(files) => (files, [])
  }

  let fileModulesWithEdgeQLContent = Set.make()
  let generatedFiles = []

  if matches->Array.length === 0 {
    Console.log(`No .res files found`)
  } else {
    Console.log(`Ensuring we're connected to the DB...`)
    await client->EdgeDB.Client.ensureConnected

    let genereteFileForQuery = async (path: string, ~outputDir) => {
      try {
        let fileText = await adapter.readFileUtf8(path)
        if fileText->String.includes("%edgeql(") {
          fileModulesWithEdgeQLContent->Set.add(path->Path.basenameExt(".res"))
          let queries =
            await fileText->extractQueriesFromReScript(
              ~analyzeQuery=AnalyzeQuery.analyzeQuery(client, ~path, ...),
            )
          let file = generateFiles(~path, ~queries)
          let prettyPath = "./" ++ adapter.path.posix.relative(root, file.path)
          let pathInGeneratedDir = filePathInGeneratedDir(file.path, ~outputDir)
          let shouldWriteFile = switch await getFileSourceHash(pathInGeneratedDir) {
          | None => true
          | Some(sourceHash) => sourceHash !== file.hash
          }
          if shouldWriteFile {
            generatedFiles->Array.push(prettyPath)
            await adapter.fs.writeFile(pathInGeneratedDir, file.contents)
          }
        }
      } catch {
      | Exn.Error(e) =>
        Console.log(
          `${CliUtils.colorRed("Error in file")} './${adapter.path.posix.relative(root, path)}':`,
        )
        Console.error(e)
      }
    }

    Console.log(`Generating files...`)
    let _ = await Promise.all(matches->Array.map(genereteFileForQuery(~outputDir, ...)))
    if generatedFiles->Array.length === 0 {
      ()
    } else if generatedFiles->Array.length > 5 {
      Console.log(`Generated ${generatedFiles->Array.length->Int.toString} files.`)
    } else {
      Console.log(`Generated:\n  ${generatedFiles->Array.joinWith("\n  ")}`)
    }

    if filesInOutputDir->Array.length > 0 {
      let hasLoggedCleaningUnusedFiles = ref(false)
      let logCleanUnusedFiles = () => {
        if !hasLoggedCleaningUnusedFiles.contents {
          Console.log("Cleaning up unused files...")
        }
        Console.time("Cleaning unused files")
        hasLoggedCleaningUnusedFiles := true
      }
      let _ = await Promise.all(
        filesInOutputDir->Array.map(async filePath => {
          let fileModuleName = Path.basenameExt(filePath, generatedFileSuffix ++ ".res")
          if !(fileModulesWithEdgeQLContent->Set.has(fileModuleName)) {
            Console.log(`Deleting unused file ${filePath}...`)
            logCleanUnusedFiles()
            await adapter.fs.unlink(filePath)
          }
        }),
      )
      if hasLoggedCleaningUnusedFiles.contents {
        Console.timeEnd("Cleaning unused files")
      }
    }
  }
}

let findEdgeDbRoot = async () => {
  let projectRoot = ref(None)
  let currentDir = ref(Process.process->Process.cwd)
  let systemRoot = adapter.path.parse(currentDir.contents).root
  let break = ref(false)
  while currentDir.contents !== systemRoot && !break.contents {
    if await adapter.exists(Path.join([currentDir.contents, "edgedb.toml"])) {
      projectRoot := Some(currentDir.contents)
      break := true
    } else {
      currentDir := Path.join([currentDir.contents, ".."])
    }
  }
  projectRoot.contents
}
