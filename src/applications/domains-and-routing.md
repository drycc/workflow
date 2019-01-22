## Domains and Routing

You can use `drycc domains` to add or remove custom domains to the application:

    $ drycc domains:add hello.bacongobbler.com
    Adding hello.bacongobbler.com to finest-woodshed... done

Once that's done, you can go into a DNS registrar and set up a CNAME from the new
appname to the old one:

    $ dig hello.dryccapp.com
    [...]
    ;; ANSWER SECTION:
    hello.bacongobbler.com.         1759    IN    CNAME    finest-woodshed.dryccapp.com.
    finest-woodshed.dryccapp.com.    270     IN    A        172.17.8.100

!!! note
    Setting a CNAME for a root domain can cause issues. Setting an @ record
    to be a CNAME causes all traffic to go to the other domain, including mail and the SOA
    ("start-of-authority") records. It is highly recommended that you bind a subdomain to
    an application, however you can work around this by pointing the @ record to the
    address of the load balancer (if any).

To add or remove the application from the routing mesh, use `drycc routing`:

    $ drycc routing:disable
    Disabling routing for finest-woodshed... done

This will make the application unreachable through the [Router][], but the application is still
reachable internally through its [Kubernetes Service][service]. To re-enable routing:

    $ drycc routing:enable
    Enabling routing for finest-woodshed... done


[router]: ../understanding-workflow/components.md#router
[service]: ../reference-guide/terms.md#service
