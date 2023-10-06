Provision Dedibox
=================

Usage
-----

Set your username as the `remote_user` config in `ansible.cfg` (which defaults
to `ubuntu`).

Given that your target bare metal host is `11.22.33.44`, run the following
command.

```sh
ansible-playbook -i inventory.cfg --ask-become provision.yml \
    -e target_host=11.22.33.44 -e garden_vm_ip=192.168.50.7
```

The sudo password is the one relevant for becoming `root` on the target host.


### With inventory file

Given that your target bare metal host is `11.22.33.44`, edit your
`inventory.cfg` file as follows.

```ini
[dedibox]
11.22.33.44
```

Then run the following command.

```sh
ansible-playbook --ask-become provision.yml \
    -e target_host=dedibox \
    -e garden_vm_ip=192.168.50.7
```

The default CIDR ranges for networks are the following:

| Network type | CIDR range        | Purpose             |
+--------------+-------------------+---------------------+
| VirtualBox   | `192.168.50.0/24` | Garden and Bosh VMs |
| Garden       | `10.244.0.0/16`   | Bosh-Lite instances |

In order to create a second Bosh environment in a given “dedibox” (shortened
“ddbox”) bare-metal box, you'll need to customize theese two CIDR ranges.

In the following example, `192.168.30.0/24` is chosen for the 2nd VirtualBox
network, and `10.224.0.0/16` for the Garden network:

```sh
ansible-playbook --ask-become provision.yml \
    -e target_host=dedibox \
    -e vbox_host_ip=192.168.30.1 \
    -e garden_vm_ip=192.168.30.7 \
    -e garden_cidr=10.224.0.0/16 \
    --tags vm-networking
```

When in need to reset the iptables networking customizations, you can focus on
setting up VM networking only with `--tags vm-networking` like this:

```sh
ansible-playbook --ask-become provision.yml \
    -e <...> \
    --tags vm-networking
```
