# Migrating from Drycc v1

Workflow uses [`kubectl`][kubectl] and [`helm`][helm] to manage the cluster. These tools are
equivalent to Drycc v1's [`fleetctl`][fleetctl] and [`dryccctl`][dryccctl]. These two tools are used
for managing the cluster's state, installing the platform and inspecting its state.

This document is a "cheat sheet" for users migrating from Drycc v1 to Workflow (v2). It lists most of
the known commands administrators would use with `dryccctl` and translates their usage in Workflow.

## Listing all Components

```
# Drycc v1
$ dryccctl list

# Workflow
$ kubectl --namespace=drycc get deployments
```

## Listing all Nodes

```
# Drycc v1
$ fleetctl list-machines

# Workflow
$ kubectl get nodes
```

## Custom Configuration

```
# Drycc v1
$ dryccctl config controller set registrationMode=admin_only

# Workflow
$ kubectl --namespace=drycc patch deployment drycc-controller -p '{"spec":{"containers":{"env":[{"name":"REGISTRATION_MODE","value":"admin_only"}]}}}'
```

## View Component Configuration

```
# Drycc v1
$ dryccctl config router get bodySize

# Workflow
$ kubectl --namespace=drycc get deployment drycc-router -o yaml
```

## Running a Command Within a Component

```
# Drycc v1
$ dryccctl dock router@1

# Workflow
$ kubectl get po --namespace=drycc -l app=drycc-router --output="jsonpath={.items[0].metadata.name}"
drycc-router-1930478716-iz6oq
$ kubectl --namespace=drycc exec -it drycc-router-1930478716-iz6oq bash
```

## Follow the Logs for a Component

```
# Drycc v1
$ fleetctl journal -f drycc-builder

# Workflow
$ kubectl get po --namespace=drycc -l app=drycc-builder --output="jsonpath={.items[0].metadata.name}"
drycc-builder-1851090495-5n0sn
$ kubectl --namespace=drycc logs -f drycc-builder-1851090495-5n0sn
```


[dryccctl]: http://docs.drycc.cc/en/latest/installing_drycc/install-dryccctl/
[fleetctl]: https://github.com/coreos/fleet/blob/master/Documentation/using-the-client.md
[kubectl]: http://kubernetes.io/docs/user-guide/kubectl-overview/
[helm]: https://github.com/kubernetes/helm
