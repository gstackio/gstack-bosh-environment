# Troubleshooting GBE


## Too many authentication failures

```
Received disconnect from 192.168.50.6 port 22:2: Too many authentication failures for jumpbox
```

This is a very common error. It means that you have too many keys loaded by
your SSH agent, and when trying to SSH to the jumpbox, too many keys are tried
before finding the right one. You can see the list of tried keys with
`ssh-add -L`.

The solution is to run `ssh-add -D` to remove them, then restart the `gbe`
command you were running.


## Debugging GBE

When you face an issue with GBE, you can inspect what's going wrong, lauching
it again with this trick to activate the `xtrace` Bash option.

    $ bash -x $(which gbe) <command> ...

When you need to debug a `bosh create-env` issue in `gbe up`, you can run GBE
with the `GBE_DEBUG_LEVEL=1` in your environment.

    $ GBE_DEBUG_LEVEL=1 gbe up
    $ less "./state/${GBE_ENVIRONMENT:-ddbox-env}/bosh-create-env.log"

Then you'll find the `bosh create-env` debug logs in
`./state/${GBE_ENVIRONMENT}/bosh-create-env.log`. These logs a hundreds of MB
wide, so be careful to remove them first when you need to SCP your state
directory to another machine.
