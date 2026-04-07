# ![Teapot](materials/teapot.svg)

Teapot is a decentralised build tool for managing complex cross-platform projects. It has many goals but it is primarily designed to improve the experience for developers trying to make cross-platform applications and libraries with a minimum of overhead.

  - Provide useful feedback when dependencies are not met or errors are encountered.
  - Decentralised dependency management allows use within private organisations without exposing code.
  - Generators can simplify the construction of new projects as well as assist with the development of existing ones.
  - The build subsystem provides a simple set of canonical operations for building libraries and executables to minimise configuration overhead.

[![Development Status](https://github.com/kurocha/teapot/workflows/Test/badge.svg)](https://github.com/kurocha/teapot/actions?workflow=Test)

## Installation

Ensure that you already have a working install of Ruby 2.0.0+ and run the following to install `teapot`:

    $ gem install teapot

## Usage

Please see the [project documentation](https://ioquatix.github.io/teapot/) for more details.

  - [Getting Started](https://ioquatix.github.io/teapot/guides/getting-started/index) - This guide explains how to use `teapot` to manage cross-platform project dependencies and build systems.

## Releases

Please see the [project releases](https://ioquatix.github.io/teapot/releases/index) for all releases.

### v3.6.0

  - Update dependencies.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
