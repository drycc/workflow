## Check Your Setup

First check that the `helm` command is available and the version is v2.5.0 or newer.

```
$ helm version
Client: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.5.0", GitCommit:"012cb0ac1a1b2f888144ef5a67b8dab6c2d45be6", GitTreeState:"clean"}
```

Ensure the `kubectl` client is installed and can connect to your Kubernetes cluster.

## Add the Drycc Chart Repository

The Drycc Chart Repository contains everything needed to install Drycc Workflow onto a Kubernetes cluster, with a single `helm install drycc/workflow --namespace drycc` command.

Add this repository to Helm:

```
$ helm repo add drycc https://charts.drycc.cc/stable
```

## Install Drycc Workflow

Now that Helm is installed and the repository has been added, install Workflow by running:

```
$ helm install drycc/workflow --namespace drycc
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
NAME                          READY     STATUS    RESTARTS   AGE
drycc-builder-hy3xv            1/1       Running   5          5m
drycc-controller-g3cu8         1/1       Running   5          5m
drycc-database-rad1o           1/1       Running   0          5m
drycc-logger-fluentd-1v8uk     1/1       Running   0          5m
drycc-logger-fluentd-esm60     1/1       Running   0          5m
drycc-logger-sm8b3             1/1       Running   0          5m
drycc-minio-4ww3t              1/1       Running   0          5m
drycc-registry-asozo           1/1       Running   1          5m
drycc-workflow-manager-68nu6   1/1       Running   0          5m
```

Once all of the pods are in the `READY` state, Drycc Workflow is up and running!
