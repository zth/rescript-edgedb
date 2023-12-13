open TestFramework

module Errors = {
  let unexpectedTokenWithHint = `Unexpected token: <Token IDENT "actors">
   |
 6 |       actors: {
   |       ^^^^^^
Hint: It appears that a ',' is missing in a shape before 'actors'`

  let typeOrAliasDoesNotExist = `object type or alias 'default::a' does not exist
    |
 11 |     } order by a.title
    |                ^
Hint: did you mean '.id'?`

  let objectTypeHasNoProp = `object type 'default::Movie' has no link or property 'TITLE'
    |
 11 |     } order by .TITLE
    |                ^^^^^^
`

  let unexpected = `Unexpected 'orderaaaaa'
    |
 11 |     } orderaaaaa
    |       ^^^^^^^^^^
`
}

describe("extracting errors", () => {
  test("Extracting errors #unexpectedWithTokenHint", () => {
    let error = EdgeDbGenerator__Utils.Errors.extractFromString(
      Errors.unexpectedTokenWithHint,
      ~startLoc={line: 10, col: 12},
    )
    expect(error)->Expect.toMatchSnapshot
  })

  test("Extracting errors #typeOrAliasDoesNotExist", () => {
    let error = EdgeDbGenerator__Utils.Errors.extractFromString(
      Errors.typeOrAliasDoesNotExist,
      ~startLoc={line: 10, col: 12},
    )
    expect(error)->Expect.toMatchSnapshot
  })

  test("Extracting errors #objectTypeHasNoProp", () => {
    let error = EdgeDbGenerator__Utils.Errors.extractFromString(
      Errors.objectTypeHasNoProp,
      ~startLoc={line: 10, col: 12},
    )
    expect(error)->Expect.toMatchSnapshot
  })

  test("Extracting errors #unexpected", () => {
    let error = EdgeDbGenerator__Utils.Errors.extractFromString(
      Errors.unexpected,
      ~startLoc={line: 10, col: 12},
    )
    expect(error)->Expect.toMatchSnapshot
  })
})
