// @sourceHash 16f6ce89084f097aa7cf3106229fe5a9
module AllMovies = {
  let queryText = `select Movie {
      id,
      title,
      actors: {
          id,
          name,
          numberOfPets := count(.pets)
      }
    } order by .title`

  type response_actors = {
    id: string,
    name: string,
    numberOfPets: float,
  }

  type response = {
    id: string,
    title: string,
    actors: array<response_actors>,
  }

  let query = (client: EdgeDB.Client.t): promise<array<response>> => {
    client->EdgeDB.QueryHelpers.many(queryText)
  }

  let transaction = (transaction: EdgeDB.Transaction.t): promise<array<response>> => {
    transaction->EdgeDB.TransactionHelpers.many(queryText)
  }
}

module MovieByTitle = {
  let queryText = `select Movie {
      id,
      title,
      actors: {
          id,
          name,
          numberOfPets := count(.pets)
      }
    } 
      filter .title = <str>$title
      limit 1`

  type args = {
    title: string,
  }

  type response_actors = {
    id: string,
    name: string,
    numberOfPets: float,
  }

  type response = {
    id: string,
    title: string,
    actors: array<response_actors>,
  }

  let query = (client: EdgeDB.Client.t, args: args, ~onError=?): promise<option<response>> => {
    client->EdgeDB.QueryHelpers.single(queryText, ~args, ~onError?)
  }

  let transaction = (transaction: EdgeDB.Transaction.t, args: args, ~onError=?): promise<option<response>> => {
    transaction->EdgeDB.TransactionHelpers.single(queryText, ~args, ~onError?)
  }
}

module AddActor = {
  let queryText = `insert Person {
    name := <str>$name
  }`

  type args = {
    name: string,
  }

  type response = {
    id: string,
  }

  let query = (client: EdgeDB.Client.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    client->EdgeDB.QueryHelpers.singleRequired(queryText, ~args)
  }

  let transaction = (transaction: EdgeDB.Transaction.t, args: args): promise<result<response, EdgeDB.Error.errorFromOperation>> => {
    transaction->EdgeDB.TransactionHelpers.singleRequired(queryText, ~args)
  }
}

module RemoveActor = {
  let queryText = `delete Person filter .id = <uuid>$id`

  type args = {
    id: string,
  }

  type response = {
    id: string,
  }

  let query = (client: EdgeDB.Client.t, args: args, ~onError=?): promise<option<response>> => {
    client->EdgeDB.QueryHelpers.single(queryText, ~args, ~onError?)
  }

  let transaction = (transaction: EdgeDB.Transaction.t, args: args, ~onError=?): promise<option<response>> => {
    transaction->EdgeDB.TransactionHelpers.single(queryText, ~args, ~onError?)
  }
}

