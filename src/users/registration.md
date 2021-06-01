# Users and Registration

Workflow use the passport component to create and authorize users

## Login to Workflow

If you already have an account, use `drycc login` to authenticate against the Drycc Workflow API.

    $ drycc login http://drycc.example.com

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

[controller]: ../understanding-workflow/components.md#controller
