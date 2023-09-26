let capitalizeString = str =>
  `${str->String.slice(~start=0, ~end=1)->String.toUpperCase}${str->String.sliceToEnd(~start=1)}`

let uncapitalizeString = str =>
  `${str->String.slice(~start=0, ~end=1)->String.toLowerCase}${str->String.sliceToEnd(~start=1)}`

let pathToName = path => {
  let name = path->Array.joinWith("_")

  // Make valid ReScript record name.
  uncapitalizeString(name)
}

module ReadFile = {
  @module("fs")
  external createReadStream: string => 'stream = "createReadStream"

  type createInterfaceOptions<'stream> = {
    input: 'stream,
    crlfDelay: int,
  }

  @send external destroy: 'stream => unit = "destroy"

  @module("readline")
  external createInterface: createInterfaceOptions<'stream> => 'readlineInterface =
    "createInterface"

  let readFirstLine = (filePath: string): promise<result<string, unit>> => {
    let readStream = createReadStream(filePath)
    let rl = createInterface({
      input: readStream,
      crlfDelay: %raw("Infinity"),
    })

    Promise.make((resolve, _reject) => {
      let _ = rl["on"]("line", (line: string) => {
        let _ = rl["close"]() // Close the readline Interface to stop reading the file
        readStream->destroy // Destroy the read stream to free up resources
        resolve(Ok(line))
      })

      // Optional: Handle possible errors on the readStream
      readStream["on"]("error", err => {
        Console.error(err)
        resolve(Error())
      })
    })
  }
}

module Hash = {
  type createHash
  @module("crypto") external createHash: createHash = "createHash"
  let hashContents: (createHash, string) => string = %raw(`function(createHash, contents) {
    return createHash("md5").update(contents).digest("hex")
  }`)
  let hashContents = hashContents(createHash, ...)
}

module Adapter = {
  type walkConfig = {
    match: array<RegExp.t>,
    skip: array<RegExp.t>,
  }
  type stdin = {isTTY: bool}
  @send external onData: (stdin, @as("data") _, string => unit) => unit = "on"
  @send external onEnd: (stdin, @as("end") _, unit => unit) => unit = "on"
  type stdout = {isTTY: bool}
  type process = {cwd: unit => string, stdin: stdin, stdout: stdout}
  type posix = {relative: (string, string) => string}
  type parseResult = {root: string}
  type path = {
    basename: (string, string) => string,
    posix: posix,
    sep: string,
    parse: string => parseResult,
  }
  @variadic @send external join: (path, array<string>) => string = "join"
  @variadic @send external resolve: (path, array<string>) => string = "resolve"
  type mkdirOpts = {recursive?: bool}
  type fs = {
    writeFile: (string, string) => promise<unit>,
    unlink: string => promise<unit>,
    access: string => promise<unit>,
    mkdir: (string, mkdirOpts) => promise<unit>,
  }
  type inputParams = {silent?: bool}
  type t = {
    process: process,
    path: path,
    fs: fs,
    readFileUtf8: string => promise<string>,
    exists: string => promise<bool>,
    walk: (string, walkConfig) => promise<array<string>>,
    input: (string, ~params: inputParams=?) => promise<string>,
  }
}

@module("edgedb") external adapter: Adapter.t = "adapter"
