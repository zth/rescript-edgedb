open TestFramework
open UnusedSelections

let sampleReanalyzeOutput = `
  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:7:3-20
  _id is never used
  <-- line 7
    @dead("_id") let _id = movie.id

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:8:3-109
  _actors is never used

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:17:3-20
  _id is never used
  <-- line 17
    @dead("_id") let _id = movie.id

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:18:3-26
  _title is never used
  <-- line 18
    @dead("_title") let _title = movie.title

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:19:3-152
  _actors is never used

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:48:3-14
  _id is never used
  <-- line 48
    @dead("_id") let _id = id

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:49:3-20
  _title is never used
  <-- line 49
    @dead("_title") let _title = title

  Warning Dead Value
  /Users/zth/OSS/rescript-edgedb/dbTestProject/src/Main.res:50:3-34
  _numberOfPets is never used
  <-- line 50
    @dead("_numberOfPets") let _numberOfPets = numberOfPets

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

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:108:5-30
  Client.tlsSecurity.Insecure is a variant case which is never constructed
  <-- line 108
      | @dead("Client.tlsSecurity.Insecure") @as("insecure") Insecure

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:109:7-52
  Client.tlsSecurity.NoHostVerification is a variant case which is never constructed
  <-- line 109
      | @dead("Client.tlsSecurity.NoHostVerification") @as("no_host_verification") NoHostVerification

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:110:7-26
  Client.tlsSecurity.Strict is a variant case which is never constructed
  <-- line 110
      | @dead("Client.tlsSecurity.Strict") @as("strict") Strict

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:111:7-28
  Client.tlsSecurity.Default is a variant case which is never constructed
  <-- line 111
      | @dead("Client.tlsSecurity.Default") @as("default") Default

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:531:7-22
  DataTypes.LocalDate.months.January is a variant case which is never constructed
  <-- line 531
        | @dead("DataTypes.LocalDate.months.January") @as(1) January

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:532:9-23
  DataTypes.LocalDate.months.February is a variant case which is never constructed
  <-- line 532
        | @dead("DataTypes.LocalDate.months.February") @as(2) February

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:533:9-20
  DataTypes.LocalDate.months.March is a variant case which is never constructed
  <-- line 533
        | @dead("DataTypes.LocalDate.months.March") @as(3) March

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:534:9-20
  DataTypes.LocalDate.months.April is a variant case which is never constructed
  <-- line 534
        | @dead("DataTypes.LocalDate.months.April") @as(4) April

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:535:9-18
  DataTypes.LocalDate.months.May is a variant case which is never constructed
  <-- line 535
        | @dead("DataTypes.LocalDate.months.May") @as(5) May

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:536:9-19
  DataTypes.LocalDate.months.June is a variant case which is never constructed
  <-- line 536
        | @dead("DataTypes.LocalDate.months.June") @as(6) June

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:537:9-19
  DataTypes.LocalDate.months.July is a variant case which is never constructed
  <-- line 537
        | @dead("DataTypes.LocalDate.months.July") @as(7) July

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:538:9-21
  DataTypes.LocalDate.months.August is a variant case which is never constructed
  <-- line 538
        | @dead("DataTypes.LocalDate.months.August") @as(8) August

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:539:9-24
  DataTypes.LocalDate.months.September is a variant case which is never constructed
  <-- line 539
        | @dead("DataTypes.LocalDate.months.September") @as(9) September

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:540:9-23
  DataTypes.LocalDate.months.October is a variant case which is never constructed
  <-- line 540
        | @dead("DataTypes.LocalDate.months.October") @as(10) October

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:541:9-24
  DataTypes.LocalDate.months.November is a variant case which is never constructed
  <-- line 541
        | @dead("DataTypes.LocalDate.months.November") @as(11) November

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:542:9-24
  DataTypes.LocalDate.months.December is a variant case which is never constructed
  <-- line 542
        | @dead("DataTypes.LocalDate.months.December") @as(12) December

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:545:7-21
  DataTypes.LocalDate.dayOfWeek.Monday is a variant case which is never constructed
  <-- line 545
        | @dead("DataTypes.LocalDate.dayOfWeek.Monday") @as(1) Monday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:546:9-22
  DataTypes.LocalDate.dayOfWeek.Tuesday is a variant case which is never constructed
  <-- line 546
        | @dead("DataTypes.LocalDate.dayOfWeek.Tuesday") @as(2) Tuesday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:547:9-24
  DataTypes.LocalDate.dayOfWeek.Wednesday is a variant case which is never constructed
  <-- line 547
        | @dead("DataTypes.LocalDate.dayOfWeek.Wednesday") @as(3) Wednesday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:548:9-23
  DataTypes.LocalDate.dayOfWeek.Thursday is a variant case which is never constructed
  <-- line 548
        | @dead("DataTypes.LocalDate.dayOfWeek.Thursday") @as(4) Thursday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:549:9-21
  DataTypes.LocalDate.dayOfWeek.Friday is a variant case which is never constructed
  <-- line 549
        | @dead("DataTypes.LocalDate.dayOfWeek.Friday") @as(5) Friday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:550:9-23
  DataTypes.LocalDate.dayOfWeek.Saturday is a variant case which is never constructed
  <-- line 550
        | @dead("DataTypes.LocalDate.dayOfWeek.Saturday") @as(6) Saturday

  Warning Dead Type
  /Users/zth/OSS/rescript-edgedb/src/EdgeDB.res:551:9-21
  DataTypes.LocalDate.dayOfWeek.Sunday is a variant case which is never constructed
  <-- line 551
        | @dead("DataTypes.LocalDate.dayOfWeek.Sunday") @as(7) Sunday
  
  Analysis reported 36 issues (Warning Dead Type:27, Warning Dead Value:9)`

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
