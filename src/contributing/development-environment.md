# Development Environment

This document is for developers who are interested in working directly on the Drycc codebase. In this guide, we walk you through the process of setting up a development environment that is suitable for hacking on most Drycc components.

We try to make it simple to hack on Drycc components. However, there are necessarily several moving pieces and some setup required. We welcome any suggestions for automating or simplifying this process.

!!! note
    The Drycc team is actively engaged in containerizing Go and Python based development environments tailored specifically for Drycc development in order to minimize the setup required.  This work is ongoing.  Refer to the [drycc/router][router] project for a working example of a fully containerized development environment.

If you're just getting into the Drycc codebase, look for GitHub issues with the label [easy-fix][]. These are more straightforward or low-risk issues and are a great way to become more familiar with Drycc.

## Prerequisites

In order to successfully compile and test Drycc binaries and build Container images of Drycc components, the following are required:

- [git][git]
- Go 1.5 or later, with support for compiling to `linux/amd64`
- [glide][glide]
- [golint][golint]
- [shellcheck][shellcheck]
- [Podman][podman] (in a non-Linux environment, you will additionally want [Podman Machine][machine])

For [drycc/controller][controller], in particular, you will also need:

- Python 2.7 or later (with `pip`)
- virtualenv (`sudo pip install virtualenv`)

In most cases, you should simply install according to the instructions. There are a few special cases, though. We cover these below.

### Configuring Go

If your local workstation does not support the `linux/amd64` target environment, you will have to install Go from source with cross-compile support for that environment. This is because some of the components are built on your local machine and then injected into a container.

Homebrew users can just install with cross compiling support:

```
$ brew install go --with-cc-common
```

It is also straightforward to build Go from source:

```
$ sudo su
$ curl -sSL https://golang.org/dl/go1.5.src.tar.gz | tar -v -C /usr/local -xz
$ cd /usr/local/go/src
$ # compile Go for our default platform first, then add cross-compile support
$ ./make.bash --no-clean
$ GOOS=linux GOARCH=amd64 ./make.bash --no-clean
```

Once you can compile to `linux/amd64`, you should be able to compile Drycc components as normal.

## Fork the Repository

Once the prerequisites have been met, we can begin to work with Drycc components.

Begin at Github by forking whichever Drycc project you would like to contribute to, then clone that fork locally.  Since Drycc is predominantly written in Go, the best place to put it is under `$GOPATH/src/github.com/drycc/`.

```
$ mkdir -p  $GOPATH/src/github.com/drycc
$ cd $GOPATH/src/github.com/drycc
$ git clone git@github.com:<username>/<component>.git
$ cd <component>
```

!!! note
    By checking out the forked copy into the namespace `github.com/drycc/<component>`, we are tricking the Go toolchain into seeing our fork as the "official" source tree.

If you are going to be issuing pull requests to the upstream repository from which you forked, we suggest configuring Git such that you can easily rebase your code to the upstream repository's main branch. There are various strategies for doing this, but the [most common](https://help.github.com/articles/fork-a-repo/) is to add an `upstream` remote:

```
$ git remote add upstream https://github.com/drycc/<component>.git
```

For the sake of simplicity, you may want to point an environment variable to your Drycc code - the directory containing one or more Drycc components:

```
$ export DRYCC=$GOPATH/src/github.com/drycc
```

Throughout the rest of this document, `$DRYCC` refers to that location.

### Alternative: Forking with a Pushurl

A number of Drycc contributors prefer to pull directly from `drycc/<component>`, but push to `<username>/<component>`. If that workflow suits you better, you can set it up this way:

```
$ git clone git@github.com:drycc/<component>.git
$ cd drycc
$ git config remote.origin.pushurl git@github.com:<username>/<component>.git
```

In this setup, fetching and pulling code will work directly with the upstream repository, while pushing code will send changes to your fork. This makes it easy to stay up to date, but also make changes and then issue pull requests.

## Make Your Changes

With your development environment set up and the code you wish to work on forked and cloned, you can begin making your changes.

## Test Your Changes

