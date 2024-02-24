open TestFramework
open UnusedSelections

let sampleReanalyzeOutput = `
  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/__generated__/Movies__edgeql.res:18:5-23
  AllMovies.response__actors.numberOfPets is a record label never used to read a value
  <-- line 18
      @dead("AllMovies.response__actors.numberOfPets") numberOfPets: float,

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/__generated__/Movies__edgeql.res:23:5-17
  AllMovies.response.title is a record label never used to read a value
  <-- line 23
      @dead("AllMovies.response.title") title: string,

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/__generated__/Movies__edgeql.res:115:5-16
  MovieByTitle.response__actors.name is a record label never used to read a value
  <-- line 115
      @dead("MovieByTitle.response__actors.name") name: string,

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/__generated__/Movies__edgeql.res:121:5-14
  MovieByTitle.response.id is a record label never used to read a value
  <-- line 121
      @dead("MovieByTitle.response.id") id: string,

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/test/TestProject.test.res:55:11-22
  _id is never used
  <-- line 55
            @dead("_id") let _id = id
`

describe("extracting filenames", () => {
  test("it extracts file names", () => {
    expect(
      extractFileName(`  /Users/zth/OSS/edgedb-rescript/rescript/__generated__/QueryFile__edgeql.res, line 14, characters 4-22`),
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
