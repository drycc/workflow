# Managing resources for an Application

We can use blow command to create resources and bind which resource is created.
This command depend on [service-catalog](https://svc-cat.io).


Use `drycc resources` to create and bind a resource for a deployed application.

    $ drycc help resources
    Valid commands for resources:

    resources:services         list all available resource services
    resources:plans            list all available plans for an resource services
    resources:create           create a resource for the application
    resources:list             list resources in the application
    resources:describe         get a resource detail info in the application
    resources:update           update a resource from the application
    resources:destroy          delete a resource from the applicationa
    resources:bind             bind a resource to servicebroker
    resources:unbind           unbind a resource from servicebroker

    Use 'drycc help [command]' to learn more.

## List all available resource services

You can list available resource services with one `drycc resources:services` command

    $ drycc resources:services
    +------------+------------+
    |    NAME    | UPDATEABLE |
    +------------+------------+
    | mysql      | true       |
    | postgresql | true       |
    | memcached  | true       |
    | redis      | true       |
    +------------+------------+

## List all available plans for an resource services

You can list all available plans for an resource services with one `drycc resources:plans` command

    $ drycc resources:plans redis
    +-------+--------------------------------+
    | NAME  |          DESCRIPTION           |
    +-------+--------------------------------+
    | 40000 | Redis 40000 plan which limit   |
    |       | resources memory size 40Gi.    |
    |   250 | Redis 250 plan which limit     |
    |       | resources memory size 250Mi.   |
    | 20000 | Redis 20000 plan which limit   |
    |       | resources memory size 20Gi.    |
    |  5000 | Redis 5000 plan which limit    |
    |       | resources memory size 5Gi.     |
    |   500 | Redis 500 plan which limit     |
    |       | resources memory size 500Mi.   |
    |   128 | Redis 128 plan which limit     |
    |       | resources memory size 128Mi.   |
    | 50000 | Redis 50000 plan which limit   |
    |       | resources memory size 50Gi.    |
    |  2500 | Redis 2500 plan which limit    |
    |       | resources memory size 2.5Gi.   |
    | 30000 | Redis 30000 plan which limit   |
    |       | resources memory size 30Gi.    |
    | 10000 | Redis 10000 plan which limit   |
    |       | resources memory size 10Gi.    |
    |  1000 | Redis 1000 plan which limit    |
    |       | resources memory size 1Gi.     |
    +-------+--------------------------------+

## Create resource in application

You can create a resource with one `drycc resources:create` command

    $ drycc resources:create redis:1000 redis
    Creating redis to scenic-icehouse... done

After resources are created, you can list the resources in this application.

    $ drycc resources:list
    === scenic-icehouse resources
    redis      redis:1000

## Bind resources

The resource which is named redis is created, you can bind the redis to the application,
use the command of `drycc resources:bind redis`.

    $ drycc resources:bind redis
    Binding resource... done

## Describe resources

And use `drycc resources:describe` show the binding detail. If the binding is successful, this command will show the information of connect to the resource.

    $ drycc resources:describe redis
    === scenic-icehouse resource redis
    plan:               redis:1000
    status:             Ready
    binding:            Ready

    REDISPORT:          6379
    REDIS_PASSWORD:     RzG87SJWG1
    SENTINELHOST:       172.16.0.2
    SENTINELPORT:       26379

## Update resources

You can use the `drycc resources:update` command to upgrade a new plan.
An example of how to upgrade the plan's capacity to 100MB:

    $ drycc resources:update redis:10000 redis
    Updating redis to scenic-icehouse... done

## Remove the resource

If you don't need resources, use `drycc resources:unbind` to unbind the resource and then use `drycc resources:destroy` to delete the resource from the application.
Before deleting the resource, the resource must be unbinded.

    $ drycc resources:unbind redis
    Unbinding resource... done

    $ drycc resources:destroy redis
    Deleting redis from scenic-icehouse... done
