# About gateway for an Application

A Gateway describes how traffic can be translated to Services within the cluster. That is, it defines a request for a way to translate traffic from somewhere that does not know about Kubernetes to somewhere that does. For example, traffic sent to a Kubernetes Service by a cloud load balancer, an in-cluster proxy, or an external hardware load balancer. While many use cases have client traffic originating “outside” the cluster, this is not a requirement.

## Create Gateway for an Application

Gateway is a way of exposing services externally, which generates an external IP address to connect route and service.

## Create service for an Application

Service is a way of exposing services internally, creating a service generates an internal DNS that can access `procfile_type`.

## Create Route for an Application

A Gateway may be attached to one or more Route references which serve to direct traffic for a subset of traffic to a specific service.