# vscode-rescript-edgedb

`rescript-edgedb` comes with this dedicated [VSCode extension](https://marketplace.visualstudio.com/items?itemName=GabrielNordeborn.vscode-rescript-edgedb) designed to enhance the experience of using ReScript and EdgeDB together. Below is a list of how you use it, and what it can do.

> NOTE: Make sure you install the [official EdgeDB extension](https://marketplace.visualstudio.com/items?itemName=magicstack.edgedb) as well, so you get syntax highlighting and more.

### Snippets

Snippets for easily adding new `%edgeql` blocks are included:

![snippets](https://github.com/zth/rescript-edgedb/assets/1457626/8dc1c54b-470d-4dee-9598-e26d35632286)

These appear as soon as you start writing `%edgeql` in a ReScript file.

### In editor error messages

Any errors for your EdgeQL queries will show directly in your ReScript files that define them:

![in-editor-errors](https://github.com/zth/rescript-edgedb/assets/1457626/19f6bf01-5648-4354-b510-881ed9b05c3a)

### Easily edit queries in the dedicated EdgeDB UI

You can easily open the local EdgeDB UI, edit your query in there (including running it, etc), and then insert the modified query back:

![open-in-edgedb-ui](https://github.com/zth/rescript-edgedb/assets/1457626/e4dca50c-de60-4a78-8de9-f195a2cfd88d)

It works like this:

1. Put the cursor in the query you want to edit.
2. Activate code actions.
3. Select the code action for opening the EdgeDB UI and copying the query.
4. The local EdgeDB query editor UI will now open in your browser, and the EdgeQL query you had your cursor in will be copied to your clipboard.
5. Paste the query into the query editor and make the edits you want.
6. Copy the entire query text and go back to VSCode and the file which has your query.
7. Activate code actions again and select the code action for inserting your modified query.
8. Done!
