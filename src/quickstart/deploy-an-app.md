## Determine Your Host and Hostname Values

Drycc workflow requires a wildcard DNS record to dynamically map app names to the router.

User should already have DNS set up pointing to their known host. The `$hostname` value can be calculated by prepending `drycc.` to the value set in `global.platform_domain`.

## Login to Workflow

Workflow use the passport component to create and authorize users.
If you already have an account, use `drycc login` to authenticate against the Drycc Workflow API.

```
$ drycc login http://drycc.example.com
Opening browser to http://drycc.example.com/v2/login/drycc/?key=4ccc81ee2dce4349ad5261ceffe72c71
Waiting for login... .o.Logged in as admin
Configuration file written to /root/.drycc/client.json
```

## Deploy an Application

Drycc Workflow supports three different types of applications, Buildpacks,
Dockerfiles and Docker Images. Our first application will be a simple Docker
Image-based application, so you don't have to wrestle with checking out code.

Run `drycc create` to create a new application on Drycc Workflow. If you do not
specify a name for your application, Workflow automatically generates a
friendly (and sometimes funny) name.

```
$ drycc create --no-remote
Creating Application... done, created proper-barbecue
If you want to add a git remote for this app later, use `drycc git:remote -a proper-barbecue`
```

Our application has been created and named `proper-barbecue`. As with the
`drycc` hostname, any HTTP traffic to `proper-barbecue` will be automatically
routed to your application pods by the edge router.

Let's use the CLI to tell the platform to deploy an application and then use curl to send a request to the app:

```
$ drycc pull drycc/example-go -a proper-barbecue
Creating build... done
$ curl http://proper-barbecue.$hostname
Powered by Drycc
```

!!! note
        If you see a 404 error, make sure you specified your application name with `-a <appname>`!

Workflow's edge router knows all about application names and automatically
sends traffic to the right application. The router sends traffic for
`proper-barbecue.104.197.125.75.nip.io` to your app, just like
`drycc.104.197.125.75.nip.io` was sent to the Workflow API service.

## Change Application Configuration

Next, let's change some configuration using the CLI. Our example app is built
to read configuration from the environment. By using `drycc config:set` we can
change how the application behaves:

```
$ drycc config:set POWERED_BY="Docker Images + Kubernetes" -a proper-barbecue
Creating config... done

=== proper-barbecue Config
POWERED_BY      Docker Images + Kubernetes
```

Behind the scenes, Workflow creates a new release for your application and uses
Kubernetes to provide a zero-downtime rolling deploy to the new release!

Validate that our configuration change has worked:

```
$ curl http://proper-barbecue.104.197.125.75.nip.io
Powered by Docker Images + Kubernetes
```

## Scale Your Application

Last, let's scale our application by adding more application processes. Using the CLI you can easily add and remove
additional processes to service requests:

```
$ drycc scale cmd=2 -a proper-barbecue
Scaling processes... but first, coffee!
done in 36s
=== proper-barbecue Processes
--- cmd (started): 2
proper-barbecue-v18-cmd-rk644 up (v18)
proper-barbecue-v18-cmd-0ag04 up (v18)
```

Congratulations! You have deployed, configured, and scaled your first application using Drycc Workflow.

## Going Further
There is a lot more you can do with Drycc Workflow, play around with the CLI:

!!! important
    In order to have permission to push an app you must add a SSH key to your user on the Drycc Workflow.
    For more information, please check [Users and SSH Keys](../users/ssh-keys/) and [Troubleshooting Workflow](../troubleshooting/).

* Roll back to a previous release with `drycc rollback -a proper-barbecue`
* See application logs with `drycc logs -a proper-barbecue`
* Try one of our other example applications like:
    * [drycc/ruby-getting-started](https://github.com/drycc/ruby-getting-started)
    * [drycc/python-getting-started](https://github.com/drycc/python-getting-started)
    * [drycc/php-getting-started](https://github.com/drycc/php-getting-started)
* Read about using application [Buildpacks](../applications/using-buildpacks.md) or [Dockerfiles](../applications/using-dockerfiles.md)
* Join our [#community slack channel](https://drycc.slack.com/) and meet the team!
