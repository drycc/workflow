# Extending Workflow

Drycc Workflow is an open source project which wouldn't be here without the amazing skill
and enthusiasm of the community that has grown up around it. Several projects have blossomed
which extend Workflow in various ways.

These links are to community-contributed extensions of Drycc Workflow. Drycc makes no
guarantees about the functionality, security, or code contained within. As with any software,
use with caution in a production environment.

## Workflow Community Projects

- [alea][] is a backing services manager for Drycc Workflow, providing easy
  access to PostgreSQL, Redis, MongoDB, and memcached.
- [dryccdash][] is a web-based UI supporting many user and app actions without need of the
  `drycc` command-line interface.
- [drycc-cleanup][] is a Drycc-friendly, configurable approach to purging unneeded Docker
  containers and images.
- [drycc-global-config-plugin][] stores config values in [Vault][] for easy use in Workflow apps.
- [drycc-node][] is a controller API client for a browser in NodeJS.
- [drycc-ui][] is the beginning of a full client-side dashboard that interfaces with the
  controller API.
- [drycc-workflow-aws][] simplifies installing Workflow on [Amazon Web Services][], backed by
  S3 and using ECR as the container registry.
- [drycc-workflow-gke][] simplifies installing Workflow on [Google Container Engine][], backed
  by Google Cloud Storage and using gcr.io as the container registry.
- [drycc-workflow-ruby][] contains Workflow controller API bindings for Ruby programming.
- [heroku-to-drycc][] migrates existing Heroku applications to the Workflow platform.
- [kube-solo-osx][] creates a zero-to-Kubernetes development environment for macOS in under
  two minutes, with specific support for installing Workflow with [Helm][] or Helm Classic.

Are we missing something? Please open a [documentation pull request][] to add it.

[alea]: https://github.com/Codaisseur/alea
[Amazon Web Services]: https://aws.amazon.com/
[dryccdash]: https://github.com/olalonde/dryccdash
[drycc-cleanup]: https://github.com/Ragnarson/drycc-cleanup
[drycc-global-config-plugin]: https://github.com/Rafflecopter/drycc-global-config-plugin
[drycc-node]: https://github.com/olalonde/drycc-node
[drycc-ui]: https://github.com/jumbojett/drycc-ui
[drycc-workflow-aws]: https://github.com/rimusz/drycc-workflow-aws
[drycc-workflow-gke]: https://github.com/rimusz/drycc-workflow-gke
[drycc-workflow-ruby]: https://github.com/thomas0087/drycc-workflow-ruby
[documentation pull request]: https://github.com/drycc/workflow/pulls
[Google Container Engine]: https://cloud.google.com/container-engine/
[Helm]: https://github.com/kubernetes/helm
[heroku-to-drycc]: https://github.com/emartech/heroku-to-drycc
[kube-solo-osx]: https://github.com/TheNewNormal/kube-solo-osx
[Vault]: https://www.vaultproject.io/
