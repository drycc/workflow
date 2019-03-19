# Experimental Native Ingress

## Install Drycc Workflow (With experimental native ingress support)

Now that Helm is installed and the repository has been added, install Workflow with a native ingress by running:

```
$ helm install drycc/workflow --namespace drycc --set global.use_native_ingress=true,controller.platform_domain=drycc.cc
```

Where `controller.platform_domain` is a **required** parameter that is traditionally not required for Workflow that is explained in the next section. In this example we are using `drycc.cc` for `$hostname`.
 
Helm will install a variety of Kubernetes resources in the `drycc` namespace.
Wait for the pods that Helm launched to be ready. Monitor their status by running:

```
$ kubectl --namespace=drycc get pods
```

You should also notice that several Kubernetes ingresses has been installed on your cluster. You can view it by running:

```
$ kubectl get ingress --namespace drycc
```

Depending on the order in which the Workflow components initialize, some pods may restart. This is common during the
installation: if a component's dependencies are not yet available, that component will exit and Kubernetes will
automatically restart it.

Here, it can be seen that the controller, builder and registry all took a few loops waiting for minio before they were able to start:

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

## Install a Kubernetes Ingress Controller

Now that Workflow has been deployed with the `global.use_native_ingress` flag set to `true`, we will need a Kubernetes ingress controller in place to begin routing traffic.

Here is an example of how to use [traefik](https://traefik.io/) as an ingress controller for Workflow. Of course, you are welcome to use any controller you wish.

```
$ helm install stable/traefik --name ingress --namespace kube-system
```

## Configure DNS

The experimental ingress feature requires a user to set up a hostname, and assumes the `drycc.$host` convention.

We need to point the `*.$host` record to the public IP address of your ingress controller. You can get the public IP using the following command. A wildcard entry is necessary here as apps will use the same rule after they are deployed.

```
$ kubectl get svc ingress-traefik --namespace kube-system
NAME              CLUSTER-IP   EXTERNAL-IP      PORT(S)                      AGE
ingress-traefik   10.0.25.3    138.91.243.152   80:31625/TCP,443:30871/TCP   33m
```

Additionally, we need to point the `drycc-builder.$host` record to the public IP address of the [Builder][].

```
$ kubectl get svc drycc-builder --namespace drycc
NAME           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
drycc-builder   10.0.165.140   40.86.182.187   2222:32488/TCP   33m
```

If we were using `drycc.cc` as a hostname, we would need to create the following A DNS records.

| Name                         | Type          | Value          |
| ---------------------------- |:-------------:| --------------:|
| *.drycc.cc                   | A             | 138.91.243.152 |
| drycc-builder.drycc.cc        | A             | 40.86.182.187  |

Once all of the pods are in the `READY` state, and `drycc.$host` resolves to the external IP found above, Workflow is up and running!

After installing Workflow, [register a user and deploy an application](../quickstart/deploy-an-app.md).

##### Feedback

While this feature is experimental we welcome feedback on the issue. We would like to learn more about use cases, and user experience. Please [open a new issue](https://github.com/drycc/workflow/issues/new) for feedback.


[builder]: ../understanding-workflow/components.md#builder
