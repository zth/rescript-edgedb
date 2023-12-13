module Adapter = {
  // This is a big mess and should be cleaned up at some point

  type stdin = {isTTY: bool}
  @send external onData: (stdin, @as("data") _, string => unit) => unit = "on"
  @send external onLine: (stdin, @as("line") _, string => unit) => unit = "on"
  @send external onError: (stdin, @as("error") _, string => unit) => unit = "on"
  @send external onEnd: (stdin, @as("end") _, unit => unit) => unit = "on"
  @send external onClose: (stdin, @as("close") _, unit => unit) => unit = "on"
  type stdout = {isTTY: bool}
  type process = {cwd: unit => string, stdin: stdin, stdout: stdout}
  @send external exit: (process, int) => 'any = "exit"

  type fs = {access: string => promise<unit>}
  type inputParams = {@dead silent?: bool}
  type t = {
    process: process,
    fs: fs,
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
  let name = path->Array.joinWith("__")

  // Make valid ReScript record name.
  uncapitalizeString(name)
}

module Errors = {
  type loc = {
    line: int,
    col: int,
  }

  type error = {
    start: loc,
    end: loc,
    text: string,
  }

  let extractFromString = (error, ~startLoc: loc): option<error> => {
    let lines = error->String.split("\n")
    let text = []
    let codeText = []

    lines->Array.forEach(line => {
      let trimmed = line->String.trim
      let isCodeText =
        trimmed->String.startsWith("|") ||
          (line->String.startsWith(" ") && trimmed->String.includes(" | "))

      if isCodeText {
        codeText->Array.push(line)
      } else {
        text->Array.push(line)
      }
    })

    let lineWithHighlight = codeText->Array.at(-1)
    let lineWithQueryLineNum = codeText->Array.at(-2)

    let line = switch lineWithQueryLineNum {
    | None => None
    | Some(line) =>
      line
      ->String.trim
      ->String.split("|")
      ->Array.get(0)
      ->Option.flatMap(l => l->String.trim->Int.fromString)
      ->Option.map(l =>
        /* EdgeDB error lines are not 0 based, so account for that */
        l + startLoc.line - 1
      )
    }

    switch (line, lineWithHighlight) {
    | (Some(line), Some(content)) =>
      switch content->String.split("|") {
      | [_, highlightRow] =>
        let colStart =
          highlightRow->String.length - highlightRow->String.trimStart->String.length - 1
        let colEnd =
          colStart +
          highlightRow
          ->String.split("")
          ->Array.filter(v => v === "^")
          ->Array.length

        Some({
          text: text->Array.filter(l => l->String.trim !== "")->Array.joinWith("\n"),
          start: {
            line,
            col: colStart,
          },
          end: {
            line,
            col: colEnd,
          },
        })
      | _ => None
      }
    | _ => None
    }
  }
}
