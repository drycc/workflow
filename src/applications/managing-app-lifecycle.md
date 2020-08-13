# Managing an Application

## Track Application Changes

Drycc Workflow tracks all changes to your application. Application changes are the result of either new application code
pushed to the platform (via `git push drycc master`), or an update to application configuration (via `drycc config:set KEY=VAL`).

Each time a build or config change is made to your application a new [release][] is created. These release numbers
increase monotonically.

You can see a record of changes to your application using `drycc releases`:

```
$ drycc releases
=== peachy-waxworks Releases
v4      3 minutes ago                     gabrtv deployed d3ccc05
v3      1 hour 17 minutes ago             gabrtv added DATABASE_URL
v2      6 hours 2 minutes ago             gabrtv deployed 7cb3321
v1      6 hours 2 minutes ago             gabrtv deployed drycc/helloworld
```

## Rollback a Release

Drycc Workflow also supports rolling back go previous releases. If buggy code or an errant configuration change is pushed
to your application, you may rollback to a previously known, good release.

!!! note
    All rollbacks create a new, numbered release. But will reference the build/code and configuration from the desired rollback point.


In this example, the application is currently running release v4. Using `drycc rollback v2` tells Workflow to deploy the
build and configuration that was used for release v2. This creates a new release named v5 whose contents are the source
and configuration from release v2:

```
$ drycc releases
=== folksy-offshoot Releases
v4      4 minutes ago                     gabrtv deployed d3ccc05
v3      1 hour 18 minutes ago             gabrtv added DATABASE_URL
v2      6 hours 2 minutes ago             gabrtv deployed 7cb3321
v1      6 hours 3 minutes ago             gabrtv deployed drycc/helloworld

$ drycc rollback v2
Rolled back to v2

$ drycc releases
=== folksy-offshoot Releases
v5      Just now                          gabrtv rolled back to v2
v4      4 minutes ago                     gabrtv deployed d3ccc05
v3      1 hour 18 minutes ago             gabrtv added DATABASE_URL
v2      6 hours 2 minutes ago             gabrtv deployed 7cb3321
v1      6 hours 3 minutes ago             gabrtv deployed drycc/helloworld
```

## Run One-off Administration Tasks

Drycc applications [use one-off processes for admin tasks][] like database migrations and other commands that must run against the live application.

Use `drycc run` to execute commands on the deployed application.

    $ drycc run 'ls -l'
    Running `ls -l`...

    total 28
    -rw-r--r-- 1 root root  553 Dec  2 23:59 LICENSE
    -rw-r--r-- 1 root root   60 Dec  2 23:59 Procfile
    -rw-r--r-- 1 root root   33 Dec  2 23:59 README.md
    -rw-r--r-- 1 root root 1622 Dec  2 23:59 pom.xml
    drwxr-xr-x 3 root root 4096 Dec  2 23:59 src
    -rw-r--r-- 1 root root   25 Dec  2 23:59 system.properties
    drwxr-xr-x 6 root root 4096 Dec  3 00:00 target


## Share an Application

Use `drycc perms:create` to allow another Drycc user to collaborate on your application.

```
$ drycc perms:create otheruser
Adding otheruser to peachy-waxworks collaborators... done
```

Use `drycc perms` to see who an application is currently shared with, and `drycc perms:remove` to remove a collaborator.

!!! note
    Collaborators can do anything with an application that its owner can do, except delete the application.

When working with an application that has been shared with you, clone the original repository and add Drycc' git remote
entry before attempting to `git push` any changes to Drycc.

```
$ git clone https://github.com/drycc/example-java-jetty.git
Cloning into 'example-java-jetty'... done
$ cd example-java-jetty
$ git remote add -f drycc ssh://git@local3.dryccapp.com:2222/peachy-waxworks.git
Updating drycc
From drycc-controller.local:peachy-waxworks
 * [new branch]      master     -> drycc/master
```

## Application Troubleshooting

Applications deployed on Drycc Workflow [treat logs as event streams][]. Drycc Workflow aggregates `stdout` and `stderr`
from every [Container][] making it easy to troubleshoot problems with your application.

Use `drycc logs` to view the log output from your deployed application.

    $ drycc logs | tail
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.5]: INFO:oejsh.ContextHandler:started o.e.j.s.ServletContextHandler{/,null}
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.8]: INFO:oejs.Server:jetty-7.6.0.v20120127
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.5]: INFO:oejs.AbstractConnector:Started SelectChannelConnector@0.0.0.0:10005
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.6]: INFO:oejsh.ContextHandler:started o.e.j.s.ServletContextHandler{/,null}
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.7]: INFO:oejsh.ContextHandler:started o.e.j.s.ServletContextHandler{/,null}
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.6]: INFO:oejs.AbstractConnector:Started SelectChannelConnector@0.0.0.0:10006
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.8]: INFO:oejsh.ContextHandler:started o.e.j.s.ServletContextHandler{/,null}
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.7]: INFO:oejs.AbstractConnector:Started SelectChannelConnector@0.0.0.0:10007
    Dec  3 00:30:31 ip-10-250-15-201 peachy-waxworks[web.8]: INFO:oejs.AbstractConnector:Started SelectChannelConnector@0.0.0.0:10008

[application]: ../reference-guide/terms.md#application
[container]: ../reference-guide/terms.md#container
[release]: ../reference-guide/terms.md#release
[store config in environment variables]: http://12factor.net/config
[decoupled from the application]: http://12factor.net/backing-services
[scale out via the process model]: http://12factor.net/concurrency
[treat logs as event streams]: http://12factor.net/logs
[use one-off processes for admin tasks]: http://12factor.net/admin-processes
[Procfile]: http://ddollar.github.io/foreman/#PROCFILE
[router]: ../understanding-workflow/components.md#router
