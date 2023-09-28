module Adapter = {
  // This is a big mess and should be cleaned up at some point
  type walkConfig = {
    match: array<RegExp.t>,
    skip: array<RegExp.t>,
  }
  type stdin = {isTTY: bool}
  @send external onData: (stdin, @as("data") _, string => unit) => unit = "on"
  @send external onLine: (stdin, @as("line") _, string => unit) => unit = "on"
  @send external onError: (stdin, @as("error") _, string => unit) => unit = "on"
  @send external onEnd: (stdin, @as("end") _, unit => unit) => unit = "on"
  @send external onClose: (stdin, @as("close") _, unit => unit) => unit = "on"
  type stdout = {isTTY: bool}
  type process = {cwd: unit => string, stdin: stdin, stdout: stdout}
  @send external exit: (process, int) => 'any = "exit"
  type posix = {relative: (string, string) => string}
  type parseResult = {root: string}
  type path = {
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
    adapter.process.stdin->Adapter.onData(chunk => data := data.contents ++ chunk)
    adapter.process.stdin->Adapter.onEnd(() => resolve(data.contents->String.trimEnd))
  })
}

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
      let _ = rl->Adapter.onLine((line: string) => {
        let _ = rl["close"]()
        readStream->destroy
        resolve(Ok(line))
      })

      rl->Adapter.onError(_err => {
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

let disallowedIdentifiers = [
  "and",
  "as",
  "assert",
  "constraint",
  "else",
  "exception",
  "external",
  "false",
  "for",
  "if",
  "in",
  "include",
  "lazy",
  "let",
  "module",
  "mutable",
  "of",
  "open",
  "rec",
  "switch",
  "true",
  "try",
  "type",
  "when",
  "while",
  "with",
  "private",
]

let legalIdentifierRegexp = %re("/^[a-z][a-zA-Z0-9_]*$/")
let textRegexp = %re("/[a-zA-Z_]/")

let removeIllegalCharacters = (input: string) => {
  let result = ref("")

  for i in 0 to input->String.length - 1 {
    let char = input->String.charAt(i)
    if textRegexp->RegExp.test(char) {
      result := if result.contents === "" {
          char->String.toLowerCase
        } else {
          result.contents ++ char
        }
    } else if textRegexp->RegExp.test(char) && result.contents === "" {
      result := result.contents ++ char->String.toLowerCase
    }
  }

  result.contents
}

let toReScriptPropName = (ident: string) => {
  let isIllegalIdentifier =
    !(legalIdentifierRegexp->RegExp.test(ident)) || disallowedIdentifiers->Array.includes(ident)

  if isIllegalIdentifier {
    `@as("${ident}") ${removeIllegalCharacters(ident)}`
  } else {
    ident
  }
}
