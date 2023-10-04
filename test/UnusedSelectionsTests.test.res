open TestFramework
open UnusedSelections

let sampleReanalyzeOutput = `
  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile__edgeql.res", line 14, characters 4-22
  FindMovies.args.movieTitle is a record label never used to read a value
  <-- line 14
      @dead("FindMovies.args.movieTitle") movieTitle: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile__edgeql.res", line 19, characters 4-20
  FindMovies.response__actors.age is a record label never used to read a value
  <-- line 19
      @dead("FindMovies.response__actors.age") age: Null.t<int>,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile__edgeql.res", line 23, characters 4-17
  FindMovies.response.title is a record label never used to read a value
  <-- line 23
      @dead("FindMovies.response.title") title: string,

  Warning Dead Module
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 2, characters 7-582
  +SingleMovie6__edgeql.FindMovieQuery is a dead module as all its items are dead.

  Warning Dead Value
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 3, characters 2-173
  FindMovieQuery.+queryText is never used
  <-- line 3
    @dead("FindMovieQuery.+queryText") let queryText = \`select Movie {

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 14, characters 4-22
  FindMovieQuery.args.movieTitle is a record label never used to read a value
  <-- line 14
      @dead("FindMovieQuery.args.movieTitle") movieTitle: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 18, characters 4-16
  FindMovieQuery.response__actors.name is a record label never used to read a value
  <-- line 18
      @dead("FindMovieQuery.response__actors.name") name: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 19, characters 4-20
  FindMovieQuery.response__actors.age is a record label never used to read a value
  <-- line 19
      @dead("FindMovieQuery.response__actors.age") age: Null.t<int>,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 23, characters 4-17
  FindMovieQuery.response.title is a record label never used to read a value
  <-- line 23
      @dead("FindMovieQuery.response.title") title: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 24, characters 4-38
  FindMovieQuery.response.status is a record label never used to read a value
  <-- line 24
      @dead("FindMovieQuery.response.status") status: [#Published | #Unpublished],

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 25, characters 4-34
  FindMovieQuery.response.actors is a record label never used to read a value
  <-- line 25
      @dead("FindMovieQuery.response.actors") actors: array<response__actors>,

  Warning Dead Value
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 28, characters 2-141
  FindMovieQuery.+query is never used
  <-- line 28
    @dead("FindMovieQuery.+query") let query = (client: EdgeDB.Client.t, args: args): promise<array<response>> => {

  Warning Dead Module
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 33, characters 7-583
  +SingleMovie6__edgeql.FindMovieQuery2 is a dead module as all its items are dead.

  Warning Dead Value
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 34, characters 2-173
  FindMovieQuery2.+queryText is never used
  <-- line 34
    @dead("FindMovieQuery2.+queryText") let queryText = \`select Movie {

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 45, characters 4-22
  FindMovieQuery2.args.movieTitle is a record label never used to read a value
  <-- line 45
      @dead("FindMovieQuery2.args.movieTitle") movieTitle: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 49, characters 4-16
  FindMovieQuery2.response__actors.name is a record label never used to read a value
  <-- line 49
      @dead("FindMovieQuery2.response__actors.name") name: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 50, characters 4-20
  FindMovieQuery2.response__actors.age is a record label never used to read a value
  <-- line 50
      @dead("FindMovieQuery2.response__actors.age") age: Null.t<int>,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 54, characters 4-17
  FindMovieQuery2.response.title is a record label never used to read a value
  <-- line 54
      @dead("FindMovieQuery2.response.title") title: string,

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 55, characters 4-38
  FindMovieQuery2.response.status is a record label never used to read a value
  <-- line 55
      @dead("FindMovieQuery2.response.status") status: [#Published | #Unpublished],

  Warning Dead Type
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 56, characters 4-34
  FindMovieQuery2.response.actors is a record label never used to read a value
  <-- line 56
      @dead("FindMovieQuery2.response.actors") actors: array<response__actors>,

  Warning Dead Value
  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/SingleMovie6__edgeql.res", line 59, characters 2-141
  FindMovieQuery2.+query is never used
  <-- line 59
    @dead("FindMovieQuery2.+query") let query = (client: EdgeDB.Client.t, args: args): promise<array<response>> => {

  Warning Dead Module
  File "/Users/zth/OSS/edgedb-rescript/rescript/src/SingleMovie6.res", line 0, characters 0-0
  +SingleMovie6 is a dead module as all its items are dead.

  Warning Dead Value
  File "/Users/zth/OSS/edgedb-rescript/rescript/src/SingleMovie6.res", line 1, characters 0-576
  +findMovie is never used
  <-- line 1
  @dead("+findMovie") let findMovie = async (client, ~title) => {
  
  Analysis reported 23 issues (Warning Dead Module:3, Warning Dead Type:15, Warning Dead Value:5)`

describe("extracting filenames", () => {
  test("it extracts file names", () => {
    expect(
      extractFileName(`  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile__edgeql.res", line 14, characters 4-22`),
    )->Expect.toBe(Some("QueryFile"))
  })

  test("it doesnt extract unless filename is from EdgeDB", () => {
    expect(
      extractFileName(`  File "/Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile.res", line 14, characters 4-22`),
    )->Expect.toBe(None)
  })
})

describe("extracting line info", () => {
  test("it extracts line info for arg", () => {
    expect(
      extractLineInfo(
        "  FindMovieQuery.response.status is a record label never used to read a value",
      ),
    )->Expect.toEqual(
      Some({
        queryName: "FindMovieQuery",
        fieldName: "status",
        recordPath: None,
      }),
    )
  })

  test("it handles record paths", () => {
    expect(
      extractLineInfo(
        "  FindMovieQuery.response__actor.status is a record label never used to read a value",
      ),
    )->Expect.toEqual(
      Some({
        queryName: "FindMovieQuery",
        fieldName: "status",
        recordPath: Some(["actor"]),
      }),
    )
  })
})

test("it can extract results", () => {
  expect(UnusedSelections.extractFromReanalyzeOutput(sampleReanalyzeOutput))->Expect.toMatchSnapshot
})
