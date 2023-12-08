# Users and SSH Keys

For **Dockerfile** and **Buildpack** based application deploys via `git push`, Drycc Workflow identifies users via SSH
keys. SSH keys are pushed to the platform and must be unique to each user. Users may have multiple SSH keys as needed.

## Generate an SSH Key

If you do not already have an SSH key or would like to create a new key for Drycc Workflow, generate a new key using
`ssh-keygen`:

```
$ ssh-keygen -f ~/.ssh/id_drycc -t rsa
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /Users/admin/.ssh/id_drycc.
Your public key has been saved in /Users/admin/.ssh/id_drycc.pub.
The key fingerprint is:
3d:ac:1f:f4:83:f7:64:51:c1:7e:7f:80:b6:70:36:c9 admin@plinth-23437.local
The key's randomart image is:
+--[ RSA 2048]----+
|              .. |
|               ..|
|           . o. .|
|         o. E .o.|
|        S == o..o|
|         o +.  .o|
|        . o + o .|
|         . o =   |
|          .   .  |
+-----------------+
$ ssh-add ~/.ssh/id_drycc
Identity added: /Users/admin/.ssh/id_drycc (/Users/admin/.ssh/id_drycc)
```

## Adding and Removing SSH Keys

By publishing the **public** half of your SSH key to Drycc Workflow the component responsible for receiving `git push`
will be able to authenticate the user and ensure that they have access to the destination application.

```
$ drycc keys:add ~/.ssh/id_drycc.pub
Uploading id_drycc.pub to drycc... done
```

You can always view the keys associated with your user as well:

```
$ drycc keys:list
ID                              OWNER    KEY                           
admin@plinth-23437.local        admin    ssh-rsa abc AAAAB3Nz...3437.local
admin@subgenius.local           admin    ssh-rsa 123 AAAAB3Nz...nius.local
```

Remove keys by their name:
```
$ drycc keys:remove admin@plinth-23437.local
Removing admin@plinth-23437.local SSH Key... don
```
