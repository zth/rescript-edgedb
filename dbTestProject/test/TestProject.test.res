open TestFramework

let client = EdgeDB.Client.make()

external spawnSync: array<string> => 'a = "Bun.spawnSync"

afterAllAsync(async () => {
  await client->EdgeDB.Client.close
})

let removeIds = JSON.Replacer(
  (key, value) => {
    switch (key, value) {
    | ("id", Js.Json.String(_)) => Js.Json.String("<id>")
    | _ => value
    }
  },
)

describe("fetching data", () => {
  testAsync("fetching movies", async () => {
    let movies = await client->Movies.allMovies
    let movies = movies->JSON.stringifyAny(~replacer=removeIds, ~space=2)->Option.getOr("")
    expect(movies)->Expect.toMatchSnapshot
  })

  testAsync("counting movies", async () => {
    let count = await client->Movies.countAllMovies
    expect(count)->Expect.toMatchSnapshot
  })

  testAsync("counting movies with param", async () => {
    let count = await client->Movies.countAllMoviesWithParam(~title="The Great Adventure")
    expect(count)->Expect.toMatchSnapshot
  })

  testAsync("test bool", async () => {
    let bool = await client->Movies.testBool
    expect(bool)->Expect.toMatchSnapshot
  })

  testAsync("test string", async () => {
    let string = await client->Movies.testString
    expect(string)->Expect.toMatchSnapshot
  })

  testAsync("fetching single movie", async () => {
    let movie = await client->Movies.movieByTitle(~title="The Great Adventure")
    let movie = movie->JSON.stringifyAny(~replacer=removeIds, ~space=2)->Option.getOr("")
    expect(movie)->Expect.toMatchSnapshot
  })

  testAsync("fetching non-existing movie", async () => {
    expect(
      await client->Movies.movieByTitle(~title="The Great Adventure 2"),
    )->Expect.toMatchSnapshot
  })

  testAsync("running in a transaction", async () => {
    let res = await client->EdgeDB.Client.transaction(
      async transaction => {
        await transaction->Movies.addActor({name: "Bruce Willis"})
      },
    )

    expect(
      switch res {
      | Ok({id}) =>
        let removed = await client->EdgeDB.Client.transaction(
          async transaction => {
            await transaction->Movies.removeActor({id: id})
          },
        )
        switch removed {
        | Some({id}) =>
          // Just for the unused CLI output
          let _id = id
        | None => ()
        }
        id->String.length > 2
      | Error(_) => false
      },
    )->Expect.toBe(true)
  })
})

test("run unused selections CLI", () => {
  let res = spawnSync(["npx", "rescript-edgedb", "unused-selections"])
  expect(res["stdout"]["toString"]())->Expect.toMatchSnapshot
})
