# Installing Drycc Workflow

This document is aimed at those who have already provisioned a [Kubernetes v1.3.4+][] cluster
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

### Check Your Authorization

If your cluster uses [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) for authorization, `helm` will need to be granted the necessary permissions to create Workflow resources.
This can be done with the following commands:

```
$ kubectl create sa tiller-deploy -n kube-system
$ kubectl create clusterrolebinding helm --clusterrole=cluster-admin --serviceaccount=kube-system:tiller-deploy
$ helm init --service-account=tiller-deploy
```

If `helm` is already installed in cluster without sufficient rights, simply add `--upgrade` to the `init` command above.

**Note**: Specific `helm` permissions haven't been sorted yet and details may change (watch `helm` [docs](https://github.com/kubernetes/helm/tree/master/docs))

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

Now, workflow requires that ingress and cert-manager must be installed. Any compatible Kubernetes entry controller can be used, but only ingress-nginx and ingress-traefik currently support enforced HTTPS and whitelist. Enable entries in accordance with [this guide] (entress.md).

## Add the Drycc Chart Repository

The Drycc Chart Repository contains everything needed to install Drycc Workflow onto a Kubernetes cluster, with a single `helm install drycc/workflow --namespace drycc --set controller.platform_domain=yourdomain.com` command.

Add this repository to Helm:

```
$ helm repo add drycc http://charts.drycc.cc/stable
```

## Install Drycc Workflow

Now that Helm is installed and the repository has been added, install Workflow by running:

```
$ helm install --namespace drycc \
    --set controller.platform_domain=drycc.cc \
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
drycc-database-83844344-47ld6             1/1       Running   0          4m
drycc-logger-176328999-wjckx              1/1       Running   4          4m
drycc-logger-fluentd-zxnqb                1/1       Running   0          4m
drycc-logger-redis-304849759-1f35p        1/1       Running   0          4m
drycc-minio-676004970-nxqgt               1/1       Running   0          4m
drycc-monitor-grafana-432627134-lnl2h     1/1       Running   0          4m
drycc-monitor-influxdb-2729788615-m9b5n   1/1       Running   0          4m
drycc-monitor-telegraf-wmcmn              1/1       Running   1          4m
drycc-nsqd-3597503299-6mn2x               1/1       Running   0          4m
drycc-registry-756475849-lwc6b            1/1       Running   1          4m
drycc-registry-proxy-96c4p                1/1       Running   0          4m
drycc-workflow-manager-2528409207-jkz2r   1/1       Running   0          4m
```

Once all of the pods are in the `READY` state, Drycc Workflow is up and running!

After installing Workflow, [register a user and deploy an application](../quickstart/deploy-an-app.md).

[Kubernetes v1.3.4+]: system-requirements.md#kubernetes-versions
[helm]: https://github.com/kubernetes/helm/blob/master/docs/install.md
