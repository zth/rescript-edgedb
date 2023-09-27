open TestFramework
open EdgeDbGenerator
open EdgeDbGenerator__Utils

describe("extracting queries from ReScript documents", () => {
  let analyzeQuery = async (_s: string) => Obj.magic(null)

  testAsync("it can extract from docs #1", async () => {
    let res = await extractQueriesFromReScript(
      `
let findMovie = async (client, ~title) => {
    let findMovieQuery = %edgeql(\`
    # @name findMovie
    select Movie {
        title,
        status,
        actors: {
            name,
            age
        }
    } filter 
        .title = <str>$movieTitle\`)

    await client->findMovieQuery({
    movieTitle: title,
    })
}`,
      ~analyzeQuery,
    )
    expect(res->Array.length)->Expect.toBe(1)
    expect((res->Array.getUnsafe(0)).name)->Expect.toBe("findMovie")
    expect((res->Array.getUnsafe(0)).query)->Expect.toMatchSnapshot
  })

  testAsync("it can extract from docs #2", async () => {
    let res = await extractQueriesFromReScript(
      `
  let findMovie = async (client, ~title) => {
      let findMovieQuery = %edgeql(\`# @name findMovieQuery
      select Movie {
          title,
          status,
          actors: {
              name,
              age
          }
      } filter 
          .title = <str>$movieTitle\`)
  
      await client->findMovieQuery({
      movieTitle: title,
      })
  }`,
      ~analyzeQuery,
    )
    expect(res->Array.length)->Expect.toBe(1)
    expect((res->Array.getUnsafe(0)).name)->Expect.toBe("findMovieQuery")
    expect((res->Array.getUnsafe(0)).query)->Expect.toMatchSnapshot
  })

  testAsync("it can extract from docs #2", async () => {
    let res = await extractQueriesFromReScript(
      `
    let findMovie = async (client, ~title) => {
        let findMovieQuery = %edgeql(\`# @name findMovieQuery
        select Movie {
            title,
            status,
            actors: {
                name,
                age
            }
        } filter 
            .title = <str>$movieTitle\`)

        let findUser = %edgeql(\`# @name findUser
        select User {
            name
        } filter 
            .id = <uuid>$userId\`)
    }`,
      ~analyzeQuery,
    )
    expect(res->Array.length)->Expect.toBe(2)
    expect((res->Array.getUnsafe(0)).name)->Expect.toBe("findMovieQuery")
    expect((res->Array.getUnsafe(1)).name)->Expect.toBe("findUser")
    expect((res->Array.getUnsafe(0)).query)->Expect.toMatchSnapshot
    expect((res->Array.getUnsafe(1)).query)->Expect.toMatchSnapshot
  })
})

test("generate file", () => {
  let query = "select Movie {
          title,
          status,
          actors: {
              name,
              age
          }
      } filter 
          .title = <str>$movieTitle"

  let distinctTypes = Set.make()
  distinctTypes->Set.add("  type args = {movieTitle: string}")
  distinctTypes->Set.add("  type response = {title: string, status: [#Published | #Unpublished]}")

  expect(
    generateFiles(
      ~path="SomeQueryFile.res",
      ~queries=[
        {
          name: "FindMovie",
          query,
          types: {
            args: "{movieTitle: string}",
            result: "<not-needed-for-test>",
            cardinality: ONE,
            query,
            distinctTypes,
          },
        },
      ],
    ),
  )->Expect.toMatchSnapshot
})

test("generate correct record prop names", () => {
  expect(toReScriptPropName("one"))->Expect.toBe("one")
  expect(toReScriptPropName("camelCased"))->Expect.toBe("camelCased")
  expect(toReScriptPropName("One"))->Expect.toBe(`@as("One") one`)
  expect(toReScriptPropName("$One"))->Expect.toBe(`@as("$One") one`)
  expect(
    toReScriptPropName("two_names_here$"),
  )->Expect.toBe(`@as("two_names_here$") two_names_here`)
})
