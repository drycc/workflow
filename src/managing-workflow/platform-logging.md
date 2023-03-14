# Platform Logging

The logging platform is made up of 2 components - [Fluentd](https://github.com/drycc/fluentd) and [Logger](https://github.com/drycc/logger).

[Fluentd](https://github.com/drycc/fluentd) runs on every worker node of the cluster and is deployed as a [Daemon Set](http://kubernetes.io/v1.1/docs/admin/daemons.html). The Fluentd pods capture all of the stderr and stdout streams of every container running on the host (even those not hosted directly by kubernetes). Once the log message arrives in our [custom fluentd plugin](https://github.com/drycc/fluentd/tree/main/rootfs/opt/fluentd/drycc-output) we determine where the message originated.

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
1) Logger and fluentd pods are running.
2) The application is writing logs to the logger component by checking that an entry in the ring buffer was created: kubectl  --namespace=drycc logs <logger pod>
3) Making sure that the container logs were mounted properly into the fluentd pod: kubectl --namespace=drycc exec <fluentd pod> ls /var/log/containers
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
│App Logs│──Log File──▶│ fluentd │───────topics─────▶│ Redis Stream │     
└────────┘             └─────────┘                   └──────────────┘     
                                                                          
```

## Default Configuration

By default the Fluentd pod can be configured to talk to numerous syslog endpoints. So for example it is possible to have Fluentd send log messages to both the Logger component and [Papertrail](https://papertrailapp.com/). This allows production deployments of Drycc to satisfy stringent logging requirements such as offsite backups of log data.

Configuring Fluentd to talk to multiple syslog endpoints means modifying the Fluentd daemonset
manifest.
This means you will need to fetch the chart with `helm fetch oci://registry.drycc.cc/charts/workflow --untar`, then
modify `workflow/charts/fluentd/templates/logger-fluentd-daemon.yaml` with the following:

```
env:
- name: "SYSLOG_HOST_1"
  value: "my.syslog.host"
- name: "SYSLOG_PORT_1"
  value: "5144"
  ....
- name: "SYSLOG_HOST_N"
  value: "my.syslog.host.n"
- name: "SYSLOG_PORT_N"
  value: "51333"
```

If you only need to talk to 1 Syslog endpoint you can use the following configuration within your chart:

```
env:
- name: "SYSLOG_HOST"
  value: "my.syslog.host"
- name: "SYSLOG_PORT"
  value: "5144"
```

Then run `helm install ./workflow --namespace drycc` to install the modified chart.

### Customizing:

We currently support logging information to Syslog, Elastic Search, and Sumo Logic. However, we will gladly accept pull requests that add support to other locations. For more information please visit the [fluentd repository](https://github.com/drycc/fluentd).


### Custom Fluentd Plugins

That are many output plugins available for [Fluentd](https://github.com/search?q=fluentd+output&ref=opensearch). But, we purposefully do not ship our Fluentd image with these installed. Instead, we provide a mechanism that allows users to install a plugin at startup time of the container and configure it. 

If you would like to install a plugin you can set an environment variable such as the following: `FLUENTD_PLUGIN_N=some-fluentd-plugin` where N is a positive integer that is incremented for every plugin you wish to install. After you set this value you must then set the configuration text for the `FILTER` or `STORE` plugin you are installing. You can do that by setting `CUSTOM_STORE_N=configuration text` where N is the corresponding index value of the plugin you just installed.

Here is an example of setting the values directly in the manifest of the daemonset. 

```
env:
  - name: "FLUENTD_PLUGIN_1"
    value: "fluent-plugin-kafka"
  - name: "CUSTOM_STORE_1"
    value: |
      <store>
        @type kafka \
        default_topic some_topic
      </store>
```

Or you could configure it using the `daemonEnvironment` key in the `values.yaml`:

```
fluentd:
  daemonEnvironment:
    FLUENTD_PLUGIN_1: "fluent-plugin-kafka"
    CUSTOM_STORE_1: "|\n              <store>\n                @type kafka\n                        default_topic some_topic\n                        </store>"
    INSTALL_BUILD_TOOLS: "|\n              true"
```

For more information please see the [Custom Plugins](https://github.com/drycc/fluentd#custom-plugins) section of the README.
