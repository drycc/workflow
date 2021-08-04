# Drycc Workflow  CLI

The Drycc Workflow command-line interface (CLI), or client, allows you to interact
with Drycc Workflow.

## Installation

Install the latest `drycc` client for Linux or Mac OS X with:

    $ curl -sSL https://raw.githubusercontent.com/drycc/workflow-cli/main/install.tmpl | bash -s v1.1.0

The installer puts `drycc` in your current directory, but you should move it
somewhere in your $PATH:

    $ ln -fs $PWD/drycc /usr/local/bin/drycc

## Getting Help

The Drycc client comes with comprehensive documentation for every command.
Use `drycc help` to explore the commands available to you:

    $ drycc help
    The Drycc command-line client issues API calls to a Drycc controller.

    Usage: drycc <command> [<args>...]

    Auth commands::

      login         login to a controller
      logout        logout from the current controller

    Subcommands, use `drycc help [subcommand]` to learn more::
    ...

To get help on subcommands, use `drycc help [subcommand]`:

    $ drycc help apps
    Valid commands for apps:

    apps:create        create a new application
    apps:list          list accessible applications
    apps:info          view info about an application
    apps:open          open the application in a browser
    apps:logs          view aggregated application logs
    apps:run           run a command in an ephemeral app container
    apps:destroy       destroy an application
    apps:transfer      transfer app ownership to another user

    Use `drycc help [command]` to learn more


## Support for Multiple Profiles

The CLI reads from the default `client` profile, which is located on your
workstation at `$HOME/.drycc/client.json`.

Easily switch between multiple Drycc Workflow installations or users by setting
the `$DRYCC_PROFILE` environment variable or by using the `-c` flag.

There are two ways to set the `$DRYCC_PROFILE` option.

1. Path to a json configuration file.
2. Profile name. If you set profile to just a name, it will be saved alongside the default profile,
   in `$HOME/.drycc/<name>.json`.

Examples:

    $ DRYCC_PROFILE=production drycc login drycc.production.com
    ...
    Configuration saved to /home/testuser/.drycc/production.json
    $ DRYCC_PROFILE=~/config.json drycc login drycc.example.com
    ...
    Configuration saved to /home/testuser/config.json

The configuration flag works identically to and overrides `$DRYCC_PROFILE`:

    $ drycc whoami -c ~/config.json
    You are drycc at drycc.example.com

## Proxy Support

If your workstation uses a proxy to reach the network where the cluster lies,
set the `http_proxy` or `https_proxy` environment variable to enable proxy support:

    $ export http_proxy="http://proxyip:port"
    $ export https_proxy="http://proxyip:port"

!!! note
    Configuring a proxy is generally not necessary for local Minikube clusters.

## CLI Plugins

Plugins allow developers to extend the functionality of the Drycc Client, adding new commands or features.

If an unknown command is specified, the client will attempt to execute the command as a dash-separated command. In this case, `drycc resource:command` will execute `drycc-resource` with the argument list `command`. In full form:

    $ # these two are identical
    $ drycc accounts:list
    $ drycc-accounts list

Any flags after the command will also be sent to the plugin as an argument:

    $ # these two are identical
    $ drycc accounts:list --debug
    $ drycc-accounts list --debug

But flags preceding the command will not:

    $ # these two are identical
    $ drycc --debug accounts:list
    $ drycc-accounts list
