# Requirements

To run Drycc Workflow on a Kubernetes cluster, there are a few requirements to keep in mind.

## Kubernetes Versions

Drycc Workflow requires Kubernetes v1.16.15 or later.

## Components Requirements

Drycc uses ingress as a routing implementation, so you have to choose an ingress.
We recommend using [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) or [traefik-ingress](https://github.com/helm/charts/tree/master/stable/traefik), which we have adapted to whitelist and force TLS functions.

Workflow supports the use of ACME to manage automatic certificates, [cert-manager](https://github.com/helm/charts/tree/master/stable/cert-manager) is also one of the necessary components.

Workflow supports stateful apps. You can create and use them through the 'drycc volumes' command. If you want to use this feature, you must have a `StorageClass` that supports `ReadWriteMany`.
 
Workflow also supports the [OSB](https://github.com/openservicebrokerapi/servicebroker) API through the 'drycc resources' command. If you want to use this function, you need to install [service-catalog](https://svc-cat.io).

## Storage Requirements

A variety of Drycc Workflow components rely on an object storage system to do their work, including storing application
slugs, Docker images and database logs.

Drycc Workflow ships with Minio by default, which provides in-cluster, ephemeral object storage. This means that if the
Minio server crashes, all data will be lost. Therefore, Minio should be used for development or testing only.

Workflow supports Amazon Simple Storage Service (S3), Google Cloud Storage (GCS), OpenShift Swift, and Azure Blob
Storage. See [configuring object storage](configuring-object-storage) for setup instructions.

## Resource Requirements

When deploying Drycc Workflow, it's important to provision machines with adequate resources. Drycc is a highly-available
distributed system, which means that Drycc components and your deployed applications will move around the cluster onto
healthy hosts as hosts leave the cluster for various reasons (failures, reboots, autoscalers, etc.). Because of this,
you should have ample spare resources on any machine in your cluster to withstand the additional load of running
services for failed machines.

Drycc Workflow components use about 2.5GB of memory across the cluster, and require approximately 30GB of hard disk
space. Because it may need to handle additional load if another one fails, each machine has minimum requirements of:

* At least 4GB of RAM (more is better)
* At least 40GB of hard disk space

Note that these estimates are for Drycc Workflow and Kubernetes only. Be sure to leave enough spare capacity for your
application footprint as well.

Running smaller machines will likely result in increased system load and has been known to result in component failures
and instability.

!!! warning
	Workflow versions prior to 2.2 require '--insecure-registry' to function properly. Depending on
	your Kubernetes and Docker configuration, setting
	`EXTRA_DOCKER_OPTS="--insecure-registry=10.0.0.0/8"` may be sufficient.

## SELinux + OverlayFS

If you are using Docker with OverlayFS, you must disable SELinux by adding `--selinux-enabled=false` to
`EXTRA_DOCKER_OPTS`. For more background information, see:

* [https://github.com/docker/docker/issues/7952](https://github.com/docker/docker/issues/7952)
* [https://github.com/drycc/workflow/issues/63](https://github.com/drycc/postgres/issues/63)
