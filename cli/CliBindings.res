module Chokidar = {
  type t

  module Watcher = {
    type t

    @send
    external onChange: (t, @as(json`"change"`) _, string => promise<unit>) => t = "on"

    @send
    external onUnlink: (t, @as(json`"unlink"`) _, string => promise<unit>) => t = "on"

    @send
    external onAdd: (t, @as(json`"add"`) _, string => promise<unit>) => t = "on"

    @send
    external close: t => Promise.t<unit> = "close"
  }

  @module("chokidar") @val
  external watcher: t = "default"

  type watchOptions = {ignored?: array<string>, ignoreInitial?: bool}

  @send
  external watch: (t, string, ~options: watchOptions=?) => Watcher.t = "watch"
}
