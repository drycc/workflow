# Drycc Workflow Roadmap

The Drycc Workflow Roadmap is a community document created as part of the open
[Planning Process](planning-process.md). Each roadmap item describes a high-level capability or
grouping of features that are deemed important to the future of Drycc.

Given the project's rapid [Release Schedule](releases.md), roadmap
items are designed to provide a sense of direction over many releases.

## Interactive `drycc run /bin/bash`

Provide the ability for developers to launch an interactive terminal session in
their application environment.

Related issues:

* <https://github.com/drycc/workflow-cli/issues/28>
* <https://github.com/drycc/drycc/issues/117>

## Log Streaming

Stream application logs via `drycc logs -f` <https://github.com/drycc/drycc/issues/465>

## Teams and Permissions

Teams and Permissions represents a more flexible permissions model to allow
more nuanced control to applications, capabilities and resources on the
platform. There have been a number of proposals in this area which need to be
reconciled for Drycc Workflow before we begin implementation.

Related issues:

* Deploy Keys: <https://github.com/drycc/drycc/issues/3875>
* Teams: <https://github.com/drycc/drycc/issues/4173>
* Fine grained permissions: <https://github.com/drycc/drycc/issues/4150>
* Admins create apps only: <https://github.com/drycc/drycc/issues/4052>
* Admin Certificate Permissions: <https://github.com/drycc/drycc/issues/4576#issuecomment-170987223>

## Monitoring

* [ ] Define and deliver alerts with Kapacitor: <https://github.com/drycc/monitor/issues/44>

## Workflow Addons/Services

Developers should be able to quickly and easily provision application
dependencies using a services or addon abstraction.
<https://github.com/drycc/drycc/issues/231>

## Inbound/Outbound Webhooks

Drycc Workflow should be able to send and receive webhooks from external
systems. Facilitating integration with third party services like GitHub,
Gitlab, Slack, Hipchat.

* [X] Send webhook on platform events: <https://github.com/drycc/drycc/issues/1486> (Workflow v2.10)
