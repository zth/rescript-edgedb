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

  client->query
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
          numberOfPets := count(.pets)
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
