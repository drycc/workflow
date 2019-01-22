## Find Your Load Balancer Address

On Google Container Engine, Drycc Workflow will automatically provision and
attach a Google Cloud Loadbalancer to the router copmonent. This component is
responsible for routing HTTP and HTTPS requests from the public internet to
applications that are deployed and managed by Drycc Workflow.

By describing the `drycc-router` service, you can see what IP address has been
allocated by Google Cloud for your Drycc Workflow cluster:

```
$ kubectl --namespace=drycc describe svc drycc-router | grep LoadBalancer
Type:                   LoadBalancer
LoadBalancer Ingress:   104.197.125.75
```

## Prepare the Hostname

Now that you have the ip address of your load balancer we can use the `nip.io`
DNS service to route arbitrary hostnames to the Drycc Workflow edge router. This
lets us point the Workflow CLI at your cluster without having to either use
your own domain or update DNS!

To verify the Workflow API server and nip.io, construct your hostname by taking
the ip address for your load balancer and adding `nip.io`. For our example
above, the address would be: `104.197.125.75.nip.io`.

Nip answers with the ip address no matter the hostname:
```
$ host 104.197.125.75.nip.io
104.197.125.75.nip.io has address 104.197.125.75
$ host something-random.104.197.125.75.nip.io
something-random.104.197.125.75.nip.io has address 104.197.125.75
```

By default, any HTTP traffic for the hostname `drycc` will be sent to the Workflow API service. To test that everything is connected properly you may validate connectivity using `curl`:

```
$ curl http://drycc.104.197.125.75.nip.io/v2/ && echo
{"detail":"Authentication credentials were not provided."}
```

You should see a failed request because we provided no credentials to the API server.

Remember the hostname, we will use it in the next step.

You are now ready to [register an admin user and deploy your first app](../../deploy-an-app.md).
