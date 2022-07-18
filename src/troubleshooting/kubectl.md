# Troubleshooting using Kubectl

This document describes how one can use `kubectl` to debug any issues with the cluster.

## Diving into the Components

Using `kubectl`, one can inspect the cluster's current state. When Workflow is installed
with `helm`, Workflow is installed into the `drycc` namespace. To inspect if Workflow is
running, run:

	$ kubectl --namespace=drycc get pods
	NAME                          READY     STATUS              RESTARTS   AGE
	drycc-builder-gqum7            0/1       ContainerCreating   0          4s
	drycc-controller-h6lk6         0/1       ContainerCreating   0          4s
	drycc-controller-celery-cmxxn  0/3       ContainerCreating   0          4s
	drycc-database-56v39           0/1       ContainerCreating   0          4s
    drycc-influxdb-f9ftm           0/1       Pending             0          3s
	drycc-logger-fluentd-xihr1     0/1       Pending             0          2s
	drycc-logger-grupg             0/1       ContainerCreating   0          3s
	drycc-storage-c2exb              0/1       Pending             0          3s
	drycc-monitor-grafana-9ccur    0/1       Pending             0          3s
	drycc-monitor-telegraf-dc3y3   0/1       Pending             0          2s
	drycc-registry-5bor6           0/1       Pending             0          3s
	drycc-rabbitmq-0               0/1       ContainerCreating   0          3s

!!! tip
	To save precious keystrokes, alias `kubectl --namespace=drycc` to `kd` so it is easier to type
	in the future.

To fetch the logs of a specific component, use `kubectl logs`:

	$ kubectl --namespace=drycc logs drycc-controller-h6lk6
	system information:
	Django Version: 1.9.6
	Python 3.5.1
	addgroup: gid '0' in use
	Django checks:
	System check identified no issues (2 silenced).
	[...]

To dive into a running container to inspect its environment, use `kubectl exec`:

	$ kubectl --namespace=drycc exec -it drycc-database-56v39 gosu postgres psql
    psql (13.4 (Debian 13.4-1.pgdg100+1))
    Type "help" for help.

	postgres=# \l
	                                                List of databases
	     Name          |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
	-------------------+----------+----------+------------+------------+-----------------------
	 drycc_controller  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
	 drycc_passport    | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
	 postgres          | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
	 template0         | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
	                   |          |          |            |            | postgres=CTc/postgres
	 template1         | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
	                   |          |          |            |            | postgres=CTc/postgres
	(4 rows)
	postgres=# \connect drycc_controller
	You are now connected to database "drycc_controller" as user "postgres".
	drycc_controller=# \dt
	                                 List of relations
	 Schema |              Name              | Type  |      Owner
	--------+--------------------------------+-------+-------------------
	 public | api_app                        | table | drycc_controller
	 public | api_build                      | table | drycc_controller
	 public | api_certificate                | table | drycc_controller
	 public | api_config                     | table | drycc_controller
	 public | api_domain                     | table | drycc_controller
	 public | api_key                        | table | drycc_controller
	 public | api_push                       | table | drycc_controller
	 public | api_release                    | table | drycc_controller
	 public | auth_group                     | table | drycc_controller
	 --More--
	 drycc_controller=# SELECT COUNT(*) from api_app;
	 count
	-------
	     0
	(1 row)
