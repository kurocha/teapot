# Teapot

Teapot is a decentralised build tool for managing complex cross-platform projects. It has many goals but it is primarily designed to improve the experience for developers trying to make cross-platform applications and libraries with a minimum of overhead.

- Provide useful feedback when dependencies are not met or errors are encountered.
- Decentralised dependency management allows use within private organisations without exposing code.
- Generators can simplify the construction of new projects as well as assist with the development of existing ones.
- The build subsystem provides a simple set of canonical operations for building libraries and executables to minimise configuration overhead.

[![Build Status](https://secure.travis-ci.org/ioquatix/teapot.png)](http://travis-ci.org/ioquatix/teapot)

## Installation

Ensure that you already have a working install of Ruby 1.9.3+

    $ gem install teapot

## Usage

Teapot doesn't have a centralised package management system. As such, this example shows how to use an existing open source framework.

Firstly, create your project by running:

	$ teapot create "My Project" https://github.com/dream-framework project
	$ cd my-project

You will be asked to merge the project file. At present, merge tools are not very good and thus you may need to take a moment to review the changes. You want to keep most of the original file, but you would like to add the `define_target` blocks which are being added.

In the resulting project directory that has been created, you can see the list of dependencies:

	$ teapot list

To build your project:

	$ teapot build Application/MyProject variant-debug

When you build, you need to specify dependencies. If you haven't specified all dependencies, they will be suggested to you.

The resulting libraries will be framework dependent, but are typically located in

	$ cd teapot/$PROJECT_NAME/platforms/$PLATFORM_NAME/bin/
	$ ./$PROJECT_NAME

### Example: Compiling TaggedFormat

For Linux (requires `clang-3.2` and `libstdc++-4.8`):

	$ teapot create "Local Tagged Format" https://github.com/dream-framework platform-linux variants tagged-format
	$ cd local-tagged-format
	$ teapot build Library/TaggedFormat variant-debug

For Mac OS X (requires Xcode Command Line Tools):
	
	$ teapot create "Local Tagged Format" https://github.com/dream-framework platform-darwin-osx variants tagged-format
	$ cd local-tagged-format
	$ teapot build Library/TaggedFormat variant-debug

You need to make sure any basic tools, e.g. compilers, system libraries, are installed correctly before building. Consult the platform and library documentation for any dependencies.

## Dependency Graph

Dependency analysis is an important part of efficiently building a source tree. A dependency graph constructed from a single output file depends on the set of input files and their associated implicit dependencies (e.g. `#include` directives), and additionally the environment and task that is being performed. Specifically, the environment can specify additional header files, libraries, or other dependent input files and needs to be considered explicitly.

Teapot assumes per-environment dependency graphs and in addition, parts of the dependency graph are generated dynamically. The process of extracting implicit dependencies can be found under `teapot/extractors` and is used extensively in the build graph `teapot/build`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2012, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
