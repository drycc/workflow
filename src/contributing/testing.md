# Testing Drycc

Each Drycc component is one among an ecosystem of such components - many of which integrate with one another - which makes testing each component thoroughly a matter of paramount importance.

Each Drycc component includes its own suite of style checks, [unit tests][], and black-box type [functional tests][].

[Integration tests][] verify the behavior of the Drycc components together as a system and are provided separately by the [drycc/workflow-e2e][workflow-e2e] project.

GitHub pull requests for all Drycc components are tested automatically by the [Travis CI][travis] [continuous integration][] system. Contributors should run the same tests locally before proposing any changes to the Drycc codebase.

## Set Up the Environment

Successfully executing the unit and functional tests for any Drycc component requires that the [Development Environment][dev-environment] is set up first.

## Run the Tests

The style checks, unit tests, and functional tests for each component can all be executed via make targets:

To execute style checks:

```
$ make test-style
```

To execute unit tests:

```
$ make test-unit
```

To execute functional tests:

```
$ make test-functional
```

To execute style checks, unit tests, and functional tests all in one shot:

```
$ make test
```

To execute integration tests, refer to [drycc/workflow-e2e][workflow-e2e] documentation.

[unit tests]: http://en.wikipedia.org/wiki/Unit_testing
[functional tests]: http://en.wikipedia.org/wiki/Functional_testing
[integration tests]: http://en.wikipedia.org/wiki/Integration_testing
[workflow-e2e]: https://github.com/drycc/workflow-e2e
[travis]: https://travis-ci.org/drycc
[continuous integration]: http://en.wikipedia.org/wiki/Continuous_integration
[dev-environment]: development-environment.md
