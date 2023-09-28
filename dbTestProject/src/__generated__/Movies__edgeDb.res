// @sourceHash 01305a8db8adc45b940edf2e8fbf11b7
module AllMovies = {
  let queryText = `select Movie {
      id,
      title,
      actors: {
          id,
          name,
          numberOfPets := count(.pets)
      }
    }`

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
}

