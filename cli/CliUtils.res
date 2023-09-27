let hasArg = (args, name) => {
  args->Array.includes(name)
}

let getArgValue = (args, names) => {
  let argIndex = args->Array.findIndexOpt(item => names->Array.includes(item))
  switch argIndex {
  | Some(argIndex) =>
    switch args[argIndex + 1] {
    | Some(maybeArgValue) if !(maybeArgValue->String.startsWith("--")) => Some(maybeArgValue)
    | _ => None
    }
  | None => None
  }
}

let colorRed = str => `\x1b[31m${str}\x1b[0m`
