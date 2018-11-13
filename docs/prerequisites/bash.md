# Bash prerequisite

Run `bash --version` to check. You should see something like this:

```
$ bash --version
GNU bash, version 4.4.23(1)-release (x86_64-apple-darwin17.5.0)
...
```

On Linux boxes, this is now the default with recent distributions. On macOS
though, the default is a Bash version 3. In this case, you need to install a
more recent one whith `brew install bash` and ensure that `/usr/local/bin` in
front of your `$PATH`.