Drycc components each include a comprehensive suite of automated tests, mostly written in Go. See [testing][] for instructions on running the tests.

## Deploying Your Changes

Although writing and executing tests are critical to ensuring code quality, most contributors will also want to deploy their changes to a live environment, whether to make use of those changes or to test them further.  The remainder of this section documents the procedure for running officially released Drycc components in a development cluster and replacing any one of those with your customizations.

### Running a Kubernetes Cluster for Development

To run a Kubernetes cluster locally or elsewhere to support your development activities, refer to Drycc installation instructions [here](../quickstart/index.md).

### Using a Development Registry

To facilitate deploying Container images containing your changes to your Kubernetes cluster, you will need to make use of a Container registry.  This is a location to where you can push your custom-built images and from where your Kubernetes cluster can retrieve those same images.

If your development cluster runs locally (in Minikube, for instance), the most efficient and economical means of achieving this is to run a Container registry locally _as_ a Container container.

To facilitate this, most Drycc components provide a make target to create such a registry:

```
$ make dev-registry
```

In a Linux environment, to begin using the registry:

```
export DRYCC_REGISTRY=<IP of the host machine>:5000
```

In non-Linux environments:

```
export DRYCC_REGISTRY=<IP of the drycc Container Machine VM>:5000
```

If your development cluster runs on a cloud provider such as Google Container Engine, a local registry such as the one above will not be accessible to your Kubernetes nodes.  In such cases, a public registry such as [DockerHub][dh] or [quay.io][quay] will suffice.

To use DockerHub for this purpose, for instance:

```
$ export DRYCC_REGISTRY="registry.drycc.cc"
$ export IMAGE_PREFIX=<your DockerHub username>
```

To use quay.io:

```
$ export DRYCC_REGISTRY=quay.io
$ export IMAGE_PREFIX=<your quay.io username>
```

Note the importance of the trailing slash.

### Dev / Deployment Workflow

With a functioning Kubernetes cluster and the officially released Drycc components installed onto it, deployment and further testing of any Drycc component you have made changes to is facilitated by replacing the officially released component with a custom built image that contains your changes.  Most Drycc components include Makefiles with targets specifically intended to facilitate this workflow with minimal friction.

In the general case, this workflow looks like this:

1. Update source code and commit your changes using `git`
2. Use `make build` to build a new Container image
3. Use `make dev-release` to generate Kubernetes manifest(s)
4. Use `make deploy` to restart the component using the updated manifest

This can be shortened to a one-liner using just the `deploy` target:

```
$ make deploy
```

## Useful Commands

Once your customized Drycc component has been deployed, here are some helpful commands that will allow you to inspect your cluster and to troubleshoot, if necessary:

### See All Drycc Pods

```
$ kubectl --namespace=drycc get pods
```

### Describe a Pod

This is often useful for troubleshooting pods that are in pending or crashed states:

```
$ kubectl --namespace=drycc describe -f <pod name>
```

### Tail Logs

```
$ kubectl --namespace=drycc logs -f <pod name>
```

### Django Shell

Specific to [drycc/controller][controller]

```
$ kubectl --namespace=drycc exec -it <pod name> -- python manage.py shell
```

Have commands other Drycc contributors might find useful? Send us a PR!

## Pull Requests

Satisfied with your changes?  Share them!

Please read [Submitting a Pull Request](submitting-a-pull-request.md). It contains a checklist of
things you should do when proposing a change to any Drycc component.

[router]: https://github.com/drycc/router
[easy-fix]: https://github.com/issues?q=user%3Adrycc+label%3Aeasy-fix+is%3Aopen
[git]: https://git-scm.com/
[glide]: https://github.com/Masterminds/glide
[golint]: https://github.com/golang/lint
[shellcheck]: https://github.com/koalaman/shellcheck
[podman]: https://podman.io/
[controller]: https://github.com/drycc/controller
[vbox]: https://www.virtualbox.org/
[testing]: testing.md
[k8s]: http://kubernetes.io/
[k8s-getting-started]: http://kubernetes.io/gettingstarted/
[pr]: submitting-a-pull-request.md
[quay]: https://quay.io/
