## Drycc Workflow Client CLI

The Drycc command-line interface (CLI), lets you interact with Drycc Workflow.
Use the CLI to create and configure and manage applications.

Install the `drycc` client for Linux or Mac OS X with:

    $ curl -sSL https://raw.githubusercontent.com/drycc/workflow-cli/main/install.tmpl | bash -s v1.1.0

Others please visit: https://github.com/drycc/workflow-cli/releases

The installer places the `drycc` binary in your current directory, but you
should move it somewhere in your $PATH:

    $ sudo ln -fs $PWD/drycc /usr/local/bin/drycc

*or*:

    $ sudo mv $PWD/drycc /usr/local/bin/drycc

Check your work by running `drycc version`:

    $ drycc version
    v1.1.0

!!! note
    Note that version numbers may vary as new releases become available

## Helm Installation

We will install Drycc Workflow using Helm which is a tool for installing and managing software in a
Kubernetes cluster.

Install the latest `helm` cli for Linux or Mac OS X by following the
[installation instructions][helm-install].

## Step 2: Boot a Kubernetes Cluster and Install Drycc Workflow

There are many ways to boot and run Kubernetes. You may choose to get up and running in cloud environments or locally on your laptop.

Cloud-based options:

* [Google Container Engine](provider/gke/boot.md): provides a managed Kubernetes environment, available with a few clicks.
* [Amazon Web Services](provider/aws/boot.md): uses Kubernetes upstream [kops](https://github.com/kubernetes/kops) to boot a cluster on AWS EC2.
* [Azure Container Service](provider/azure-acs/boot.md): provides a managed Kubernetes environment.

If you would like to test on your local machine follow our guide for [Minikube](provider/minikube/boot.md).


[helm-install]: https://github.com/kubernetes/helm#install
