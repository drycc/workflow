# Installing Drycc Workflow

This document is aimed at those who have already provisioned a [Kubernetes v1.16.15+][] cluster
and want to install Drycc Workflow. If help is required getting started with Kubernetes and
Drycc Workflow, follow the [quickstart guide](../quickstart/index.md) for assistance.

## Prerequisites

1. Verify the [Kubernetes system requirements](system-requirements.md)
1. Install [Helm and Drycc Workflow CLI](../quickstart/install-cli-tools.md) tools

## Check Your Setup

Check that the `helm` command is available and the version is v2.5.0 or newer.

```
$ helm version
Client: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
```

## Choose Your Deployment Strategy

Drycc Workflow includes everything it needs to run out of the box. However, these defaults are aimed at simplicity rather than
production readiness. Production and staging deployments of Workflow should, at a minimum, use off-cluster storage
which is used by Workflow components to store and backup critical data. Should an operator need to completely re-install
Workflow, the required components can recover from off-cluster storage. See the documentation for [configuring object
storage](configuring-object-storage.md) for more details.

More rigorous installations would benefit from using outside sources for the following things:
* [Postgres](configuring-postgres.md) - For example AWS RDS.
* [Registry](configuring-registry.md) - This includes [quay.io](https://quay.io), [dockerhub](https://hub.docker.com), [Amazon ECR](https://aws.amazon.com/ecr/), and [Google GCR](https://cloud.google.com/container-registry/).
* [Redis](../managing-workflow/platform-logging.md#configuring-off-cluster-redis) - Such as AWS Elasticache
* [InfluxDB](../managing-workflow/platform-monitoring.md#configuring-off-cluster-influxdb) and [Grafana](../managing-workflow/platform-monitoring.md#off-cluster-grafana)

#### Ingress

Now, workflow requires that ingress and cert-manager must be installed. Any compatible Kubernetes entry controller can be used, but only ingress-nginx and ingress-traefik currently support enforced HTTPS and allowlist. Enable entries in accordance with [this guide](./ingress.md).

## Add the Drycc Chart Repository

The Drycc Chart Repository contains everything needed to install Drycc Workflow onto a Kubernetes cluster, with a single `helm install drycc/workflow --namespace drycc --set global.platform_domain=yourdomain.com` command.

Add this repository to Helm:

```
$ helm repo add drycc https://charts.drycc.cc/stable
```

## Install Drycc Workflow

If the version of helm is 3.0 +; you need to create the namespace in advance:

```
kubectl create ns drycc
```

Now that Helm is installed and the repository has been added, install Workflow by running:

```
$ helm install --namespace drycc \
    --set global.platform_domain=drycc.cc \
    drycc/workflow
```

By default, registry uses docker hub, at present, we support three registries. They are:

* redhat quay `quay.io`
* docker hub `docker.io`
* aliyun cr `registry.cn-hangzhou.aliyuncs.com`

If you want to change it, set the variable when using helm.

```
$ helm install --namespace drycc \
    --set builder.image_registry=quay.io \
    --set slugbuilder.image_registry=quay.io \
    --set imagebuilder.image_registry=quay.io \
    --set controller.image_registry=quay.io \
    --set slugrunner.image_registry=quay.io \
    --set database.image_registry=quay.io \
    --set fluentd.image_registry=quay.io \
    --set redis.image_registry=quay.io \
    --set influxdb.image_registry=quay.io \
    --set rabbitmq.image_registry=quay.io \
    --set logger.image_registry=quay.io \
    --set minio.image_registry=quay.io \
    --set monitor.image_registry=quay.io \
    --set nsqd.image_registry=quay.io \
    --set registry.image_registry=quay.io \
    --set registry-proxy.image_registry=quay.io \
    --set global.platform_domain=drycc.cc \
    drycc/workflow
```

Helm will install a variety of Kubernetes resources in the `drycc` namespace.
Wait for the pods that Helm launched to be ready. Monitor their status by running:

```
$ kubectl --namespace=drycc get pods
```

If it's preferred to have `kubectl` automatically update as the pod states change, run (type Ctrl-C to stop the watch):

```
$ kubectl --namespace=drycc get pods -w
```

Depending on the order in which the Workflow components initialize, some pods may restart. This is common during the
installation: if a component's dependencies are not yet available, that component will exit and Kubernetes will
automatically restart it.

Here, it can be seen that the controller, builder and registry all took a few loops before they were able to start:

```
$ kubectl --namespace=drycc get pods
NAME                                     READY     STATUS    RESTARTS   AGE
drycc-builder-574483744-l15zj             1/1       Running   0          4m
drycc-controller-3953262871-pncgq         1/1       Running   2          4m
drycc-controller-celery-cmxxn             3/3       Running   0          4m
drycc-database-83844344-47ld6             1/1       Running   0          4m
drycc-influxdb-2729788615-m9b5n           1/1       Running   0          4m
drycc-logger-176328999-wjckx              1/1       Running   4          4m
drycc-logger-fluentd-zxnqb                1/1       Running   0          4m
drycc-redis-304849759-1f35p               1/1       Running   0          4m
drycc-minio-676004970-nxqgt               1/1       Running   0          4m
drycc-monitor-grafana-432627134-lnl2h     1/1       Running   0          4m
drycc-monitor-telegraf-wmcmn              1/1       Running   1          4m
drycc-nsqd-3597503299-6mn2x               1/1       Running   0          4m
drycc-registry-756475849-lwc6b            1/1       Running   1          4m
drycc-registry-proxy-96c4p                1/1       Running   0          4m
drycc-rabbitmq-0                          1/1       Running   0          4m
```

Once all of the pods are in the `READY` state, Drycc Workflow is up and running!

For more installation parameters, please check the [values.yaml](https://github.com/drycc/workflow/blob/main/charts/workflow/values.yaml) file of workflow.

After installing Workflow, [register a user and deploy an application](../quickstart/deploy-an-app.md).

[Kubernetes v1.16.15+]: system-requirements.md#kubernetes-versions

## Configure DNS

User must to set up a hostname, and assumes the `drycc-builder.$host` convention.

We need to point the `drycc-builder.$host` record to the public IP address of your builder. You can get the public IP using the following command. A wildcard entry is necessary here as apps will use the same rule after they are deployed.

```
$ kubectl get svc drycc-builder --namespace drycc
NAME              CLUSTER-IP   EXTERNAL-IP      PORT(S)                      AGE
drycc-builder     10.0.25.3    138.91.243.152   2222:31625/TCP               33m
```


If we were using `drycc.cc` as a hostname, we would need to create the following A DNS records.

| Name                         | Type          | Value          |
| ---------------------------- |:-------------:| --------------:|
| drycc-builder.drycc.cc       | A             | 138.91.243.152 |

Once all of the pods are in the `READY` state, and `drycc-builder.$host` resolves to the external IP found above, Workflow is up and running!

After installing Workflow, [register a user and deploy an application](../quickstart/deploy-an-app.md).

If your k8s does not provide public network loadblance, you need to install TCP proxy services such as haproxy on machines that can 
access both internal and external networks, and then expose `80` and `443`.