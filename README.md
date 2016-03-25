# editpipe

Edit stdin using an editor before sending to stdout.

Example:

```
$ base64 /dev/urandom | head -n 10 | editpipe | shuf
```

The `editpipe` command will open the `EDITOR` or `VISUAL` command to edit the
intermediate 10 lines of base 64 text. When the file is saved and the editor is
closed, the output gets shuffled and printed to stdout.
