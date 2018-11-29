
|![](https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Warning.svg/156px-Warning.svg.png) | Hephy Workflow is the open source fork of Deis Workflow.<br />Please [read the announcement][] for more detail. |
|---:|---|
| 11/29/2018 | Hephy Workflow [v2.20.0][] new release |
| 08/27/2018 | Team Hephy [blog][] comes online |
| 08/20/2018 | Deis [#community slack][] goes dark |
| 08/10/2018 | Hephy Workflow [v2.19.4][] fourth patch release |
| 08/08/2018 | [Deis website][] goes dark, then redirects to Azure Kubernetes Service |
| 03/16/2018 | [Hephy Workflow website][] comes online |
| 03/01/2018 | End of Deis Workflow maintenance: critical patches no longer merged |
| 12/11/2017 | Team Hephy [slack community][] invites first volunteers |
| 09/07/2017 | Deis Workflow [v2.18][] final release before entering maintenance mode |
| 09/06/2017 | Team Hephy [slack community][] comes online |

![](https://raw.githubusercontent.com/teamhephy/workflow/master/themes/deis/static/img/deis_logo.png)

[![Slack Status](https://slack.teamhephy.com/badge.svg)](https://slack.teamhephy.com/)

**Deis Workflow** is an open source Platform as a Service (PaaS) that adds a developer-friendly layer to any [Kubernetes][k8s-home] cluster, making it easy to deploy and manage applications.

Deis Workflow is the second major release (v2) of the Deis PaaS. If you are looking for the CoreOS-based PaaS visit [https://github.com/deis/deis](https://github.com/deis/deis).

To **get started** with **Deis Workflow** please read the [Quick Start Guide](https://deis.com/docs/workflow/quickstart/).

Visit [https://deis.com](https://deis.com) for more information on [why you should use Deis Workflow](https://deis.com/why-deis/) or [learn about its features](https://deis.com/how-it-works/).

This repository contains the source code for Deis Workflow documentation. If you're looking for individual components, they live in their own repositories.

Please see below for links and descriptions of each component:

- [controller](https://github.com/teamhephy/controller) - Workflow API server
- [builder](https://github.com/teamhephy/builder) - Git server and source-to-image component
- [dockerbuilder](https://github.com/teamhephy/dockerbuilder) - The builder for [Docker](https://www.docker.com/) based applications
- [slugbuilder](https://github.com/teamhephy/slugbuilder) - The builder for [slug/buildpack](https://devcenter.heroku.com/articles/slug-compiler) based applications
- [slugrunner](https://github.com/teamhephy/slugrunner) - The runner for slug/buildpack based applications
- [fluentd](https://github.com/teamhephy/fluentd) - Backend log shipping mechanism for `deis logs`
- [postgres](https://github.com/teamhephy/postgres) - The central database
- [registry](https://github.com/teamhephy/registry) - The Docker registry
- [logger](https://github.com/teamhephy/logger) - The (in-memory) log buffer for `deis logs`
- [monitor](https://github.com/teamhephy/monitor) - The platform monitoring components
- [router](https://github.com/teamhephy/router) - The HTTP/s edge router
- [minio](https://github.com/teamhephy/minio) - The in-cluster, ephemeral, development-only object storage system
- [nsq](https://github.com/teamhephy/nsq) - Realtime distributed messaging platform
- [workflow-cli](https://github.com/teamhephy/workflow-cli) - Workflow CLI `deis`
- [workflow-e2e](https://github.com/teamhephy/workflow-e2e) - End-to-end tests for the entire platform
- [workflow-manager](https://github.com/teamhephy/workflow-manager) - Manage, inspect, and debug a Workflow cluster

We welcome your input! If you have feedback, please [submit an issue][issues]. If you'd like to participate in development, please read the "Working on Documentation" section below and [submit a pull request][prs].

# Working on Documentation

[![Build Status](https://travis-ci.org/deis/workflow.svg?branch=master)](https://travis-ci.org/deis/workflow)
[![Latest Docs](http://img.shields.io/badge/docs-latest-fc1e5e.svg)](http://docs-v2.readthedocs.org/en/latest/)

The Deis project welcomes contributions from all developers. The high level process for development matches many other open source projects. See below for an outline.

* Fork this repository.
* Make your changes.
* [Submit a pull request][prs] (PR) to this repository with your changes, and unit tests whenever possible.
	* If your PR fixes any [issues][issues], make sure you write `Fixes #1234` in your PR description (where `#1234` is the number of the issue you're closing).
* The Deis core contributors will review your code. After each of them sign off on your code, they'll label your PR with `LGTM1` and `LGTM2` (respectively). Once that happens, a contributor will merge it.

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
[issues]: https://github.com/teamhephy/workflow/issues
[prs]: https://github.com/teamhephy/workflow/pulls
[Deis website]: http://deis.com/
[blog]: https://blog.teamhephy.info/blog/
[read the announcement]: https://blog.teamhephy.info/blog/posts/announcements/hephy-workflow-deis-fork.html
[#community slack]: https://slack.deis.io/
[slack community]: https://slack.teamhephy.com/
[v2.18]: https://github.com/teamhephy/workflow/releases/tag/v2.18.0
[Hephy Workflow website]: https://web.teamhephy.com
[v2.19.0]: https://gist.github.com/Cryptophobia/24c204583b18b9fc74c629fb2b62dfa3
[v2.20.0]: https://gist.github.com/Cryptophobia/667cc30f42dc38d6784212eea00bfc58
