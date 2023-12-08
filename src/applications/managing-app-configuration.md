# Configuring an Application

A Drycc application [stores config in environment variables][].


## Setting Environment Variables

Use `drycc config` to modify environment variables for a deployed application.

    $ drycc help config
    Valid commands for config:

    config:list        list environment variables for an app
    config:set         set environment variables for an app
    config:unset       unset environment variables for an app
    config:pull        extract environment variables to .env
    config:push        set environment variables from .env

    Use `drycc help [command]` to learn more.

When config is changed, a new release is created and deployed automatically.

You can set multiple environment variables with one `drycc config:set` command,
or with `drycc config:push` and a local .env file.

    $ drycc config:set FOO=1 BAR=baz && drycc config:pull
    $ cat .env
    FOO=1
    BAR=baz
    $ echo "TIDE=high" >> .env
    $ drycc config:push
    Creating config... done, v4

    === yuppie-earthman
    DRYCC_APP: yuppie-earthman
    FOO: 1
    BAR: baz
    TIDE: high


## Attach to Backing Services

Drycc treats backing services like databases, caches and queues as [attached resources][].
Attachments are performed using environment variables.

For example, use `drycc config` to set a `DATABASE_URL` that attaches
the application to an external PostgreSQL database.

    $ drycc config:set DATABASE_URL=postgres://user:pass@example.com:5432/db
    === peachy-waxworks
    DATABASE_URL: postgres://user:pass@example.com:5432/db

Detachments can be performed with `drycc config:unset`.


## Buildpacks Cache

By default, apps using the [Imagebuilder][] will reuse the latest image data.
When deploying applications that depend on third-party libraries that have to be fetched,
this could speed up deployments a lot. In order to make use of this, the buildpack must implement
the cache by writing to the cache directory. Most buildpacks already implement this, but when using
custom buildpacks, it might need to be changed to make full use of the cache.

### Disabling and re-enabling the cache

In some cases, cache might not speed up your application. To disable caching, you can set the
`DRYCC_DISABLE_CACHE` variable with `drycc config:set DRYCC_DISABLE_CACHE=1`. When you disable the
cache, Drycc will clear up files it created to store the cache. After having it turned off, run
`drycc config:unset DRYCC_DISABLE_CACHE` to re-enable the cache.

### Clearing the cache

Use the following procedure to clear the cache:

    $ drycc config:set DRYCC_DISABLE_CACHE=1
    $ git commit --allow-empty -m "Clearing Drycc cache"
    $ git push drycc # (if you use a different remote, you should use your remote name)
    $ drycc config:unset DRYCC_DISABLE_CACHE


## Custom Health Checks

By default, Workflow only checks that the application starts in their Container. If it is preferred
to have Kubernetes respond to application health, a health check may be added by configuring a
health check probe for the application.

The health checks are implemented as [Kubernetes container probes][kubernetes-probes]. A `liveness`
and a `readiness` probe can be configured, and each probe can be of type `httpGet`, `exec`, or
`tcpSocket` depending on the type of probe the container requires.

A liveness probe is useful for applications running for long periods of time, eventually
transitioning to broken states and cannot recover except by restarting them.

Other times, a readiness probe is useful when the container is only temporarily unable to serve,
and will recover on its own. In this case, if a container fails its readiness probe, the container
will not be shut down, but rather the container will stop receiving incoming requests.

`httpGet` probes are just as it sounds: it performs a HTTP GET operation on the Container. A
response code inside the 200-399 range is considered a pass.

`exec` probes run a command inside the Container to determine its health, such as
`cat /var/run/myapp.pid` or a script that determines when the application is ready. An exit code of
zero is considered a pass, while a non-zero status code is considered a fail.

`tcpSocket` probes attempt to open a socket in the Container. The Container is only considered
healthy if the check can establish a connection. `tcpSocket` probes accept a port number to perform
the socket connection on the Container.

Health checks can be configured on a per-proctype basis for each application using `drycc healthchecks:set`. If no type is mentioned then the health checks are applied to default proc type web, whichever is present. To
configure a `httpGet` liveness probe:

```
$ drycc healthchecks:set liveness httpGet 80 --type web
Applying livenessProbe healthcheck... done

App:             peachy-waxworks
UUID:            afd84067-29e9-4a5f-9f3a-60d91e938812
Owner:           dev
Created:         2023-12-08T10:25:00Z
Updated:         2023-12-08T10:25:00Z
Healthchecks:
                 liveness web http-get headers=[] path=/ port=80 delay=50s timeout=50s period=10s #success=1 #failure=3
```

If the application relies on certain headers being set (such as the `Host` header) or a specific
URL path relative to the root, you can also send specific HTTP headers:

```
$ drycc healthchecks:set liveness httpGet 80 \
    --path /welcome/index.html \
    --headers "X-Client-Version:v1.0,X-Foo:bar"
Applying livenessProbe healthcheck... done

App:             peachy-waxworks
UUID:            afd84067-29e9-4a5f-9f3a-60d91e938812
Owner:           dev
Created:         2023-12-08T10:25:00Z
Updated:         2023-12-08T10:25:00Z
Healthchecks:
                 liveness web http-get headers=[X-Client-Version=v1.0] path=/welcome/index.html port=80 delay=50s timeout=50s period=10s #success=1 #failure=3
```

To configure an `exec` readiness probe:

```
$ drycc healthchecks:set readiness exec -- /bin/echo -n hello --type web
Applying readinessProbe healthcheck... done

App:             peachy-waxworks
UUID:            afd84067-29e9-4a5f-9f3a-60d91e938812
Owner:           dev
Created:         2023-12-08T10:25:00Z
Updated:         2023-12-08T10:25:00Z
Healthchecks:
                 readiness web exec /bin/echo -n hello delay=50s timeout=50s period=10s #success=1 #failure=3
```

You can overwrite a probe by running `drycc healthchecks:set` again:

```
$ drycc healthchecks:set readiness httpGet 80 --type web
Applying livenessProbe healthcheck... done

App:             peachy-waxworks
UUID:            afd84067-29e9-4a5f-9f3a-60d91e938812
Owner:           dev
Created:         2023-12-08T10:25:00Z
Updated:         2023-12-08T10:25:00Z
Healthchecks:
                 liveness web http-get headers=[] path=/ port=80 delay=50s timeout=50s period=10s #success=1 #failure=3
```

Configured health checks also modify the default application deploy behavior. When starting a new
Pod, Workflow will wait for the health check to pass before moving onto the next Pod.


## Isolate the Application

Workflow supports isolating applications onto a set of nodes using `drycc tags`.

!!! note
    In order to use tags, you must first launch your cluster with the proper node labels. If you do
    not, tag commands will fail. Learn more by reading ["Assigning Pods to Nodes"][pods-to-nodes].

Once your nodes are configured with appropriate label selectors, use `drycc tags:set` to restrict
the application to those nodes:

```
$ drycc tags:set environ=prod
Applying tags...  done, v4

environ  prod
```


[attached resources]: http://12factor.net/backing-services
[kubernetes-probes]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes
[pods-to-nodes]: http://kubernetes.io/docs/user-guide/node-selection/
[release]: ../reference-guide/terms.md#release
[router]:  ../understanding-workflow/components.md#router
[Slugbuilder]: ../understanding-workflow/components.md#builder-builder-slugbuilder-and-imagebuilder
[stores config in environment variables]: http://12factor.net/config
