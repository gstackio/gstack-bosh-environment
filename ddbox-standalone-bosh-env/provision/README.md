Provision Dedibox
=================

Usage
-----

Set your username as the `remote_user` config in `ansible.cfg` (which defaults
to `ubuntu`).

Given that your target bare metal host is `11.22.33.44`, run the following
command.

    ansible-playbook -i inventory.cfg --ask-become provision.yml \
         -e target_host=11.22.33.44 -e garden_vm_ip=192.168.50.7

The sudo password is the one relevant for becoming `root` on the target host.


### With inventory file

Given that your target bare metal host is `11.22.33.44`, edit your
`inventory.cfg` file as follows.

    [dedibox]
    11.22.33.44

Then run the following command.

    ansible-playbook -i inventory.cfg --ask-become provision.yml \
         -e garden_vm_ip=192.168.50.7
