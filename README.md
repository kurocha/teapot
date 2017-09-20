# ![Teapot](materials/teapot.svg)

Teapot is a decentralised build tool for managing complex cross-platform projects. It has many goals but it is primarily designed to improve the experience for developers trying to make cross-platform applications and libraries with a minimum of overhead.

- Provide useful feedback when dependencies are not met or errors are encountered.
- Decentralised dependency management allows use within private organisations without exposing code.
- Generators can simplify the construction of new projects as well as assist with the development of existing ones.
- The build subsystem provides a simple set of canonical operations for building libraries and executables to minimise configuration overhead.

[![Build Status](https://secure.travis-ci.org/kurocha/teapot.svg)](http://travis-ci.org/kurocha/teapot)
[![Code Climate](https://codeclimate.com/github/kurocha/teapot.svg)](https://codeclimate.com/github/kurocha/teapot)
[![Coverage Status](https://coveralls.io/repos/kurocha/teapot/badge.svg)](https://coveralls.io/r/kurocha/teapot)

## Installation

Ensure that you already have a working install of Ruby 2.0.0+ and run the following to install `teapot`:

	$ gem install teapot

## Usage

Teapot doesn't have a default centralised package management system but there is a [canonical one](https://github.com/kurocha) for developing cross-platform C++ applications. This example shows how to use this framework.

### Create Project

Firstly, create your project by running:

	$ teapot create "My Project" https://github.com/kurocha generate-project
	$ cd my-project

You will be asked to merge the project file. At present, merge tools are not very good and thus you may need to take a moment to review the changes. You want to keep most of the original file, but you would like to add the `define_target` blocks which are being added.

In the resulting project directory that has been created, you can see the list of dependencies:

	$ teapot list
	... lots of output ...

To only see things exported by your current project, you can run:

	$ teapot list root
	Package root (from /private/tmp/my-project):
		#<Teapot::Project "my-project">
			My Project description.
			- Summary: A brief one line summary of the project.
			- License: MIT License
			- Version: 0.1.0
			- Author: Samuel Williams <samuel.williams@oriontransfer.co.nz>
		#<Teapot::Target "my-project-library">
			- depends on "Build/Files"
			- depends on "Build/Clang"
			- depends on :platform
			- depends on "Language/C++14" {:private=>true}
			- provides "Library/MyProject"
		#<Teapot::Target "my-project-test">
			- depends on "Library/UnitTest"
			- depends on "Library/MyProject"
			- provides "Test/MyProject"
		#<Teapot::Target "my-project-executable">
			- depends on "Build/Files"
			- depends on "Build/Clang"
			- depends on :platform
			- depends on "Language/C++14" {:private=>true}
			- depends on "Library/MyProject"
			- provides "Executable/MyProject"
		#<Teapot::Target "my-project-run">
			- depends on "Executable/MyProject"
			- provides "Run/MyProject"
		#<Teapot::Configuration "development" visibility=private>
			- references root from /private/tmp/my-project
			- clones platforms from https://github.com/kurocha/platforms
			- clones unit-test from https://github.com/kurocha/unit-test
			- clones generate-cpp-class from https://github.com/kurocha/generate-cpp-class
			- clones generate-project from https://github.com/kurocha/generate-project
			- clones variants from https://github.com/kurocha/variants
			- clones platform-darwin-osx from https://github.com/kurocha/platform-darwin-osx
			- clones platform-darwin-ios from https://github.com/kurocha/platform-darwin-ios
			- clones build-clang from https://github.com/kurocha/build-clang
			- clones build-darwin from https://github.com/kurocha/build-darwin
			- clones build-files from https://github.com/kurocha/build-files
			- clones streams from https://github.com/kurocha/streams
			- clones generate-template from https://github.com/kurocha/generate-template
		#<Teapot::Configuration "my-project" visibility=public>
			- references root from /private/tmp/my-project

### Run Tests

Testing is a good idea, and teapot supports test driven development.

	$ teapot Test/MyProject

#### Wildcard Targets

To run all tests:

	$ teapot "Test/*"

Provided you are using an environment that supports sanitizers, you can test more thoroughly using:

	$ teapot "Test/*" variant-sanitize

### Run Project

We can now build and run the project executable:

	$ teapot Run/MyProject
	I'm a little teapot,
	Short and stout,
	Here is my handle (one hand on hip),
	Here is my spout (other arm out with elbow and wrist bent).
	When I get all steamed up,
	Hear me shout,
	Tip me over and pour me out! (lean over toward spout)

	                              ~
	                   ___^___   __
	               .- /       \./ /
	              /  /          _/
	              \__|         |
	                  \_______/

The resulting executables and libraries will be framework dependent, but are typically located in:

	$ cd teapot/platforms/development/$PLATFORM-debug/bin
	$ ./$PROJECT_NAME

### Cloning Project

You can clone another project which will fetch all dependencies:

	$ teapot clone https://github.com/kurocha/tagged-format
	$ cd tagged-format
	$ teapot build Executable/TaggedFormat

## Open Issues

- Should packages be built into a shared prefix or should they be built into unique prefixes and joined together either via install or `-L` and `-I`?
	- Relative include paths might fail to work correctly if headers are not installed into same directory.
- Should packages have some way to expose system requirements, e.g. installed compiler, libraries, etc. Perhaps some kind of `Package#valid?` which allows custom logic?

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2012, 2014, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

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
