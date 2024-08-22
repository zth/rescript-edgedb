// @sourceHash 8b3b5cd8dbf0f74596f7a74af8554e12

module AllMovies = {
  let queryText = `# @name allMovies
      select Movie {
        id,
        title,
        actors: {
            id,
            name,
            numberOfPets := count(.pets)
        }
      } order by .title`
  
  type response__actors = {
    id: string,
    name: string,
    numberOfPets: float,
  }
  
  type response = {
    id: string,
    title: string,
    actors: array<response__actors>,
  }
  
  @live
  let query = (client: EdgeDB.Client.t): promise<array<response>> => {
    client->EdgeDB.QueryHelpers.many(queryText)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t): promise<array<response>> => {
    transaction->EdgeDB.TransactionHelpers.many(queryText)
  }
}

module CountAllMovies = {
  let queryText = `# @name countAllMovies
      select count(Movie);`
  
  type response = float
  
  @live
  let query = (client: EdgeDB.Client.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText)
  }
}

module CountAllMoviesWithParam = {
  let queryText = `# @name countAllMoviesWithParam
      select count(Movie filter .title = <str>$title);`
  
  @live  
  type args = {
    title: string,
  }
  
  type response = float
  
  @live
  let query = (client: EdgeDB.Client.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText, ~args)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText, ~args)
  }
}

module TestBool = {
  let queryText = `# @name testBool
     select '!' IN {'hello', 'world'};`
  
  type response = bool
  
  @live
  let query = (client: EdgeDB.Client.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText)
  }
}

module TestString = {
  let queryText = `# @name testString
      select r'A raw \n string';`
  
  type response = string
  
  @live
  let query = (client: EdgeDB.Client.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText)
  }
}

module AllMoviesNested = {
  let queryText = `# @name allMoviesNested
      select Movie {
        id,
        title,
        actors: {
            id,
            name,
            numberOfPets := count(.pets)
        }
      } order by .title`
  
  type response__actors = {
    id: string,
    name: string,
    numberOfPets: float,
  }
  
  type response = {
    id: string,
    title: string,
    actors: array<response__actors>,
  }
  
  @live
  let query = (client: EdgeDB.Client.t): promise<array<response>> => {
    client->EdgeDB.QueryHelpers.many(queryText)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t): promise<array<response>> => {
    transaction->EdgeDB.TransactionHelpers.many(queryText)
  }
}

module MovieByTitle = {
  let queryText = `# @name movieByTitle
      select Movie {
        id,
        title,
        actors: {
            id,
            name,
            numberOfPets := count(.pets),
            typesDump: {
              date,
              localDateTime,
              localDate,
              relativeDuration,
              duration,
              dateDuration,
              localTime,
              json
            }
        }
      }
        filter .title = <str>$title
        limit 1`
  
  @live  
  type args = {
    title: string,
  }
  
  type response__actors__typesDump = {
    date: Null.t<Date.t>,
    localDateTime: Null.t<EdgeDB.DataTypes.LocalDateTime.t>,
    localDate: Null.t<EdgeDB.DataTypes.LocalDate.t>,
    relativeDuration: Null.t<EdgeDB.DataTypes.RelativeDuration.t>,
    duration: Null.t<EdgeDB.DataTypes.Duration.t>,
    dateDuration: Null.t<EdgeDB.DataTypes.DateDuration.t>,
    localTime: Null.t<EdgeDB.DataTypes.LocalTime.t>,
    json: Null.t<JSON.t>,
  }
  
  type response__actors = {
    id: string,
    name: string,
    numberOfPets: float,
    typesDump: Null.t<response__actors__typesDump>,
  }
  
  type response = {
    id: string,
    title: string,
    actors: array<response__actors>,
  }
  
  @live
  let query = (client: EdgeDB.Client.t, args: args, ~onError=?): promise<option<response>> => {
    client->EdgeDB.QueryHelpers.single(queryText, ~args, ~onError?)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t, args: args, ~onError=?): promise<option<response>> => {
    transaction->EdgeDB.TransactionHelpers.single(queryText, ~args, ~onError?)
  }
}

module AddActor = {
  let queryText = `# @name AddActor
    insert Person {
      name := <str>$name
    }`
  
  @live  
  type args = {
    name: string,
  }
  
  type response = {
    id: string,
  }
  
  @live
  let query = (client: EdgeDB.Client.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText, ~args)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText, ~args)
  }
}

module RemoveActor = {
  let queryText = `# @name RemoveActor
    delete Person filter .id = <uuid>$id`
  
  @live  
  type args = {
    id: string,
  }
  
  type response = {
    id: string,
  }
  
  @live
  let query = (client: EdgeDB.Client.t, args: args, ~onError=?): promise<option<response>> => {
    client->EdgeDB.QueryHelpers.single(queryText, ~args, ~onError?)
  }
  
  @live
  let transaction = (transaction: EdgeDB.Transaction.t, args: args, ~onError=?): promise<option<response>> => {
    transaction->EdgeDB.TransactionHelpers.single(queryText, ~args, ~onError?)
  }
}