# Users and Registration

There are two classes of Workflow users: normal users and administrators.

 * Users can use most of the features of Workflow - creating and deploying applications, adding/removing domains, etc.
 * Administrators can perform all the actions that users can, but they also have owner access to all applications.

The first user created on a Workflow installation is automatically an administrator.

## Register with a Controller

Use `drycc register` with the [Controller][] URL (supplied by your Drycc administrator)
to create a new account. After successful registration you will be logged in as the new user.

    $ drycc register http://drycc.example.com
    username: myuser
    password:
    password (confirm):
    email: myuser@example.com
    Registered myuser
    Logged in as myuser

!!! important
    The first user to register with Drycc Workflow automatically becomes an administrator. Additional users who register will be ordinary users.

## Login to Workflow

If you already have an account, use `drycc login` to authenticate against the Drycc Workflow API.

    $ drycc login http://drycc.example.com
    username: drycc
    password:
    Logged in as drycc

## Logout from Workflow

Logout of an existing controller session using `drycc logout`.

    $ drycc logout
    Logged out as drycc

## Verify Your Session

You can verify your client configuration by running `drycc whoami`.

    $ drycc whoami
    You are drycc at http://drycc.example.com

!!! note
    Session and client configuration is stored in the `~/.drycc/client.json` file.

## Registering New Users

By default, new users are not allowed to register after an initial user does. That initial user
becomes the first "admin" user. Others will now receive an error when trying to register, but when
logged in, an admin user can register new users:

```shell
$ drycc register --login=false --username=newuser --password=changeme123 --email=newuser@drycc.cc
```

## Controlling Registration Modes

After creating your first user, you may wish to change the registration mode for Drycc Workflow.

Drycc Workflow supports three registration modes:

| Mode                  | Description                                     |
| ---                   | ---                                             |
| admin\_only (default) | Only existing admins may register new users     |
| enabled               | Registration is enabled and anyone can register |
| disabled              | Does not allow anyone to register new users.    |

To modify the registration mode for Workflow you may add or modify the `REGISTRATION_MODE` environment variable for the
controller component. If Drycc Workflow is already running, use:

`kubectl --namespace=drycc patch deployments drycc-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"drycc-controller","env":[{"name":"REGISTRATION_MODE","value":"disabled"}]}]}}}}'`

Modify the `value` portion to match the desired mode.

Kubernetes will automatically deploy a new ReplicaSet and corresponding Pod with the new environment variables set.

## Managing Administrative Permissions

You can use the `drycc perms` command to promote a user to an admin:

```
$ drycc perms:create john --admin
Adding john to system administrators... done
```

View current admins:

```
$ drycc perms:list --admin
=== Administrators
admin
john
```

Demote admins to normal users:

```
$ drycc perms:delete john --admin
Removing john from system administrators... done
```

## Re-issuing User Authentication Tokens

The controller API uses a simple token-based HTTP Authentication scheme. Token authentication is appropriate for
client-server setups, such as native desktop and mobile clients. Each user of the platform is issued a token the first
time that they sign up on the platform. If this token is compromised, it will need to be regenerated.

A user can regenerate their own token like this:

    $ drycc auth:regenerate

An administrator can also regenerate the token of another user like this:

    $ drycc auth:regenerate -u test-user

At this point, the user will no longer be able to authenticate against the controller with his auth token:

    $ drycc apps
    401 UNAUTHORIZED
    Detail:
    Invalid token

They will need to log back in to use their new auth token.

If there is a cluster wide security breach, an administrator can regenerate everybody's auth token like this:

    $ drycc auth:regenerate --all=true


## Changing Account Password

A user can change their own account's password like this:

```
$ drycc auth:passwd
current password:
new password:
new password (confirm):
```

An administrator can change the password of another user's account like this:

```
$ drycc auth:passwd --username=<username>
new password:
new password (confirm):
```

[controller]: ../understanding-workflow/components.md#controller
