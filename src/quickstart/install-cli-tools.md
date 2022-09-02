## Drycc Workflow Client CLI

The Drycc command-line interface (CLI), lets you interact with Drycc Workflow.
Use the CLI to create and configure and manage applications.

Install the `drycc` client for Linux or Mac OS X with:

```
$ curl -sfL https://www.drycc.cc/install-cli.sh | bash -
```

!!! important
    Users in Chinese mainland can use the following methods to speed up installation:

    ```
    $ curl -sfL https://www.drycc.cc/install-cli.sh | INSTALL_DRYCC_MIRROR=cn bash -
    ```

Others please visit: https://github.com/drycc/workflow-cli/releases

The installer places the `drycc` binary in your current directory, but you
should move it somewhere in your $PATH:

```
$ sudo ln -fs $PWD/drycc /usr/local/bin/drycc
```

*or*:

```
$ sudo mv $PWD/drycc /usr/local/bin/drycc
```

Check your work by running `drycc version`:

```
$ drycc version
v1.1.0
```

!!! note
    Note that version numbers may vary as new releases become available
