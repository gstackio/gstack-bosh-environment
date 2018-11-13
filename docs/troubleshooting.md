# Troubleshooting GBE

```
Received disconnect from 192.168.50.6 port 22:2: Too many authentication failures for jumpbox
```

This is a very common error. It means that you have too many keys loaded by
your SSH agent, and when trying to SSH to the jumpbox, too many keys are tried
before finding the right one. You can see the list of tried keys with
`ssh-add -L`.

The solution is to run `ssh-add -D` to remove them, then restart the `gbe`
command you were running.
