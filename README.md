# Drycc workflow
[![Build Status](https://woodpecker.drycc.cc/api/badges/drycc/workflow/status.svg)](https://woodpecker.drycc.cc/drycc/workflow)

**Drycc Workflow** is an open source Container as a Service (CaaS) that adds a developer-friendly layer to any [Kubernetes](http://kubernetes.io) cluster, making it easy to deploy and manage applications.

To **get started** with **Drycc Workflow** please read the [Quick Start Guide](https://www.drycc.cc/docs/quickstart/).

Visit [https://www.drycc.cc](https://www.drycc.cc) for more information on [why you should use Drycc Workflow](https://www.drycc.cc/docs/understanding-workflow/concepts/) or [learn about its features](https://www.drycc.cc/docs/understanding-workflow/architecture/).

This repository contains the source code for Drycc Workflow documentation. If you're looking for individual components, they live in their own repositories.

Please see below for links and descriptions of each component:

- [gateway](https://github.com/drycc/gateway) - Workflow gateway charts
- [passport](https://github.com/drycc/passport) - Workflow single sign on system
- [controller](https://github.com/drycc/controller) - Workflow API server
- [builder](https://github.com/drycc/builder) - Git server and source-to-image component
- [imagebuilder](https://github.com/drycc/imagebuilder) - The builder for Container Image and [CNCF Buildpacks](https://buildpacks.io/) based applications
- [fluentbit](https://github.com/drycc/fluentbit) - Backend log shipping mechanism for `drycc logs`
- [postgres](https://github.com/drycc/postgres) - The central database
- [registry](https://github.com/drycc/registry) - The Container registry
- [logger](https://github.com/drycc/logger) - The (in-memory) log buffer for `drycc logs`
- [monitor](https://github.com/drycc/monitor) - The platform monitoring components
- [prometheus](https://github.com/drycc/prometheus) - The monitor database
- [rabbitmq](https://github.com/drycc/rabbitmq) - RabbitMQ is a message broker used with controller celery
- [storage](https://github.com/drycc/storage) - The in-cluster, kubernetes storage, s3 api compatible, hybrid storage system.
- [workflow-cli](https://github.com/drycc/workflow-cli) - Workflow CLI `drycc`

We welcome your input! If you have feedback, please [submit an issue](https://github.com/drycc/workflow/issues). 
If you'd like to participate in development, please [submit a pull request](https://github.com/drycc/workflow/pulls).
