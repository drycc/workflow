# Security Considerations

!!! important
	Workflow is not suitable for multi-tenant environments or hosting untrusted code.

A major goal of Workflow is to be operationally secure and trusted by operations engineers in every
deployed environment. There are, however, two notable security-related considerations to be aware
of when deploying Workflow.

# Application Runtime Segregation

Users of Workflow often want to deploy their applications to separate environments. Typically,
physical network isolation isn’t the goal, but rather segregation of application environments - if a
region goes haywire, it shouldn’t affect applications that are running in a separate region.

In Workflow, deployed applications can be segregated by using the `drycc tags` command. This enables
you to tag machines in your cluster with arbitrary metadata, then configure your applications to be
scheduled to machines which match the metadata.

For example, if some machines in your cluster are tagged with `region=us-west-1` and some
with `region=us-east-1`, you can configure an application to be deployed to us-west-1
by using `drycc tags set region=us-west-1`. Workflow will pass this configuration
along to Kubernetes, which will schedule your application in different regions.

See [Isolate the Application][] for more information.

# Running Workflow on Public Clouds

If you are running on a public cloud without security group features, you will have to set up
security groups yourself through either `iptables` or a similar tool. The only ports on worker
nodes that should be exposed to the public are:

 - 22: (optional) for remote SSH
 - 80: for the routers
 - 443: (optional) routers w/ SSL enabled
 - 2222: for the routers proxying TCP to the builder
 - 9090: for the routers' health check

# IP Whitelist

Enforcing a cluster-wide IP whitelist may be advisable for routers governing ingress to a cluster
that hosts applications intended for a limited audience-- e.g. applications for internal use within
an organization. You can enforce cluster-wide IP whitelisting by enabling whitelists, then
attaching an annotation to the router:

    $ kubectl --namespace=drycc annotate deployments/drycc-router router.drycc.cc/nginx.enforceWhitelists=true
    $ kubectl --namespace=drycc annotate deployments/drycc-router router.drycc.cc/nginx.defaultWhitelist="0.0.0.0/0"

The format is the same for the controller whitelist but you need to specify the whitelist directly
to the controller's service. For example:

    $ kubectl --namespace=drycc annotate service drycc-controller router.drycc.cc/whitelist="10.0.1.0/24,121.212.121.212"

And the same applies to applications. For example, to apply a whitelist to an application named
`example`:

    $ kubectl --namespace=example annotate service example-web router.drycc.cc/whitelist="10.0.1.0/24,121.212.121.212"

Application level whitelisting can also be done using the Drycc client. To add/remove/list addresses of an application whitelist, use `drycc whitelist`:

    $ drycc whitelist:add 10.0.1.0/24,121.212.121.212 -a drafty-zaniness
    Adding 10.0.1.0/24,121.212.121.212 to drafty-zaniness whitelist...done

    $ drycc whitelist:remove 121.212.121.212 -a drafty-zaniness
    Removing 121.212.121.212 from drafty-zaniness whitelist... done

    $ drycc whitelist -a drafty-zaniness
    === drafty-zaniness Whitelisted Addresses
    10.0.1.0/24


[Isolate the Application]: ../applications/managing-app-configuration.md#isolate-the-application
