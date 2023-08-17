# Platform Logging

The logging platform is made up of 2 components - [Fluentbit](https://github.com/drycc/fluentbit) and [Logger](https://github.com/drycc/logger).

[Fluentbit](https://github.com/drycc/fluentbit) runs on every worker node of the cluster and is deployed as a [Daemon Set](http://kubernetes.io/v1.1/docs/admin/daemons.html). The Fluentbit pods capture all of the stderr and stdout streams of every container running on the host (even those not hosted directly by kubernetes). Once the log message arrives in our [custom fluentbit plugin](https://github.com/drycc/fluentbit/tree/main/plugin) we determine where the message originated.

If the message was from the [Workflow Controller](https://github.com/drycc/controller) or from an application deployed via workflow we send it to the logs topic on the local [Redis Stream](http://redis.io) instance.

Logger then acts as a consumer reading messages off of the Redis Stream logs topic storing those messages in a local Redis instance. When a user wants to retrieve log entries using the `drycc logs` command we make an HTTP request from Controller to Logger which then fetches the appropriate data from Redis.

## Configuring Off Cluster Redis

Even though we provide a redis instance with the default Workflow install, it is recommended that operators use a third-party source like Elasticache or similar offering. This way your data is durable across upgrades or outages. If you have a third-party Redis installation you would like to use all you need to do is set the following values in your helm chart:

* db = "0"
* host = "my.host.redis"
* port = "6379"
* password = ""

These can be changed by running `helm inspect values drycc/workflow > values.yaml` before using
`helm install` to complete the installation. To customize the redis credentials, edit `values.yaml`
and modify the `redis` section of the file to tune these settings.

## Debugging Logger

If the `drycc logs` command encounters an error it will return the following message:

```
Error: There are currently no log messages. Please check the following things:
1) Logger and fluentbit pods are running.
2) The application is writing logs to the logger component by checking that an entry in the ring buffer was created: kubectl  --namespace=drycc logs <logger pod>
3) Making sure that the container logs were mounted properly into the fluentbit pod: kubectl --namespace=drycc exec <fluentbit pod> ls /var/log/containers
```

## Architecture Diagram

```
                        ┌────────┐                                        
                        │ Router │                  ┌────────┐     ┌─────┐
                        └────────┘                  │ Logger │◀───▶│Redis│
                            │                       └────────┘     └─────┘
                        Log file                        ▲                
                            │                           │                
                            ▼                           │                
┌────────┐             ┌─────────┐    logs/metrics   ┌──────────────┐     
│App Logs│──Log File──▶│Fluentbit│───────topics─────▶│ Redis Stream │     
└────────┘             └─────────┘                   └──────────────┘     
                                                                          
```

## Default Configuration

Fluent Bit is based in a pluggable architecture where different plugins plays a major role in the data pipeline, more than 70 built-in plugins available.
Please refer to charts [values.yaml](https://github.com/drycc/fluentbit/blob/main/charts/fluentbit/values.yaml) for specific configurations.
