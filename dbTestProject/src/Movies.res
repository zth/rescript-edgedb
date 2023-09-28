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

let _ = %edgeql(`
  # @name AddActor
  insert Person {
    name := <str>$name
  }
`)

// Workaround until new release of rescript-embed-lang
let addActor = Movies__edgeDb.AddActor.transaction

let _ = %edgeql(`
  # @name RemoveActor
  delete Person filter .id = <uuid>$id
`)

// Workaround until new release of rescript-embed-lang
let removeActor = Movies__edgeDb.RemoveActor.transaction
