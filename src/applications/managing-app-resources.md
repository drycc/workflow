# Managing resources for an Application

We can use blow command to create resources and bind which resource is created.
This command depend on [service-catalog](https://svc-cat.io).


Use `drycc resources` to create and bind a resource for a deployed application.

    $ drycc help resources
    Valid commands for resources:

    resources:create           create a resource for the application
    resources:list             list resources in the application
    resources:describe         get a resource detail info in the application
    resources:update           update a resource from the application
    resources:destroy          delete a resource from the applicationa
    resources:bind             bind a resource to servicebroker
    resources:unbind           unbind a resource from servicebroker

    Use 'drycc help [command]' to learn more.

## Create resource in application

You can create a resource with one `drycc resources:create` command

    $ drycc resources:create memcached:custom memcached
    Creating memcached to scenic-icehouse... done

After resources are created, you can list the resources in this application.

    $ drycc resources:list
    === scenic-icehouse resources
    memcached      memcached:custom

## Bind resources

The resource which is named memcached is created, you can bind the memcached to the application,
use the command of `drycc resources:bind memcached`.

    $ drycc resources:bind memcached
    Binding resource... done

## Describe resources

And use `drycc resources:describe` show the binding detail. If the binding is successful, this command will show the information of connect to the resource.

    $ drycc resources:describe memcached
    === scenic-icehouse resource memcached
    plan:        memcached:custom
    status:      Ready
    binding:     Ready

    HOST:        10.1.7.241 10.1.7.101
    PORT:        11211

## Update resources

You can use the `drycc resources:update` command to upgrade a new plan.
An example of how to upgrade the plan's capacity to 100MB:

    $ drycc resources:update memcached:100 memcached
    Updating memcached to scenic-icehouse... done

## Remove the resource

If you don't need resources, use `drycc resources:unbind` to unbind the resource and then use `drycc resources:destroy` to delete the resource from the application.
Before deleting the resource, the resource must be unbinded.

    $ drycc resources:unbind memcached
    Unbinding resource... done

    $ drycc resources:destroy memcached
    Deleting memcached from scenic-icehouse... done


