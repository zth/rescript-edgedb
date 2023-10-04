let adapter = EdgeDbGenerator__Utils.adapter

let extractFileNameRegExp = %re("/\/([^\/]*?)__edgeql\.\w+\"/")

let extractFileName = line => {
  if line->String.startsWith("  File") {
    switch line->String.match(extractFileNameRegExp) {
    | Some([_, fileName]) => Some(fileName)
    | _ => None
    }
  } else {
    None
  }
}

type extractedLineInfo = {
  queryName: string,
  recordPath: option<array<string>>,
  fieldName: string,
}
let extractLineInfo = line => {
  switch line->String.trim->String.split(" ")->List.fromArray {
  | list{info, ...rest} =>
    let restText = rest->List.toArray->Array.joinWith(" ")
    switch (info->String.split("."), restText) {
    | ([queryName, recordName, fieldName], "is a record label never used to read a value")
      if !(recordName->String.startsWith("args")) =>
      Some({
        queryName,
        fieldName,
        recordPath: switch recordName->String.split("__")->Array.sliceToEnd(~start=1) {
        | [] => None
        | path => Some(path)
        },
      })
    | _ => None
    }
  | _ => None
  }
}

let extractFromReanalyzeOutput = (output: string) => {
  output
  ->String.split("\n\n")
  ->Array.filterMap(text => {
    let lines = text->String.split("\n")
    let index = ref(0)
    lines->Array.findMap(line => {
      let currentIndex = index.contents
      index := currentIndex + 1
      switch (line->String.startsWith("  File \""), lines[currentIndex + 1]) {
      | (true, Some(nextLine)) =>
        switch (extractFileName(line), extractLineInfo(nextLine)) {
        | (Some(fileName), Some(fileInfo)) => Some((fileName, fileInfo))
        | _ => None
        }
      | _ => None
      }
    })
  })
}

@module("child_process")
external childProcess: 'a = "default"

let readReanalyzeOutput = () => {
  Promise.make((resolve, reject) => {
    let p = childProcess["spawn"]("npx", ["--yes", "reanalyze", "-dce"])

    switch p["stdout"]->Nullable.toOption {
    | None =>
      Console.error("Something went wrong")
      reject()
      adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
    | Some(stdout) =>
      let data = ref("")
      stdout->EdgeDbGenerator__Utils.Adapter.onData(d => {
        data := data.contents ++ d
      })
      switch p["stderr"]->Nullable.toOption {
      | None => ()
      | Some(stderr) =>
        stderr->EdgeDbGenerator__Utils.Adapter.onData(e => {
          if e->String.includes("End_of_file") {
            Console.error(`Something went wrong trying to analyze the ReScript project. Try cleaning your ReScript project and rebuilding it from scratch before trying again.`)
          }
          reject()
          adapter.process->EdgeDbGenerator__Utils.Adapter.exit(1)
        })
      }
      stdout->EdgeDbGenerator__Utils.Adapter.onClose(() => {
        resolve(data.contents->extractFromReanalyzeOutput)
      })
    }
  })
}

let reportResults = results => {
  if results->Array.length === 0 {
    Console.log("No unused selections found. Great job!")
  } else {
    Console.log(
      `\n${CliUtils.colorRed("✘")} Found ${results
        ->Array.length
        ->Int.toString} unused selections.`,
    )
    let byFile = Dict.make()
    results->Array.forEach(((queryName, fileInfo)) => {
      switch byFile->Dict.get(queryName) {
      | None => byFile->Dict.set(queryName, [fileInfo])
      | Some(item) => item->Array.push(fileInfo)
      }
    })
    byFile
    ->Dict.toArray
    ->Array.forEach(((fileName, fileInfos)) => {
      Console.log(`\nFile "${fileName}":`)
      let byQuery = Dict.make()
      fileInfos->Array.forEach(fileInfo => {
        switch byQuery->Dict.get(fileInfo.queryName) {
        | None => byQuery->Dict.set(fileInfo.queryName, [fileInfo])
        | Some(item) => item->Array.push(fileInfo)
        }
      })
      byQuery
      ->Dict.toArray
      ->Array.forEach(((queryName, fileInfo)) => {
        Console.log(`   In query "${queryName}":`)
        fileInfo->Array.forEach(
          fileInfo => {
            let contextMessage = switch fileInfo.recordPath {
            | None | Some([]) => ""
            | Some(path) => `${path->Array.joinWith(".")}: `
            }
            Console.log(`    - ${contextMessage}${fileInfo.fieldName}`)
          },
        )
      })
    })
  }
}
