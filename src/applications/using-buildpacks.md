# Using Buildpacks

Drycc supports deploying applications via [Cloud Native Buildpacks](https://buildpacks.io/). Cloud Native Buildpacks are useful if you want to follow [cnb's docs](https://buildpacks.io/docs/) for building applications.

## Add SSH Key

For **Buildpack** based application deploys via `git push`, Drycc Workflow identifies users via SSH keys. SSH keys are pushed to the platform and must be unique to each user.

- See [this document](../users/ssh-keys.md#generate-an-ssh-key) for instructions on how to generate an SSH key.

- Run `drycc keys:add` to upload your SSH key to Drycc Workflow.

```
$ drycc keys:add ~/.ssh/id_drycc.pub
Uploading id_drycc.pub to drycc... done
```

Read more about adding/removing SSH Keys [here](../users/ssh-keys.md#adding-and-removing-ssh-keys).

## Prepare an Application

If you do not have an existing application, you can clone an example application that demonstrates the Heroku Buildpack workflow.

    $ git clone https://github.com/drycc/example-go.git
    $ cd example-go


## Create an Application

Use `drycc create` to create an application on the [Controller][].

    $ drycc create
    Creating application... done, created skiing-keypunch
    Git remote drycc added


## Push to Deploy

Use `git push drycc master` to deploy your application.

    $ git push drycc master
    Counting objects: 75, done.
    Delta compression using up to 8 threads.
    Compressing objects: 100% (48/48), done.
    Writing objects: 100% (75/75), 18.28 KiB | 0 bytes/s, done.
    Total 75 (delta 30), reused 58 (delta 22)
    remote: --->
    Starting build... but first, coffee!
    ---> Waiting podman running.
    ---> Process podman started.
    ---> Waiting caddy running.
    ---> Process caddy started.
    ---> Building pack
    ---> Using builder registry.drycc.cc/drycc/buildpacks:bookworm
    Builder 'registry.drycc.cc/drycc/buildpacks:bookworm' is trusted
    Pulling image 'registry.drycc.cc/drycc/buildpacks:bookworm'
    Resolving "drycc/buildpacks" using unqualified-search registries (/etc/containers/registries.conf)
    Trying to pull registry.drycc.cc/drycc/buildpacks:bookworm...
    Getting image source signatures
    ...
    ---> Skip generate base layer
    ---> Python Buildpack
    ---> Downloading and extracting Python 3.10.0
    ---> Installing requirements with pip
    Collecting Django==3.2.8
    Downloading Django-3.2.8-py3-none-any.whl (7.9 MB)
    Collecting gunicorn==20.1.0
    Downloading gunicorn-20.1.0-py3-none-any.whl (79 kB)
    Collecting sqlparse>=0.2.2
    Downloading sqlparse-0.4.2-py3-none-any.whl (42 kB)
    Collecting pytz
    Downloading pytz-2021.3-py2.py3-none-any.whl (503 kB)
    Collecting asgiref<4,>=3.3.2
    Downloading asgiref-3.4.1-py3-none-any.whl (25 kB)
    Requirement already satisfied: setuptools>=3.0 in /layers/drycc_python/python/lib/python3.10/site-packages (from gunicorn==20.1.0->-r requirements.txt (line 2)) (57.5.0)
    Installing collected packages: sqlparse, pytz, asgiref, gunicorn, Django
    Successfully installed Django-3.2.8 asgiref-3.4.1 gunicorn-20.1.0 pytz-2021.3 sqlparse-0.4.2
    ---> Generate Launcher
    ...
    Build complete.
    Launching App...
    ...
    Done, skiing-keypunch:v2 deployed to Workflow

    Use 'drycc open' to view this application in your browser

    To learn more, use 'drycc help' or visit https://www.drycc.cc

    To ssh://git@drycc.staging-2.drycc.cc:2222/skiing-keypunch.git
     * [new branch]      master -> master

    $ curl -s http://skiing-keypunch.example.com
    Powered by Drycc
    Release v2 on skiing-keypunch-v2-web-02zb9

Because a Buildpacks-style application is detected, the `web` process type is automatically scaled to 1 on first deploy.

Use `drycc scale web=3` to increase `web` processes to 3, for example. Scaling a
process type directly changes the number of [pods] running that process.


## Included Buildpacks

For convenience, a number of buildpacks come bundled with Drycc:

 * [Go Buildpack][]
 * [Java Buildpack][]
 * [Nodejs Buildpack][]
 * [PHP Buildpack][]
 * [Python Buildpack][]
 * [Ruby Buildpack][]
 * [Rust Buildpack][]

Drycc will cycle through the `bin/detect` script of each buildpack to match the code you
are pushing.

!!! note
    If you're testing against the [Scala Buildpack][], the [Builder][] requires at least
    512MB of free memory to execute the Scala Build Tool.


## Using a Custom Buildpack

To use a custom buildpack, you need create a `.pack_builder` file in your root path app.

    $  tee > .pack_builder << EOF
       > registry.drycc.cc/drycc/buildpacks:bookworm
       > EOF

On your next `git push`, the custom buildpack will be used.

## Using Private Repositories

To pull code from private repositories, set the `SSH_KEY` environment variable to a private key
which has access. Use either the path of a private key file or the raw key material:

    $ drycc config:set SSH_KEY=/home/user/.ssh/id_rsa
    $ drycc config:set SSH_KEY="""-----BEGIN RSA PRIVATE KEY-----
    (...)
    -----END RSA PRIVATE KEY-----"""

For example, to use a custom buildpack hosted at a private GitHub URL, ensure that an SSH public
key exists in your [GitHub settings][]. Then set `SSH_KEY` to the corresponding SSH private key
and set `.pack_builder` to the builder image:

    $  tee > .pack_builder << EOF
       > registry.drycc.cc/drycc/buildpacks:bookworm
       > EOF
    $ git add .buildpack
    $ git commit -m "chore(buildpack): modify the pack_builder"
    $ git push drycc master

## Builder selector

Which way to build a project conforms to the following principles:

- If Dockerfile exists in the project, the stack uses `container`
- If Procfile exists in the project, the stack uses `buildpack`
- If both exist, `container` is used by default
- You can also set the `DRYCC_STACK` to `container` or `buildpack` determine which stack to use.


[pods]: http://kubernetes.io/v1.1/docs/user-guide/pods.html
[controller]: ../understanding-workflow/components.md#controller
[builder]: ../understanding-workflow/components.md#builder
[Go Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/go
[Java Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/java
[Nodejs Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/nodejs
[PHP Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/php
[Python Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/python
[Ruby Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/ruby
[Rust Buildpack]: https://github.com/drycc/pack-images/tree/main/buildpacks/rust
[Cloud Native Buildpacks]: https://buildpacks.io/
[GitHub settings]: https://github.com/settings/ssh
