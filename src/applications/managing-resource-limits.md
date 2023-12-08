## Managing Application Resource Limits

Drycc Workflow supports restricting memory and CPU shares of each process. Requests/Limits set on a per-process type are given to
Kubernetes as a requests and limits. Which means you guarantee <requests\> amount of resource for a process as well as limit
the process from using more than <limits\>.
By default, Kubernetes will set <requests\> equal to <limit\> if we don't explicitly set <requests\> value. Please keep in mind that `0 <= requests <= limits`.

## Limiting

If you set a requests/limits that is out of range for your cluster, Kubernetes will be unable to schedule your application
processes into the cluster!

Available units for memory are:

| Unit | Amount           |
| ---  | ---              |
| B    | Bytes            |
| K    | KiB (Power of 2) |
| M    | MiB (Power of 2) |
| G    | GiB (Power of 2) |

Available units for CPU are:

| Unit  | Amount                            |
| ---   | ---                               |
| 1000m | 1000 milli-cores == 100% CPU core |
| 500m  | 500 milli-cores == 50% CPU core   |
| 250m  | 250 milli-cores == 25% CPU core   |
| 100m  | 100 milli-cores == 10% CPU core   |

Use `drycc limits:set <type>=<value>` to restrict memory by process type, where value can be <limit\> or <request\>/<limit\> format :

```
$ drycc limits:set --cpu cmd=1 -m web=256M
Applying limits... done

UUID                                    OWNER    TYPE       DEVICE    QUOTA
a0ae9c17-ed27-4a61-80b9-35eb924aee5c    dev      web        MEM       256M
a0ae9c17-ed27-4a61-80b9-35eb924aee5c    dev      web        CPU       1
```

