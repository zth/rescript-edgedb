# rescript-edgedb

Use EdgeDB fully type safe in ReScript. Embed EdgeQL right in your ReScript source code.

## Getting started

```bash
npm i rescript-edgedb rescript-embed-lang
```

Also make sure you have `@rescript/core >= 0.5.0`. It's required.

Setup your `bsconfig.json`:

```json
"bs-dependencies": ["@rescript/core", "rescript-edgedb"]
"ppx-flags": ["rescript-embed-lang/ppx"]
```

The `rescript-edgedb` watcher needs to run for your EdgeQL to be compiled. Set up scripts in your `package.json` to do that:

```json
"scripts": {
  "build:edgedb": "rescript-edgedb generate --output ./src/__generated__ --src ./src",
  "watch:edgedb": "npm run build:edgedb -- --watch"
}
```

> The CLI will walk upwards looking for `edgedb.toml` in order to find how to connect to your database. So, you don't need to give the CLI any details on how to connect your database (although you can if you want).

- `--src` should point to the root directory where you have ReScript files that contain `%edgeql` tags you want compiled. This directory will be searched (and watched) recursively.
- `--output` should point to the directory where you want all _generated_ files to end up. This needs to be a directory that's part of your ReScript project, so the ReScript compiler can pick them up.

### Writing queries

Finally, after starting `npm run watch:edgedb` and ensuring the console output looks fine, we can write our first EdgeQL query:

```rescript
// Movies.res
let findMovies = %edgeql(`
    # @name findMovies
    select Movie {
        title,
        status,
        actors: {
            name,
            age
        }
    } filter
      .title = <str>$movieTitle`)
```

Executing the query is done by passing it the `client`, and arguments if it takes any.

```rescript
let findMovie = %edgeql(`
    # @name findMovies
    select Movie {
        title,
        status,
        actors: {
            name,
            age
        }
    } filter
        .title = <str>$movieTitle`)

// array<movie>
let movies = await client->findMovies({
    movieTitle: title,
})
```

There's just one thing to notice in relation to regular EdgeQL - we require you to put a comment at the top of your query with a `@name` annotation, naming the query. This is because we need to be able to discern which query is which in the current ReScript file, since you can put as many queries as you want in the same ReScript file.

### `let` binding or `module`

EdgeQL can be written both as a `let` binding like above, or as a `module` binding:

```rescript
// Movies.res
let findMovies = %edgeql(`
  # @name findMovies
  select Movie {
      title,
      status,
      actors: {
          name,
          age
      }
  } filter
    .title = <str>$movieTitle
`)

let movies = await client->findMovies({
  movieTitle: "Jalla Jalla",
})

module DeleteMovie = %edgeql(`
  # @name deleteMovie
  delete Movie filter
    .title = <str>$movieTitle
`)

let _maybeDeletedMovie = await client->DeleteMovie.query({
  title: "Jalla Jalla"
})
```

The _only_ difference between these two is that the `let` binding gives you access to the generated `query` (which you use to execute the query) directly, whereas the `module` binding gives you access to the _entire_ generated module for the EdgeQL you write. This includes `query` (like with the `let` binding), the generated types for all of the query contents (args and response), and an extra `transaction` function that you can use in transactions. More about transactions below.

`let` binding style EdgeQL is the thing you'll use most of all - it's to the point, and can be defined anywhere. `module` bindings need to be at the top level. But, sometimes you need it.

> We might consider adding a "transaction mode" to the `let` binding as well in the future. Defining the queries inline is very powerful, and forcing you to define things at the top level because of `module` isn't the best DX at all times.

### Using transactions

There's a `transaction` function emitted for each EdgeQL query. You can use that to do your operation in a transaction:

```rescript
let client = EdgeDB.Client.make()

// Remember to define your EdgeQL using a module, so you get easy access to all generated functions.
module InsertMovie = %edgeql(`
  # @name insertMovie
  insert Movie {
      title := <str>$title,
      status := <PublishStatus>$status
  }`)

await client->EdgeDB.Client.transaction(async tx => {
  await tx->InsertMovie.transaction({
    title: "Jalla Jalla",
    status: #Published
  })
})
```

### Cardinality

> Cardinality = how many results are returned from your query.

EdgeDB and `rescript-edgedb` automatically manages the cardinality of each query for you. That means that you can always trust the return types of your query. For example, adding `limit 1` to the `findMovies` query above would make the return types `option<movie>` instead of `array<movie>`.

Similarily, you can design the query so that it expects there to always be exactly 1 response, and error if that's not the case. In that case, the return type would be `result<movie, EdgeDB.Error.operationError>`.

Here's a complete list of the responses your EdgeQL queries can produce:

- `void` - Nothing. No results are returned at all.
- `array<response>` - Many. A list of all results.
- `option<response>` - Maybe one.
- `result<response, EdgeDB.Error.errorFromOperation>` Exactly one. Or an error.

## The CLI

You can get a full list of supported CLI commands by running `npx rescript-edgedb --help`. More documentation on the exact parameters available is coming.

## So, how does it work?

`rescript-edgedb` consists of 2 parts:

1. A code generator that generates ReScript from your EdgeQL.
2. A PPX transform that swaps your `%edgeql` tag to its corresponding generated code, via [`rescript-embed-lang`](https://github.com/zth/rescript-embed-lang).

Take this query as an example:

```rescript
// Movies.res
let findMovies = %edgeql(`
  # @name findMovies
  select Movie {
      title,
      status,
      actors: {
          name,
          age
      }
  } filter
    .title = <str>$movieTitle`)
```

The `rescript-edgedb` tooling finds this `%edgeql` tag, and generates a file called `Movies__edgeql.res` from it, using code generation leveraging the official EdgeDB type generation tooling. That file will contain generated code and types for the `findMovies` query:

```rescript
// @sourceHash 18807b4839373ee493a3aaab68766f53
module FindMoviesQuery = {
  let queryText = `select Movie {
        title,
        status,
        actors: {
            name,
            age
        }
    } filter
      .title = <str>$movieTitle`

  type args = {
    movieTitle: string,
  }

  type response_actors = {
    name: string,
    age: Null.t<int>,
  }

  type response = {
    title: string,
    status: [#Published | #Unpublished],
    actors: array<response_actors>,
  }

  let query = (client: EdgeDB.Client.t, args: args): promise<array<response>> => {
    client->EdgeDB.QueryHelpers.many(queryText, ~args)
  }

  let transaction = (transaction: EdgeDB.Transaction.t, args: args): promise<array<response>> => {
    transaction->EdgeDB.TransactionHelpers.many(queryText, ~args)
  }
}
```

Thanks to `rescript-embed-lang`, you don't have to think about that generated file at all. It's automatically managed for you.

## FAQ

**Should I check the generated files into source control?**
Yes, you should. This ensures building the project doesn't _have_ to rely on a running EdgeDB instance (which the code generation tooling requires).

## WIP

- [x] Simple transactions support
- [x] CLI to statically prevent overfetching
- [ ] Improve CLI docs
- [x] Test/example project
- [x] Figure out publishing
- [ ] Generate docs using new ReScript doc generation

## Contributing

`rescript-edgedb` leverages Bun for local development, including running tests.
