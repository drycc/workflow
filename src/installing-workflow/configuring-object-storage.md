# Configuring Object Storage

A variety of Drycc Workflow components rely on an object storage system to do their work including storing application slugs, Docker images and database logs.

Drycc Workflow ships with [Storage][storage] by default, which provides in-cluster.

## Configuring off-cluster Object Storage

Every component that relies on object storage uses two inputs for configuration:

1. You must use object storage services that are compatible with S3 API
2. Access credentials stored as a Kubernetes secret named `storage-creds`

The helm chart for Drycc Workflow can be easily configured to connect Workflow components to off-cluster object storage. Drycc Workflow currently supports Google Compute Storage, Amazon S3, [Azure Blob Storage][] and OpenStack Swift Storage.

### Step 1: Create storage buckets

Create storage buckets for each of the Workflow subsystems: `builder`, `registry`, and `database`.

Depending on your chosen object storage you may need to provide globally unique bucket names. If you are using S3, use hyphens instead of periods in the bucket names. Using periods in the bucket name will cause an [ssl certificate validation issue with S3](https://forums.aws.amazon.com/thread.jspa?threadID=105357).

If you provide credentials with sufficient access to the underlying storage, Workflow components will create the buckets if they do not exist.

### Step 2: Generate storage credentials

If applicable, generate credentials that have create and write access to the storage buckets created in Step 1.

If you are using AWS S3 and your Kubernetes nodes are configured with appropriate [IAM][aws-iam] API keys via InstanceRoles, you do not need to create API credentials. Do, however, validate that the InstanceRole has appropriate permissions to the configured buckets!

### Step 3: Add Drycc Repo

If you haven't already added the Helm repo, do so with `helm repo add drycc https://charts.drycc.cc/stable`

### Step 4: Configure Workflow Chart

Operators should configure object storage by editing the Helm values file before running `helm install`. To do so:

* Fetch the Helm values by running `helm inspect values drycc/workflow > values.yaml`
* Update the `global/storage` parameter to reference the platform you are using, e.g. `s3`, `azure`, `gcs`, or `swift`
* Find the corresponding section for your storage type and provide appropriate values including region, bucket names, and access credentials.
* Save your changes.

!!! note
	All values will be automatically (base64) encoded _except_ the `key_json` values under `gcs`/`gcr`.  These must be base64-encoded.  This is to support cleanly passing said encoded text via `helm --set` cli functionality rather than attempting to pass the raw JSON data.  For example:

		$ helm install workflow --namespace drycc \
			--set global.platformDomain=youdomain.com
			--set global.storage=gcs,gcs.key_json="$(cat /path/to/gcs_creds.json | base64 -w 0)"

You are now ready to run `helm install drycc/workflow --namespace drycc -f values.yaml` using your desired object storage.


[storage]: ../understanding-workflow/components.md#object-storage
[aws-iam]: http://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
[Azure Blob Storage]: https://azure.microsoft.com/en-us/services/storage/blobs/
