@module("bun:test") external test: (string, unit => unit) => unit = "test"
@module("bun:test") external describe: (string, unit => unit) => unit = "describe"
@module("bun:test") external testAsync: (string, unit => promise<unit>) => unit = "test"

module Expect = {
  type t
  @send external toBe: (t, 'value) => unit = "toBe"
  @send external toEqual: (t, 'value) => unit = "toEqual"
  @send external toMatchSnapshot: t => unit = "toMatchSnapshot"
}

@module("bun:test") external expect: 'result => Expect.t = "expect"

@module("bun:test") external afterAllAsync: (unit => promise<unit>) => unit = "afterAll"
