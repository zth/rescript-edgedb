// This file is just for marking fields as used, so we can try out the unused selections CLI.
let client = EdgeDB.Client.make()

let movies = await client->Movies.allMovies

let _ = movies->Array.forEach(movie => {
  let _id = movie.id
  let _actors = movie.actors->Array.forEach(actor => {
    let _id = actor.id
    let _name = actor.name
  })
})

let singleMovie = await client->Movies.movieByTitle(~title="The Great Adventure")

let _ = switch singleMovie {
| Some({title, actors: [{id, numberOfPets}]}) =>
  let _id = id
  let _title = title
  let _numberOfPets = numberOfPets
| _ => ()
}
