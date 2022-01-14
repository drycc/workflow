# Mounting volumes for an Application

We can use the blow command to create volumes and mount the created volumes.
Drycc create volume support [ReadWriteMany](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes), so before deploying drycc, you need to have a StorageClass ready which can support ReadWriteMany.
Deploying drycc, set controller.appStorageClass to this StorageClass.


Use `drycc volumes` to mount a volume for a deployed application's processes.

    $ drycc help volumes
    Valid commands for volumes:

    volumes:create           create a volume for the application
    volumes:list             list volumes in the application
    volumes:delete           delete a volume from the application
    volumes:mount            mount a volume to process of the application
    volumes:unmount          unmount a volume from process of the application

    Use 'drycc help [command]' to learn more.

## Create a volume for the application

You can create a volume with the `drycc volumes:create` command

    $ drycc volumes:create myvolume 200M
    Creating myvolumes to scenic-icehouse... done

## List volumes in the application

After volume is created, you can list the volumes in this application.

    $ drycc volumes:list
    === scenic-icehouse volumes
    --- myvolumes     200M

## Mount a volume

The volume which is named myvolumes is created, you can mount the volume with process of the application,
use the command of `drycc volumes:mount`. When volume is mounted, a new release will be created and deployed automatically.

    $ drycc volumes:mount myvolumes web=/data/web
    Mounting volume... done

And use `drycc volumes:list` show mount detail.

    $ drycc volumes:list
    === scenic-icehouse volumes
    --- myvolumes     200M
    web               /data/web

If you don't need the volume, use `drycc volumes:unmount` to unmount the volume and then use  `drycc volumes:delete` to delete the volume from the application.
Before deleting volume, the volume has to be unmounted.

    $ drycc volumes:unmount myvolumes web
    Unmounting volume... done

    $ drycc volumes:delete myvolumes
    Deleting myvolumes from scenic-icehouse... done
