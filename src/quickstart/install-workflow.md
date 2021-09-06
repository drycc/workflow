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

### Installing open-iscsi

The command used to install open-iscsi differs depending on the Linux distribution.
We recommend using Ubuntu as the guest OS image since it contains open-iscsi already.
You may need to edit the cluster security group to allow SSH access.
For SUSE and openSUSE, use this command:

```
$ zypper install open-iscsi
```

For Debian and Ubuntu, use this command:

```
$ apt-get install open-iscsi
```

For RHEL, CentOS, and EKS with EKS Kubernetes Worker AMI with AmazonLinux2 image, use this command:

```
$ yum install iscsi-initiator-utils
```

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

### Installing haproxy
We use metallb as the loadblance component.
If the host managed by metallb has a public IP, we don't need to install haproxy.
Otherwise, we need to use haproxy to expose ports such as `80` and `443 `.
Ensure that ports `80`, `443` and `2222` cannot be occupied by other applications on the host, and focus on services such as httpd and nginx.

For Debian and Ubuntu, use this command:

```
$ apt-get install haproxy
```

For RHEL, CentOS, and EKS with EKS Kubernetes Worker AMI with AmazonLinux2 image, use this command:

```
$ yum install haproxy
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

You can use the installation script available at https://www.drycc.cc/install.sh to install drycc as a service on systemd and openrc based systems.

```
$ curl -sfL https://www.drycc.cc/install.sh | bash -
```

!!! important
    Users in Chinese mainland can use the following methods to speed up installation:

    ```
    $ curl -sfL https://www.drycc.cc/install.sh | INSTALL_K3S_MIRROR=cn bash -
    ```

### Install Options

When using this method to install drycc, the following environment variables can be used to configure the installation:

ENVIRONMENT VARIABLE            | DESCRIPTION
--------------------------------|------------------------------------------------------------------------------------------------
PLATFORM_DOMAIN                 | Required item, specify drycc's domain name
DRYCC_ADMIN_USERNAME            | Required item, specify drycc's admin username
DRYCC_ADMIN_PASSWORD            | Required item, specify drycc's admin password
CHANNEL                         | By default, `stable` channel will be installed. You can also specify `testing`
USE_HAPROXY                     | Haproxy is enabled by default. If you want to turn it off, this value is false
METALLB_ADDRESS_POOLS           | IP pool for LoadBalancer. The default is `172.16.0.0/12`
INSTALL_K3S_MIRROR              | Specify the accelerated mirror location. Currently, only `cn` is supported
MINIO_PERSISTENCE_SIZE          | The size of the persistence space allocated to `minio`, which is `5Gi` by default
MONITOR_PERSISTENCE_SIZE        | The size of the persistence space allocated to `monitor`, which is `5Gi` by default
INFLUXDB_PERSISTENCE_SIZE       | The size of the persistence space allocated to `influxdb`, which is `5Gi` by default
RABBITMQ_PERSISTENCE_SIZE       | The size of the persistence space allocated to `rabbitmq`, which is `5Gi` by default
HELMBROKER_PERSISTENCE_SIZE     | The size of the persistence space allocated to `helmbroker`, which is `5Gi` by default

Since the installation script will install k3s, other environment variables can refer to k3s installation [environment variables](https://rancher.com/docs/k3s/latest/en/installation/install-options/).
    
## Uninstall

If you installed drycc using an installation script, you can uninstall the entire drycc using this script.

```
$ curl -sfL https://www.drycc.cc/uninstall.sh | bash -
```
