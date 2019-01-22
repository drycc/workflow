# Configuring Load Balancers

Depending on what distribution of Kubernetes you use and where you host it, installation of Drycc Workflow may automatically provision an external (to Kubernetes) load balancer or similar mechanism for directing inbound traffic from beyond the cluster to the Drycc router(s).  For example, [kube-aws](https://coreos.com/kubernetes/docs/latest/kubernetes-on-aws.html) and [Google Container Engine](https://cloud.google.com/container-engine/) both do this.  On some other platforms-- Minikube or bare metal, for instance-- this must either be accomplished manually or does not apply at all.

## Idle connection timeouts

If a load balancer such as the one described above does exist (whether created automatically or manually) and if you intend on handling any long-running requests, the load balancer (or similar) may require some manual configuration to increase the idle connection timeout.  Typically, this is most applicable to AWS and Elastic Load Balancers, but may apply in other cases as well.  It does not apply to Google Container Engine, as the idle connection timeout cannot be configured there, but also works as-is.

If, for instance, Drycc Workflow were installed on kube-aws, this timeout should be increased to a recommended value of 1200 seconds.  This will ensure the load balancer does not hang up on the client during long-running operations like an application deployment.  The AWS-specific annotation below will be included by default in the router service starting in Workflow v2.13.0.

If you are running Kubernetes v1.4 or later but a Workflow version earlier than v2.13.0, you should configure the idle timeout using this service annotation:

```
$ kubectl --namespace=drycc annotate service/drycc-router service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout=1200
```

On older Kubernetes versions, you have to [configure the idle timeout manually](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/config-idle-timeout.html), but it will reset back to the default of 60 seconds whenever Kubernetes needs to reconfigure the load balancer, for example because a node in your cluster was added or removed. Remember to re-apply your manual changes if that happens.

## Configuring PROXY protocol

By default Kubernetes will create an external TCP load balancer to route incoming requests to the Drycc router, which will take care of forwarding the requests to the right application inside the cluster depending on the hostname. Because the original request is not modified by the load balancer, the router only knows about the internal IP address of the load balancer which will then be forwarded to your app in the `X-Forwarded-For` HTTP header.

If you need access to the *actual* client's IP address in your application, for example for IP-based sessions, access control or auditing, you need to configure the external load balancer and the Drycc router to use the [PROXY protocol](http://www.haproxy.org/download/1.6/doc/proxy-protocol.txt). The PROXY protocol adds a small header with the client's IP address to each connection, which can then be used by the Drycc router to pass the actual client IP in the `X-Forwarded-For` HTTP header.

**Here's how to enable PROXY protocol when running Kubernetes on AWS with an ELB Classic Load Balancer:**

Enable PROXY protocol for the `drycc-router` deployment:

```
$ kubectl --namespace=drycc annotate deployment/drycc-router router.drycc.cc/nginx.useProxyProtocol=true
```

Enable PROXY protocol on the ELB load balancer for the `drycc-router` service:

```
$ kubectl --namespace=drycc annotate service/drycc-router service.beta.kubernetes.io/aws-load-balancer-proxy-protocol='*'
```

Prepare for a short downtime until both the ELB and the router have converged to the new configuration.

!!! important
    ELB PROXY protocol support was added in Kubernetes 1.3. If you are still on Kubernetes 1.2, you need to first upgrade to a newer [supported Kubernetes version](https://drycc.info/docs/workflow/installing-workflow/system-requirements/#kubernetes-versions).

## Manually configuring a load balancer

If using a Kubernetes distribution or underlying infrastructure that does not support the automated provisioning of a front-facing load balancer, operators will wish to manually configure a load balancer (or use other tricks) to route inbound traffic from beyond the cluster into the cluster to the Drycc router(s).  There are many ways to accomplish this.  This documentation will focus on the most common method.  Readers interested in other options may refer to [the router component's own documentation](https://github.com/drycc/router#front-facing-load-balancer) for further details.

Begin by determining the "node ports" for the `drycc-router` service:


```
$ kubectl --namespace=drycc describe service drycc-router
```

This will yield output similar to the following:

```
...
Port:			http	80/TCP
NodePort:		http	32477/TCP
Endpoints:		10.2.80.11:80
Port:			https	443/TCP
NodePort:		https	32389/TCP
Endpoints:		10.2.80.11:443
Port:			builder	2222/TCP
NodePort:		builder	30729/TCP
Endpoints:		10.2.80.11:2222
Port:			healthz	9090/TCP
NodePort:		healthz	31061/TCP
Endpoints:		10.2.80.11:9090
...
```

The node ports shown above are high-numbered ports that are allocated on every Kubernetes worker node for use by the router service.  The kube-proxy component on every Kubernetes node will listen on these ports and proxy traffic through to the corresponding port within an endpoint-- that is, a pod running the Drycc router.

If manually creating a load balancer, configure it to forward inbound traffic on ports 80, 443, and 2222 (port 9090 can be ignored) to the corresponding node ports on your Kubernetes worker nodes.  Ports 80 and 443 may use either HTTP/S or TCP as protocols.  Port 2222 must use TCP.
