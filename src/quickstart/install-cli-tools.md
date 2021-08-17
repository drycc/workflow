## Drycc Workflow Client CLI

The Drycc command-line interface (CLI), lets you interact with Drycc Workflow.
Use the CLI to create and configure and manage applications.

Install the `drycc` client for Linux or Mac OS X with:

    $ curl -sSL https://raw.githubusercontent.com/drycc/workflow-cli/main/install.tmpl | bash -s v1.1.0

Others please visit: https://github.com/drycc/workflow-cli/releases

The installer places the `drycc` binary in your current directory, but you
should move it somewhere in your $PATH:

    $ sudo ln -fs $PWD/drycc /usr/local/bin/drycc

*or*:

    $ sudo mv $PWD/drycc /usr/local/bin/drycc

Check your work by running `drycc version`:

    $ drycc version
    v1.1.0

!!! note
    Note that version numbers may vary as new releases become available
