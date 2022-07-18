# Production Deployments

When readying a Workflow deployment for production workloads, there are some additional
recommendations.


## Running Workflow without drycc storage

In production, persistent storage can be achieved by running an external object store.
For users on AWS, GCE/GKE or Azure, the convenience of Amazon S3, Google GCS or Microsoft Azure Storage
makes the prospect of running a Storage-less Workflow cluster quite reasonable. For users who have restriction
on using external object storage using swift object storage can be an option.

Running a Workflow cluster without Storage provides several advantages:

 - Removal of state from the worker nodes
 - Reduced resource usage
 - Reduced complexity and operational burden of managing Workflow

See [Configuring Object Storage][] for details on removing this operational complexity.


## Review Security Considerations

There are some additional security-related considerations when running Workflow in production.
See [Security Considerations][] for details.


## Registration is Admin-Only

By default, registration with the Workflow controller is in "admin_only" mode. The first user
to run a `drycc register` command becomes the initial "admin" user, and registrations after that
are disallowed unless requested by an admin.

Please see the following documentation to learn about changing registration mode:

 - [Customizing Controller][]

## Disable Grafana Signups

It is also recommended to disable signups for the Grafana dashboards.

Please see the following documentation to learn about disabling Grafana signups:

 - [Customizing Monitor][]

## Running Workflow with RBAC

If your cluster has [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) amongst your [authorization](https://kubernetes.io/docs/admin/authorization/) modes (`$ kubectl api-versions` should contains `rbac.authorization.k8s.io`) it may be necessary to enable RBAC in Workflow.
This can be achieved by setting `use_rbac` in the `global` section of `values.yaml` to `true`, or by adding `--set=global.use_rbac=true` to the `$ helm install/upgrade` command.
RBAC support was announced in Kubernetes-1.5 and is enabled by default if:
- your Kubernetes cluster is in GKE
- your Kubernetes cluster built with [kubeadm](https://kubernetes.io/docs/getting-started-guides/kubeadm/)

**Note**: helm may need to be given [specific permissions][helm specific permissions] under RBAC if not already done.

**Attention**: Azure ACS Kubernetes clusters are not RBAC-enabled for today due to lack in authentication strategy. Feel free to watch this [PR](https://github.com/kubernetes/kubernetes/pull/43987) for more details.

[configuring object storage]: ../installing-workflow/configuring-object-storage.md
[customizing controller]: tuning-component-settings.md#customizing-the-controller
[customizing monitor]: tuning-component-settings.md#customizing-the-monitor
[database]: ../understanding-workflow/components.md#database
[logger]: ../understanding-workflow/components.md#logger
[storage]: ../understanding-workflow/components.md#storage
[platform ssl]: platform-ssl.md
[registry]: ../understanding-workflow/components.md#registry
[helm specific permissions]: ../installing-workflow/index.md#check-your-authorization
