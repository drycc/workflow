
|![](https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Warning.svg/156px-Warning.svg.png) | Drycc Workflow is the open source fork of Drycc Workflow.<br />Please [read the announcement][] for more detail. |
|---:|---|
| 11/29/2018 | Drycc Workflow [v2.20.0][] new release |
| 08/27/2018 | Team Drycc [blog][] comes online |
| 08/20/2018 | Drycc [#community slack][] goes dark |
| 08/10/2018 | Drycc Workflow [v2.19.4][] fourth patch release |
| 08/08/2018 | [Drycc website][] goes dark, then redirects to Azure Kubernetes Service |
| 03/16/2018 | [Drycc Workflow website][] comes online |
| 03/01/2018 | End of Drycc Workflow maintenance: critical patches no longer merged |
| 12/11/2017 | Team Drycc [slack community][] invites first volunteers |
| 09/07/2017 | Drycc Workflow [v2.18][] final release before entering maintenance mode |
| 09/06/2017 | Team Drycc [slack community][] comes online |

![](https://raw.githubusercontent.com/drycc/workflow/master/themes/drycc/static/img/drycc_logo.png)

[![Slack Status](https://slack.drycc.com/badge.svg)](https://slack.drycc.com/)

**Drycc Workflow** is an open source Platform as a Service (PaaS) that adds a developer-friendly layer to any [Kubernetes][k8s-home] cluster, making it easy to deploy and manage applications.

Drycc Workflow is the second major release (v2) of the Drycc PaaS. If you are looking for the CoreOS-based PaaS visit [https://github.com/drycc/drycc](https://github.com/drycc/drycc).

To **get started** with **Drycc Workflow** please read the [Quick Start Guide](https://drycc.com/docs/workflow/quickstart/).

Visit [https://drycc.com](https://drycc.com) for more information on [why you should use Drycc Workflow](https://drycc.com/why-drycc/) or [learn about its features](https://drycc.com/how-it-works/).

This repository contains the source code for Drycc Workflow documentation. If you're looking for individual components, they live in their own repositories.

Please see below for links and descriptions of each component:

- [controller](https://github.com/drycc/controller) - Workflow API server
- [builder](https://github.com/drycc/builder) - Git server and source-to-image component
- [dockerbuilder](https://github.com/drycc/dockerbuilder) - The builder for [Docker](https://www.docker.com/) based applications
- [slugbuilder](https://github.com/drycc/slugbuilder) - The builder for [slug/buildpack](https://devcenter.heroku.com/articles/slug-compiler) based applications
- [slugrunner](https://github.com/drycc/slugrunner) - The runner for slug/buildpack based applications
- [fluentd](https://github.com/drycc/fluentd) - Backend log shipping mechanism for `drycc logs`
- [postgres](https://github.com/drycc/postgres) - The central database
- [registry](https://github.com/drycc/registry) - The Docker registry
- [logger](https://github.com/drycc/logger) - The (in-memory) log buffer for `drycc logs`
- [monitor](https://github.com/drycc/monitor) - The platform monitoring components
- [router](https://github.com/drycc/router) - The HTTP/s edge router
- [minio](https://github.com/drycc/minio) - The in-cluster, ephemeral, development-only object storage system
- [nsq](https://github.com/drycc/nsq) - Realtime distributed messaging platform
- [workflow-cli](https://github.com/drycc/workflow-cli) - Workflow CLI `drycc`
- [workflow-e2e](https://github.com/drycc/workflow-e2e) - End-to-end tests for the entire platform
- [workflow-manager](https://github.com/drycc/workflow-manager) - Manage, inspect, and debug a Workflow cluster

We welcome your input! If you have feedback, please [submit an issue][issues]. If you'd like to participate in development, please read the "Working on Documentation" section below and [submit a pull request][prs].

# Working on Documentation

[![Build Status](https://travis-ci.org/drycc/workflow.svg?branch=master)](https://travis-ci.org/drycc/workflow)
[![Latest Docs](http://img.shields.io/badge/docs-latest-fc1e5e.svg)](http://docs-v2.readthedocs.org/en/latest/)

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
[Drycc website]: http://drycc.com/
[blog]: https://blog.drycc.info/blog/
[read the announcement]: https://blog.drycc.info/blog/posts/announcements/drycc-workflow-drycc-fork.html
[#community slack]: https://slack.drycc.cc/
[slack community]: https://slack.drycc.com/
[v2.18]: https://github.com/drycc/workflow/releases/tag/v2.18.0
[Drycc Workflow website]: https://web.drycc.com
[v2.19.0]: https://gist.github.com/Cryptophobia/24c204583b18b9fc74c629fb2b62dfa3
[v2.20.0]: https://gist.github.com/Cryptophobia/667cc30f42dc38d6784212eea00bfc58
