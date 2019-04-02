# Chart Provenance

Drycc has released [Kubernetes Helm][helm] charts for Workflow
and for each of its [components](../understanding-workflow/components.md).

Helm provides tools for establishing and verifying chart integrity.  (For an overview, see the [Provenance](https://github.com/kubernetes/helm/blob/master/docs/provenance.md) doc.)  All release charts from the Drycc Workflow team are now signed using this mechanism.

The full `Drycc, Inc. (Helm chart signing key) <security@drycc.cc>` public key can be found [here](../security/1d6a97d0.txt), as well as the [pgp.mit.edu](http://pgp.mit.edu/pks/lookup?op=vindex&fingerprint=on&search=0x17E526B51D6A97D0) keyserver and the official Drycc Keybase [account][drycc-keybase].  The key's fingerprint can be cross-checked against all of these sources.

## Verifying a signed chart

The public key mentioned above must exist in a local keyring before a signed chart can be verified.

To add it to the default `~/.gnupg/pubring.gpg` keyring, any of the following commands will work:

```
$ # via our hosted location
$ curl https://drycc.cc/workflow/docs/security/1d6a97d0.txt | gpg --import

$ # via the pgp.mit.edu keyserver
$ gpg --keyserver pgp.mit.edu --recv-keys 1D6A97D0

$ # via Keybase with account...
$ keybase follow drycc
$ keybase pgp pull

$ # via Keybase by curl
$ curl https://keybase.io/drycc/key.asc | gpg --import
```

Charts signed with this key can then be verified when fetched:

```
$ helm repo add drycc http://charts.drycc.cc/stable
"drycc" has been added to your repositories

$ helm fetch --verify drycc/workflow --version v2.17.0
Verification: &{0xc420704c80 sha256:a2a140dca075a2eabe20422f1aa5bc1ce210b18a326472d6b2708e1a93afebea workflow-v2.17.0.tgz}
```

One can then inspect the fetched `workflow-v2.17.0.tgz.prov` provenance file.

If the chart was not signed, the command above would result in:

```
Error: Failed to fetch provenance "http://charts.drycc.cc/stable/workflow/workflow-v2.17.0.tgz.prov"
```

Alternatively, the chart can also be verified at install time:

```
$ helm install --verify drycc/workflow --namespace drycc \
    --set controller.platform_domain=yourdomain.com
NAME:   exiled-mink
LAST DEPLOYED: Wed Aug  9 08:22:16 2017
NAMESPACE: drycc
STATUS: DEPLOYED
...

$ helm ls
NAME       	REVISION	UPDATED                 	STATUS  	CHART
exiled-mink	1       	Wed Aug  9 08:22:16 2017	DEPLOYED	workflow-v2.17.0
```

Having done so, one is assured of the origin and authenticity of any installed Workflow chart released by Drycc.

[helm]: https://github.com/kubernetes/helm/blob/master/docs/install.md
[drycc-keybase]: https://keybase.io/drycc
