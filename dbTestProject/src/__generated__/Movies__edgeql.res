// @sourceHash 3d7911e6776c791d6a1b2296a1bd21b2

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
  
  let query = (client: EdgeDB.Client.t): promise<array<response>> => {
    client->EdgeDB.QueryHelpers.many(queryText)
  }
  
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
            numberOfPets := count(.pets)
        }
      } 
        filter .title = <str>$title
        limit 1`
  
    type args = {
      title: string,
    }
  
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
  
  let query = (client: EdgeDB.Client.t, args: args, ~onError=?): promise<option<response>> => {
    client->EdgeDB.QueryHelpers.single(queryText, ~args, ~onError?)
  }
  
  let transaction = (transaction: EdgeDB.Transaction.t, args: args, ~onError=?): promise<option<response>> => {
    transaction->EdgeDB.TransactionHelpers.single(queryText, ~args, ~onError?)
  }
}

module AddActor = {
  let queryText = `# @name AddActor
    insert Person {
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
  let queryText = `# @name RemoveActor
    delete Person filter .id = <uuid>$id`
  
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