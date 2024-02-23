# Install Workflow

If you have a pure host, it can be a cloud server, bare metal server, virtual machine, or even your laptop. Then this chapter is very suitable for you.

## Operating Systems

Drycc is expected to work on most modern Linux systems. Some OSS have specific requirements:

* (Red Hat/CentOS) Enterprise Linux, they usually use RPM package management.
* Ubuntu (Desktop/Server/Cloud) Linux, a very popular distribution.
* Debian GNU Linux, a very pure distribution of opensource software.

If you want to add more Linux distribution support, please submit a issue on github or submit PR directly.

## System Software

Some basic software needs to be installed before installing drycc workflow.

### OS configuration

K8s requires a large number of ports. If you are not sure what they are, please close the local firewall or open these ports.
At the same time, because k8s you need system time, you need to ensure that the system time is correct.

### Installing NFSv4 client

The command used to install a NFSv4 client differs depending on the Linux distribution.

For Debian and Ubuntu, use this command:

```
$ apt-get install nfs-common
```

For RHEL, CentOS, and EKS with EKS Kubernetes Worker AMI with AmazonLinux2 image, use this command:

```
$ yum install nfs-utils
```

### Installing curl

For Debian and Ubuntu, use this command:

```
$ apt-get install curl
```

For RHEL, CentOS, and EKS with EKS Kubernetes Worker AMI with AmazonLinux2 image, use this command:

```
$ yum install curl
```

## Hardware

Hardware requirements scale based on the size of your deployments. Minimum recommendations are outlined here.

* RAM: 1G Minimum (we recommend at least 2GB)
* CPU: 1 Minimum

This configuration only contains the minimum requirements that can meet the operation.

## Disk

Drycc performance depends on the performance of the database. To ensure optimal speed, we recommend using an SSD when possible. Disk performance will vary on ARM devices utilizing an SD card or eMMC.

## Domain Name

Drycc needs a root domain name under your full control and points this domain name to the server to be installed.
Suppose there is a wildcard domain pointing to the current server to install drycc, which is the name `*.dryccdoman.com`.
We need to set the `PLATFORM_DOMAIN` environment variables before installation.

```
$ export PLATFORM_DOMAIN=dryccdoman.co
```

Of course, if it is a test environment, we can also use `nip.io`, an IP to domain name service.
For example, your host IP is `59.46.3.190`, we will get the following domain name `59.46.3.190.nip.io`

```
$ export PLATFORM_DOMAIN=59.46.3.190.nip.io
```

## Install

Before installation, please make sure whether your installation environment is a public network.
If it is an intranet environment and there is no public IP, you need to disable the automatic certificate.

```
$ export CERT_MANAGER_ENABLED=false
```

Then you can use the installation script available at https://www.drycc.cc/install.sh to install drycc as a service on systemd and openrc based systems.

```
$ curl -sfL https://www.drycc.cc/install.sh | bash -
```

!!! important
    If you are in China, you need to use mirror acceleration:

    ```
    $ curl -sfL https://www.drycc.cc/install.sh | INSTALL_DRYCC_MIRROR=cn bash -
    ```

### Install Node

Node can be a simple agent or a server; Server has the function of agent. Multiple servers have high availability, but the number of servers should not
exceed 7 at most. There is no limit to the number of agents.

* First, check the cluster token of the master.

```
$ cat /var/lib/rancher/k3s/server/node-token
K1078e7213ca32bdaabb44536f14b9ce7926bb201f41c3f3edd39975c16ff4901ea::server:33bde27f-ac49-4483-b6ac-f4eec2c6dbfa
```

We assume that the IP address of the cluster master is `192.168.6.240`, in that way.

* Then, Set the environment variable:

```
$ export K3S_URL=https://192.168.6.240:6443
$ export K3S_TOKEN="K1078e7213ca32bdaabb44536f14b9ce7926bb201f41c3f3edd39975c16ff4901ea::server:33bde27f-ac49-4483-b6ac-f4eec2c6dbfa"
```

!!! important
    If you are in China, you need to use mirror acceleration:

    ```
    $ export INSTALL_DRYCC_MIRROR=cn
    ```

