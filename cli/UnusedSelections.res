let adapter = EdgeDbGenerator__Utils.adapter

let extractFileNameRegExp = %re("/\/([^\/]*?)__edgeql\.res/")

let extractFileName = line => {
  switch line->String.trim->String.match(extractFileNameRegExp) {
  | Some([_, fileName]) => Some(fileName)
  | _ => None
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
    let restText = rest->List.toArray->Array.joinWith(" ")->String.trim
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
    if text->String.includes("__edgeql.res") {
      let lines = text->String.split("\n")
      let index = ref(0)
      lines->Array.findMap(line => {
        let currentIndex = index.contents
        index := currentIndex + 1

        switch (line->String.includes("__edgeql.res"), lines[currentIndex + 1]) {
        | (true, Some(nextLine)) =>
          switch (extractFileName(line), extractLineInfo(nextLine)) {
          | (Some(fileName), Some(fileInfo)) => Some((fileName, fileInfo))
          | _ => None
          }
        | _ => None
        }
      })
    } else {
      None
    }
  })
}

@module("child_process")
external childProcess: 'a = "default"

let readReanalyzeOutput = () => {
  Promise.make((resolve, reject) => {
    let p = childProcess["spawn"]("npx", ["--yes", "@rescript/tools", "reanalyze", "-dce"])

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
      Console.log(`\nFile "${fileName}.res":`)
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
            | Some(path) => `${path->Array.joinWith(".")}`
            }
            Console.log(`    - ${contextMessage}.${fileInfo.fieldName}`)
          },
        )
      })
    })
  }
}
