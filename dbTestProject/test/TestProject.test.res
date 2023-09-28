open TestFramework

let client = EdgeDB.Client.make()

external spawnSync: array<string> => 'a = "Bun.spawnSync"
external process: 'a = "process"

afterAllAsync(async () => {
  await client->EdgeDB.Client.close
})

describe("fetching data", () => {
  testAsync("fetching movies", async () => {
    expect(await client->Movies.allMovies)->Expect.toMatchSnapshot
  })

  testAsync("fetching single movie", async () => {
    expect(await client->Movies.movieByTitle(~title="The Great Adventure"))->Expect.toMatchSnapshot
  })

  testAsync("fetching non-existing movie", async () => {
    expect(
      await client->Movies.movieByTitle(~title="The Great Adventure 2"),
    )->Expect.toMatchSnapshot
  })
})

test("run unused selections CLI", () => {
  let res = spawnSync(["npx", "rescript-edgedb", "unused-selections"])
  expect(res["stdout"]["toString"]())->Expect.toMatchSnapshot
})
