# Components

Workflow is comprised of a number of small, independent services that combine
to create a distributed PaaS. All Workflow components are deployed as services
(and associated controllers) in your Kubernetes cluster. If you are interested
we have a more detailed exploration of the [Workflow
architecture][architecture].

All of the componentry for Workflow is built with composability in mind. If you
need to customize one of the components for your specific deployment or need
the functionality in your own project we invite you to give it a shot!

## Controller

**Project Location:** [drycc/controller](https://github.com/drycc/controller)

The controller component is an HTTP API server which serves as the endpoint for
the `drycc` CLI. The controller provides all of the platform functionality as
well as interfacing with your Kubernetes cluster. The controller persists all
of its data to the database component.

## Passport

**Project Location:** [drycc/passport](https://github.com/drycc/passport)

The passport component exposes a web API and provide OAuth2 authentication.

## Database

**Project Location:** [drycc/postgres](https://github.com/drycc/postgres)

The database component is a managed instance of [PostgreSQL][] which holds a
majority of the platforms state. Backups and WAL files are pushed to object
storage via [WAL-E][]. When the database is restarted, backups are fetched and
replayed from object storage so no data is lost.

## Builder

**Project Location:** [drycc/builder](https://github.com/drycc/builder)


The builder component is responsible for accepting code pushes via [Git][] and
managing the build process of your [Application][]. The builder process is:

1. Receives incoming `git push` requests over SSH
2. Authenticates the user via SSH key fingerprint
3. Authorizes the user's access to push code to the Application
4. Starts the Application Build phase (see below)
5. Triggers a new [Release][] via the Controller

Builder currently supports both buildpack and Dockerfile based builds.

**Project Location:** [drycc/imagebuilder](https://github.com/drycc/imagebuilder)

For Buildpack-based deploys, the builder component will launch a one-shot Job
in the `drycc` namespace. This job runs `imagebuilder` component which handles
default and custom buildpacks (specified by `.packbuilder`). The completed image
is pushed to the managed Docker registry on cluster. For more information
about buildpacks see [using buildpacks][using-buildpacks].

Unlike buildpack-based, For Applications which contain a `Dockerfile` in the root
of the repository, it generates a Docker image (using the underlying Docker engine).
For more information see [using Dockerfiles][using-dockerfiles].

## Object Storage

**Project Location:** [drycc/minio](https://github.com/drycc/minio)

All of the Workflow components that need to persist data will ship them to the
object storage that was configured for the cluster.For example, database ships
its WAL files, registry stores Docker images, and slugbuilder stores slugs.

Workflow supports either on or off-cluster storage. For production deployments
we highly recommend that you configure [off-cluster object storage][configure-objectstorage].

To facilitate experimentation, development and test environments, the default charts for
Workflow include on-cluster object storage via [minio](https://github.com/minio/minio).

If you also feel comfortable using Kubernetes persistent volumes you may
configure minio to use persistent storage available in your environment.

## Registry

**Project Location:** [drycc/registry](https://github.com/drycc/registry)

The registry component is a managed docker registry which holds application
images generated from the builder component. Registry persists the Docker image
images to either local storage (in development mode) or to object storage
configured for the cluster.

## Logger: fluentd, logger

The logging subsystem consists of two components. Fluentd handles log shipping
and logger maintains a ring-buffer of application logs.


**Project Location:** [drycc/fluentd](https://github.com/drycc/fluentd)

Fluentd is deployed to your Kubernetes cluster via Daemon Sets. Fluentd
subscribes to all container logs, decorates the output with Kubernetes metadata
and can be configured to drain logs to multiple destinations. By default,
fluentd ships logs to the logger component, which powers `drycc logs`.

**Project Location:** [drycc/logger](https://github.com/drycc/logger)

The `logger` component receives log streams from `fluentd`, collating by
Application name. Logger does not persist logs to disk, instead maintaining an
in-memory ring buffer. For more information on logger see the [project
documentation][logger-documentation].

## Monitor

**Project Location:** [drycc/monitor](https://github.com/drycc/monitor)

The monitoring subsystem consists of two components: Telegraf and Grafana.

Telegraf is the is the metrics collection agent that runs using the daemon set API. It runs on
every worker node in the cluster, fetches information about the pods currently running and ships it
to InfluxDB.

Grafana is a standalone graphing application. It natively supports InfluxDB as a datasource and
provides a robust engine for creating dashboards on top of timeseries data. Workflow provides a few
dashboards out of the box for monitoring Drycc Workflow and Kubernetes. The dashboards can be used
as a starting point for creating more custom dashboards to suit a user's needs.

## InfluxDB

**Project Location:** [drycc/influxdb](https://github.com/drycc/influxdb)

InfluxDB is a database that stores the metrics collected by Telegraf. Out of the box, it does not
persist to disk, but you can set it up to back it with a persisitent volume or swap this out with
a more robust InfluxDB setup in a production setting.

## Rabbitmq

**Project Location:** [drycc/rabbitmq](https://github.com/drycc/rabbitmq)

RabbitMQ is the most widely deployed open source message broker.
Controller use celery with rabbitMQ to execute the asynchronous task.

## HelmBroker

**Project Location:** [drycc/rabbitmq](https://github.com/drycc/helmbroker)

Helm Broker is a Service Broker that exposes Helm charts as Service Classes in Service Catalog.
To do so, Helm Broker uses the concept of addons. An addon is an abstraction layer over a Helm chart
which provides all information required to convert the chart into a Service Class.

## See Also

* [Workflow Concepts][concepts]
* [Workflow Architecture][architecture]

[Application]: ../reference-guide/terms.md#application
[Config]: ../reference-guide/terms.md#config
[Git]: http://git-scm.com/
[Nginx]: http://nginx.org/
[PostgreSQL]: http://www.postgresql.org/
[WAL-E]: https://github.com/wal-e/wal-e
[architecture]: architecture.md
[concepts]: concepts.md
[configure-objectstorage]: ../installing-workflow/configuring-object-storage.md
[logger-documentation]: https://github.com/drycc/logger
[release]: ../reference-guide/terms.md#release
[using-buildpacks]: ../applications/using-buildpacks.md
[using-dockerfiles]: ../applications/using-dockerfiles.md
