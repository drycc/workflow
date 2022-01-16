# Drycc workflow

**Drycc Workflow** is an open source Platform as a Service (PaaS) that adds a developer-friendly layer to any [Kubernetes][k8s-home] cluster, making it easy to deploy and manage applications.

To **get started** with **Drycc Workflow** please read the [Quick Start Guide](https://drycc.cc/quickstart/).

Visit [https://drycc.cc](https://drycc.cc) for more information on [why you should use Drycc Workflow](https://drycc.cc/understanding-workflow/concepts/) or [learn about its features](https://drycc.cc/understanding-workflow/architecture/).

This repository contains the source code for Drycc Workflow documentation. If you're looking for individual components, they live in their own repositories.

Please see below for links and descriptions of each component:

- [passport](https://github.com/drycc/passport) - Workflow single sign on system
- [controller](https://github.com/drycc/controller) - Workflow API server
- [builder](https://github.com/drycc/builder) - Git server and source-to-image component
- [imagebuilder](https://github.com/drycc/imagebuilder) - The builder for [Docker](https://www.docker.com/) and [CNCF Buildpacks](https://buildpacks.io/) based applications
- [fluentd](https://github.com/drycc/fluentd) - Backend log shipping mechanism for `drycc logs`
- [postgres](https://github.com/drycc/postgres) - The central database
- [registry](https://github.com/drycc/registry) - The Docker registry
- [logger](https://github.com/drycc/logger) - The (in-memory) log buffer for `drycc logs`
- [monitor](https://github.com/drycc/monitor) - The platform monitoring components
- [influxdb](https://github.com/drycc/influxdb) - The monitor database
- [rabbitmq](https://github.com/drycc/rabbitmq) - RabbitMQ is a message broker used with controller celery
- [minio](https://github.com/drycc/minio) - The in-cluster, ephemeral, development-only object storage system
- [workflow-cli](https://github.com/drycc/workflow-cli) - Workflow CLI `drycc`

We welcome your input! If you have feedback, please [submit an issue][issues]. If you'd like to participate in development, please read the "Working on Documentation" section below and [submit a pull request][prs].

# Working on Documentation
[![Build Status](https://drone.drycc.cc/api/badges/drycc/workflow/status.svg)](https://drone.drycc.cc/drycc/workflow)

The Drycc project welcomes contributions from all developers. The high level process for development matches many other open source projects. See below for an outline.

* Fork this repository.
* Make your changes.
* [Submit a pull request][prs] (PR) to this repository with your changes, and unit tests whenever possible.
    * If your PR fixes any [issues][issues], make sure you write `Fixes #1234` in your PR description (where `#1234` is the number of the issue you're closing).
* The Drycc core contributors will review your code. After each of them sign off on your code, they'll label your PR with `LGTM1` and `LGTM2` (respectively). Once that happens, a contributor will merge it.

## Requirements

The documentation site requires either a local installation of [MkDocs][] or access to Docker.

### Local Installation

Install [MkDocs][] and required dependencies:

```
make deps
```

## Building Documentation

To build the documentation run: `make build` or `make docker-build`.

## Serve Documentation Locally

To serve documenation run: `make serve` or `make docker-serve`.

Then view the documentation on [http://localhost:8000](http://localhost:8000) or `http://DOCKER_IP:8000`.

[k8s-home]: http://kubernetes.io
[install-k8s]: http://kubernetes.io/gettingstarted/
[mkdocs]: http://www.mkdocs.org/
[issues]: https://github.com/drycc/workflow/issues
[prs]: https://github.com/drycc/workflow/pulls
[Drycc website]: http://drycc.cc/
