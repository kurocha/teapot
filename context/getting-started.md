# Getting Started

This guide explains how to use `teapot` to manage cross-platform project dependencies and build systems.

## Installation

Ensure that you already have a working install of Ruby 2.0.0+ and run the following to install `teapot`:

~~~ bash
$ gem install teapot
~~~

## Create Project

Firstly, create your project by running:

~~~ bash
$ teapot create "My Project" https://github.com/kurocha generate-project
$ cd my-project
~~~

You will be asked to merge the project file. At present, merge tools are not very good and thus you may need to take a moment to review the changes. You want to keep most of the original file, but you would like to add the `define_target` blocks which are being added.

In the resulting project directory that has been created, you can see the list of dependencies:

~~~ bash
$ teapot list
... lots of output ...
~~~

To only see things exported by your current project, you can run:

~~~ bash
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
~~~

## Run Tests

Testing is a good idea, and teapot supports test driven development.

~~~ bash
$ teapot Test/MyProject
~~~

### Wildcard Targets

To run all tests:

~~~ bash
$ teapot "Test/*"
~~~

Provided you are using an environment that supports sanitizers, you can test more thoroughly using:

~~~ bash
$ teapot "Test/*" variant-sanitize
~~~

## Run Project

We can now build and run the project executable:

~~~ bash
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
~~~

The resulting executables and libraries will be framework dependent, but are typically located in:

~~~ bash
$ cd teapot/platforms/development/$PLATFORM-debug/bin
$ ./$PROJECT_NAME
~~~

## Cloning Project

You can clone another project which will fetch all dependencies:

~~~ bash
$ teapot clone https://github.com/kurocha/tagged-format
$ cd tagged-format
$ teapot build Executable/TaggedFormat
~~~
