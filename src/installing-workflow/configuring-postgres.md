# Configuring Postgres

Drycc Workflow's controller and passport component rely on a PostgreSQL database to store platform state.

By default, Drycc Workflow ships with the [database] component, which provides an in-cluster PostgreSQL database backed up to in-cluster or off-cluster [object storage]. Currently, for object storage, which is utilized by _several_ Workflow components, only off-cluster solutions such as S3 or GCS are recommended in production environments. Experience has shown that many operators already opting for off-cluster object storage similarly prefer to host Postgres off-cluster as well, using Amazon RDS or similar. When excercising both options, a Workflow installation becomes entirely stateless, and is thus restored or rebuilt with greater ease should the need ever arise.

## Provisioning off-cluster Postgres

First, provision a PostgreSQL RDBMS using the cloud provider or other infrastructure of your choice. Take care to ensure that security groups or other firewall rules will permit connectivity from your Kubernetes worker nodes, any of which may play host to the Workflow controller component.

Take note of the following:

1. The hostname or public IP of your PostgreSQL RDBMS
2. The port on which your PostgreSQL RDBMS runs-- typically 5432

Within the off-cluster RDBMS, manually provision the following:

1. A database user (take note of the username and password)
2. A database owned by that user (take note of its name)

If you are able to log into the RDBMS as a superuser or a user with appropriate permissions, this process will _typically_ look like this:

```
$ psql -h <host> -p <port> -d postgres -U <"postgres" or your own username>
> create user <drycc username; typically "drycc"> with password '<password>';
> create database <database name; typically "drycc"> with owner <drycc username>;
> \q
```

## Configuring Workflow

The Helm chart for Drycc Workflow can be easily configured to connect the Workflow controller component to an off-cluster PostgreSQL database.

* **Step 1:** If you haven't already fetched the values, do so with `helm inspect values drycc/workflow > values.yaml`
* **Step 2:** Update database connection details by modifying `values.yaml`:
    * Update the `databaseLocation` parameter to `off-cluster`.
    * Update the values in the `[database]` configuration section to properly reflect all connection details.
    * Update the values in the `[controller]` configuration section to properly reflect platformDomain details.
    * Save your changes.
    * Note: you do not need to (and must not) base64 encode any values, as the Helm chart will automatically handle encoding as necessary.

You are now ready to `helm install drycc oci://registry.drycc.cc/charts/workflow --namespace drycc -f values.yaml` [as usual][installing].

[database]: ../understanding-workflow/components.md#database
[object storage]: configuring-object-storage.md
[installing]: ../installing-workflow/index.md
