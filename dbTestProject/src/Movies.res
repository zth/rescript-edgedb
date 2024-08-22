let allMovies = client => {
  let query = %edgeql(`
    # @name allMovies
    select Movie {
      id,
      title,
      actors: {
          id,
          name,
          numberOfPets := count(.pets)
      }
    } order by .title
    `)

  // let query = %edgeql(`
  //# @name allMovies2
  //select Movie {
  //  id
  //} order by .title
  //`)

  client->query
}

let countAllMovies = client => {
  let query = %edgeql(`
    # @name countAllMovies
    select count(Movie);
  `)

  client->query
}

let countAllMoviesWithParam = (client, ~title) => {
  let query = %edgeql(`
    # @name countAllMoviesWithParam
    select count(Movie filter .title = <str>$title);
  `)

  client->query({title: title})
}

let testBool = client => {
  let query = %edgeql(`
    # @name testBool
   select '!' IN {'hello', 'world'};
  `)

  client->query
}

let testString = client => {
  let query = %edgeql(`
    # @name testString
    select r'A raw \n string';
  `)

  client->query
}

module Nested = {
  let query = %edgeql(`
    # @name allMoviesNested
    select Movie {
      id,
      title,
      actors: {
          id,
          name,
          numberOfPets := count(.pets)
      }
    } order by .title
    `)
}

let movieByTitle = (client, ~title) => {
  let query = %edgeql(`
    # @name movieByTitle
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
      limit 1
    `)

  client->query({
    title: title,
  })
}

module AddActor = %edgeql(`
  # @name AddActor
  insert Person {
    name := <str>$name
  }
`)

let addActor = AddActor.transaction

module RemoveActor = %edgeql(`
  # @name RemoveActor
  delete Person filter .id = <uuid>$id
`)

let removeActor = RemoveActor.transaction
