/* Most things in here are (loosely) ported from the existing `edgedb-js` tooling to ReScript. */
module Utils = EdgeDbGenerator__Utils
module Fs = NodeJs.Fs
module Path = NodeJs.Path
module Process = NodeJs.Process

@send
external matchAll: (string, RegExp.t) => Iterator.t<array<string>> = "matchAll"

let toReScriptPropName = name =>
  switch RescriptEmbedLang.CodegenUtils.toReScriptSafeName(name) {
  | NeedsAnnotation({actualName, safeName}) => `@as("${actualName}") ${safeName}`
  | Safe(safeName) => safeName
  }

@live
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

  @live
  type objectFieldInfo = {
    name: string,
    implicit: bool,
    linkprop: bool,
    cardinality: cardinality,
  }

  @unboxed @live
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

  @module("edgedb/dist/codecs/json.js")
  external jsonCodec: t = "JSONCodec"

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
      @live
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

      let annotations = if ctx.currentPath->Array.at(0) === Some("args") {
        "@live  \n"
      } else {
        ""
      }

      let name = Utils.pathToName(ctx.currentPath)
      let recordDef = `${annotations}type ${name} = {\n${fields
        ->Array.mapWithIndex((field, i) => {
          let subCodec = switch (subCodecs->Array.getUnsafe(i), field.cardinality) {
          | (subCodec, ONE | NO_RESULT | AT_MOST_ONE) if subCodec->is(setCodec) =>
            panic("subcodec is SetCodec, but upper cardinality is one")
          | (subCodec, _) if subCodec->is(setCodec) => subCodec->getSubcodecs->Array.getUnsafe(0)
          | (subCodec, _) => subCodec
          }
          `  ${toReScriptPropName(field.name)}${if (
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
        ->Array.join("\n")}\n}`

      ctx.distinctTypes->Set.add(recordDef)
      name
    }
    and generatePrimitive = (~codec: Codec.t, ~ctx: ctx) => {
      let name = Utils.pathToName(ctx.currentPath)
      let annotations = if ctx.currentPath->Array.at(0) === Some("args") {
        "@live  \n"
      } else {
        ""
      }
      ctx.distinctTypes->Set.add(`${annotations}type ${name} = ${codec->walkCodec(ctx)}`)
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
            ->Array.join(" | ")}]`
        } else if codec->is(int16Codec) || codec->is(int32Codec) {
          "int"
        } else if codec->is(bigintCodec) {
          "bigint"
        } else if codec->is(jsonCodec) {
          "JSON.t"
        } else {
          switch codec->tsType {
          | "number" => "float"
          | "boolean" => "bool"
          | "Date" => "Date.t"
          | ("LocalDateTime"
            | "LocalDate"
            | "RelativeDuration"
            | "ConfigMemory"
            | "Duration"
            | "DateDuration"
            | "LocalTime") as dataType =>
            `EdgeDB.DataTypes.${dataType}.t`
          | tsType if tsType->String.charAt(0)->String.toUpperCase === tsType->String.charAt(0) =>
            `${tsType}.t`
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
          ->Array.join(", ")})`
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

  let analyzeQuery = async (client: EdgeDB.Client.t, query: string, ~path): result<
    QueryType.t,
    string,
  > => {
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
        `${CliUtils.colorRed("ERROR in file")}: ${path}:\n${errorMessage.contents->Option.getOr(
            "-",
          )}`,
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
      // walkCodec only handles object codec and named tuple codec.
      // If distinctTypes is empty, or it is missing a response type,
      // then we know we are working with a primitive return type.
      if (
        distinctTypes->Set.size === 0 ||
          !(
            distinctTypes
            ->Set.values
            ->Iterator.toArrayWithMapper(t => String.includes(t, "response"))
            ->Array.includes(true)
          )
      ) {
        WalkCodec.generatePrimitive(
          ~codec=outCodec,
          ~ctx={optionalNulls: false, currentPath: ["response"], distinctTypes},
        )
      }
      Ok({
        result,
        args,
        cardinality,
        query,
        distinctTypes,
      })
    | _ =>
      Error(
        errorMessage.contents->Option.getOr(
          "This query has an unknown EdgeDB error. Please check the query and recompile.",
        ),
      )
    }
  }
}