* Join the cluster as server:

```
$ curl -sfL https://www.drycc.cc/install.sh | bash -s - install_k3s_server
```

* Join the cluster as agent:

```
$ curl -sfL https://www.drycc.cc/install.sh | bash -s - install_k3s_agent
```

### Install Options

When using this method to install drycc, the following environment variables can be used to configure the installation:

ENVIRONMENT VARIABLE                            | DESCRIPTION
------------------------------------------------|---------------------------------------------------------------------------------------------
PLATFORM_DOMAIN                                 | Required item, specify drycc's domain name
DRYCC_ADMIN_USERNAME                            | Required item, specify drycc's admin username
DRYCC_ADMIN_PASSWORD                            | Required item, specify drycc's admin password
CERT_MANAGER_ENABLED                            | Whether to use automatic certificate. It is `true` by default
CHANNEL                                         | By default, `stable` channel will be installed. You can also specify `testing`
CONTAINERD_FILE                                 | The `config.yaml` file path used by containerd
KUBERNETES_SERVICE_HOST                         | Set with the HOST of the loadbalancer that was in front of kube-apiserver
KUBERNETES_SERVICE_PORT                         | Set with the PORT of the loadbalancer that was in front of kube-apiserver
METALLB_CONFIG_FILE                             | The metallb config file path, layer 2 network is used by default
INSTALL_DRYCC_MIRROR                            | Specify the accelerated mirror location. Currently, only `cn` is supported
BUILDER_REPLICAS                                | Number of builder replicas to deploy
CONTROLLER_API_REPLICAS                         | Number of controller api replicas to deploy
CONTROLLER_CELERY_REPLICAS                      | Number of controller celery replicas to deploy
CONTROLLER_WEBHOOK_REPLICAS                     | Number of controller webhook replicas to deploy
CONTROLLER_APP_RUNTIME_CLASS                    | RuntimeClass is a feature for selecting the container runtime configuration.
CONTROLLER_APP_STORAGE_CLASS                    | StorageClass allocated by `drycc volumes`; default storageClass is used by default
REDIS_REPLICAS                                  | Number of redis replicas to deploy
REDIS_PERSISTENCE_SIZE                          | The size of the persistence space allocated to `redis`, which is `5Gi` by default
REDIS_PERSISTENCE_STORAGE_CLASS                 | StorangeClass of `redis`; default storangeclass is used by default
STORAGE_CSI_STATEFULSET_REPLICAS                | Number of storage csi controller replicas to deploy
STORAGE_MAINNODE_TIPD_REPLICAS                  | Number of storage mainode tipd replicas to deploy
STORAGE_MAINNODE_TIPD_PERSISTENCE_SIZE          | The size of the persistence space allocated to `mainnode tipd`, which is `10Gi` by default
STORAGE_MAINNODE_TIPD_PERSISTENCE_STORAGE_CLASS | StorangeClass of `mainnode tipd`; default storangeclass is used by default
STORAGE_MAINNODE_WEED_REPLICAS                  | Number of storage mainode weed replicas to deploy
STORAGE_MAINNODE_WEED_PREALLOCATE               | Preallocate disk space for volumes, `false` is used by default
STORAGE_MAINNODE_WEED_SIZE_LIMIT_MB             | Master stops directing writes to oversized volumes, `30000` is used by default
STORAGE_MAINNODE_WEED_DEFAULT_REPLICATION       | default replication type if not specified, which is `000` by default
STORAGE_MAINNODE_WEED_PERSISTENCE_SIZE          | The size of the persistence space allocated to `mainnode weed`, which is `10Gi` by default
STORAGE_MAINNODE_WEED_PERSISTENCE_STORAGE_CLASS | StorangeClass of `mainnode weed`; default storangeclass is used by default
STORAGE_METANODE_TIKV_REPLICAS                  | Number of storage metanode tikv replicas to deploy
STORAGE_METANODE_TIKV_PERSISTENCE_SIZE          | The size of the persistence space allocated to `metanode tikv`, which is `10Gi` by default
STORAGE_METANODE_TIKV_PERSISTENCE_STORAGE_CLASS | StorangeClass of `mainnode tikv`; default storangeclass is used by default
STORAGE_METANODE_WEED_REPLICAS                  | Number of storage metanode weed replicas to deploy
STORAGE_METANODE_WEED_PERSISTENCE_SIZE          | The size of the persistence space allocated to `metanode weed`, which is `10Gi` by default
STORAGE_METANODE_WEED_PERSISTENCE_STORAGE_CLASS | StorangeClass of `mainnode weed`; default storangeclass is used by default
STORAGE_DATANODE_WEED_REPLICAS                  | Number of storage datanode weed replicas to deploy
STORAGE_DATANODE_WEED_PERSISTENCE_SIZE          | The size of the persistence space allocated to `datanode weed`, which is `20Gi` by default
STORAGE_DATANODE_WEED_PERSISTENCE_STORAGE_CLASS | StorangeClass of `datanode weed`; default storangeclass is used by default
MONITOR_GRAFANA_PERSISTENCE_SIZE                | The size of the persistence space allocated to `monitor.grafana`, which is `5Gi` by default
MONITOR_GRAFANA_PERSISTENCE_STORAGE_CLASS       | StorangeClass of `monitor` grafana; default storangeclass is used by default
LOGGER_REPLICAS                                 | Number of logger replicas to deploy
RABBITMQ_REPLICAS                               | Number of rabbitmq replicas to deploy
RABBITMQ_PERSISTENCE_SIZE                       | The size of the persistence space allocated to `rabbitmq`, which is `5Gi` by default
RABBITMQ_PERSISTENCE_STORAGE_CLASS              | StorangeClass of `rabbitmq`; default storangeclass is used by default
DATABASE_REPLICAS                               | Number of database replicas to deploy
DATABASE_PERSISTENCE_SIZE                       | The size of the persistence space allocated to `database`, which is `5Gi` by default
DATABASE_PERSISTENCE_STORAGE_CLASS              | StorangeClass of `database`; default storangeclass is used by default
TIMESERIES_REPLICAS                             | Number of timeseries replicas to deploy
TIMESERIES_PERSISTENCE_SIZE                     | The size of the persistence space allocated to `timeseries`, which is `5Gi` by default
TIMESERIES_PERSISTENCE_STORAGE_CLASS            | StorangeClass of `timeseries`; default storangeclass is used by default
PASSPORT_REPLICAS                               | Number of passport replicas to deploy
REGISTRY_REPLICAS                               | Number of registry replicas to deploy
HELMBROKER_REPLICAS                             | Number of helmbroker api replicas to deploy
HELMBROKER_CELERY_REPLICAS                      | Number of helmbroker celery replicas to deploy
HELMBROKER_PERSISTENCE_SIZE                     | The size of the persistence space allocated to `helmbroker`, which is `5Gi` by default
HELMBROKER_PERSISTENCE_STORAGE_CLASS            | StorangeClass of `helmbroker`; default storangeclass is used by default
PROMETHEUS_SERVER_RETENTION                     | Prometheus data retention period (default if not specified is 15 days)
PROMETHEUS_SERVER_PERSISTENCE_SIZE              | The size of the persistence space allocated to `prometheus-server`, which is `10Gi` by default
PROMETHEUS_SERVER_PERSISTENCE_STORAGE_CLASS     | StorangeClass of `prometheus-server`; default storangeclass is used by default
K3S_DATA_DIR                                    | The config of k3s data dir; If not set, the default path is used
ACME_SERVER                                     | ACME Server url, default use letsencrypt
ACME_EAB_KEY_ID                                 | The key ID of which your external account binding is indexed by the external account
ACME_EAB_KEY_SECRET                             | The key Secret of which your external account symmetric MAC key

Since the installation script will install k3s, other environment variables can refer to k3s installation [environment variables](https://rancher.com/docs/k3s/latest/en/installation/install-options/).

## Uninstall

If you installed drycc using an installation script, you can uninstall the entire drycc using this script.

```
$ curl -sfL https://www.drycc.cc/uninstall.sh | bash -
```
