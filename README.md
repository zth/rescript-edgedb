# rescript-edgedb

Use EdgeDB fully type safe in ReScript. Embed EdgeQL right in your ReScript source code.

## Getting started

`rescript-edgedb` consists of 2 parts: 1) a code generator that generates ReScript from your EdgeQL, and 2) a PPX transform that connects the generated code to your ReScript source, via [`rescript-embed-lang`](https://github.com/zth/rescript-embed-lang).

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
  "build:edgedb": "rescript-edgedb generate --output ./__generated__ --src ./src",
  "watch:edgedb": "npm run build:edgedb -- --watch"
}
```

> The CLI will walk upwards looking for `edgedb.toml` in order to find how to connect to your database.

`--src` should point to the root directory where you have ReScript files that contain `%edgeql` tags you want compiled. `---output` should point to the directory where you want all _generated_ files to end up. This needs to be a directory that's part of your ReScript project, so the ReScript compiler can pick them up.

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

And this will generate a file called `Movies__edgeDb.res` which will contain the generated code and types for the `findMovies` query:

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
}
```

Thanks to `rescript-embed-lang`, you don't have to think about that generated file at all. It's automatically managed for you. Instead, you can simply use your `findMovie` value and execute your query, fully type safe:

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

### Cardinality

EdgeDB and `rescript-edgedb` automatically manages the cardinality of each query for you. That means that you can always trust the return types of your query. For example, adding `limit 1` to the `findMovies` query above would make the return types `option<movie>` instead of `array<movie>`.

Similarily, you can design the query so that it expects there to always be exactly 1 response, and error if that's not the case. In that case, the return type would be `result<movie, EdgeDB.Error.operationError>`.

## The CLI

You can get a full list of supported CLI commands by running `npx rescript-edgedb --help`. More documentation on the exact parameters available is coming.

## FAQ

**Should I check the generated files into source control?**
Yes, you should. This ensures building the project doesn't _have_ to rely on a running EdgeDB instance (which the code generation tooling requires).

## WIP

- [ ] Simple transactions support
- [ ] CLI to statically prevent overfetching
- [ ] Improve CLI docs
- [ ] Test/example project
- [ ] Figure out publishing
- [ ] Generate docs using new ReScript doc generation

## Contributing

`rescript-edgedb` leverages Bun for local development, including running tests.
