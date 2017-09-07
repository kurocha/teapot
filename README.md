# ![Teapot](materials/teapot.svg)

Teapot is a decentralised build tool for managing complex cross-platform projects. It has many goals but it is primarily designed to improve the experience for developers trying to make cross-platform applications and libraries with a minimum of overhead.

- Provide useful feedback when dependencies are not met or errors are encountered.
- Decentralised dependency management allows use within private organisations without exposing code.
- Generators can simplify the construction of new projects as well as assist with the development of existing ones.
- The build subsystem provides a simple set of canonical operations for building libraries and executables to minimise configuration overhead.

[![Build Status](https://secure.travis-ci.org/ioquatix/teapot.svg)](http://travis-ci.org/ioquatix/teapot)
[![Code Climate](https://codeclimate.com/github/ioquatix/teapot.svg)](https://codeclimate.com/github/ioquatix/teapot)
[![Coverage Status](https://coveralls.io/repos/ioquatix/teapot/badge.svg)](https://coveralls.io/r/ioquatix/teapot)

## Installation

Ensure that you already have a working install of Ruby 2.0.0+ and run the following to install `teapot`:

	$ gem install teapot

## Usage

Teapot doesn't have a default centralised package management system but there is a canonical one for developing cross-platform C++ applications. This example shows how to use this framework.

Firstly, create your project by running:

	$ teapot create "My Project" https://github.com/kurocha platforms unit-test
	$ cd my-project

You will be asked to merge the project file. At present, merge tools are not very good and thus you may need to take a moment to review the changes. You want to keep most of the original file, but you would like to add the `define_target` blocks which are being added.

In the resulting project directory that has been created, you can see the list of dependencies:

	$ teapot list
	Package root (from ./my-project):
		#<Teapot::Configuration "my-project" visibility=private>
			- references root from ./my-project
			- clones platforms from https://github.com/kurocha/platforms
			- clones unit-test from https://github.com/kurocha/unit-test
			- clones variants from https://github.com/kurocha/variants
			- clones platform-darwin-osx from https://github.com/kurocha/platform-darwin-osx
			- clones platform-darwin-ios from https://github.com/kurocha/platform-darwin-ios
			- clones build-clang from https://github.com/kurocha/build-clang
			- clones build-darwin from https://github.com/kurocha/build-darwin
	Package platforms (from ./my-project/teapot/packages/my-project/platforms):
		#<Teapot::Configuration "platforms" visibility=public>
			- clones platforms from https://github.com/kurocha/platforms
			- references variants from ./my-project/teapot/packages/platforms/variants
			- references platform-darwin-osx from ./my-project/teapot/packages/platforms/platform-darwin-osx
			- references platform-darwin-ios from ./my-project/teapot/packages/platforms/platform-darwin-ios
			- references build-clang from ./my-project/teapot/packages/platforms/build-clang
			- references build-darwin from ./my-project/teapot/packages/platforms/build-darwin
	Package unit-test (from ./my-project/teapot/packages/my-project/unit-test):
		#<Teapot::Project "Unit Test">
			- License: MIT License
			- Version: 0.1.0
			- Author: Samuel Williams
		#<Teapot::Target "unit-test">
			- depends on "Build/Files"
			- depends on "Build/Clang"
			- depends on :platform
			- depends on "Language/C++11"
			- provides "Library/UnitTest"
		#<Teapot::Target "unit-test-tests">
			- depends on "Build/Clang"
			- depends on :platform
			- depends on "Language/C++11"
			- depends on "Library/UnitTest"
			- provides "Test/UnitTest"
		#<Teapot::Generator "Unit/Test">
			Generates a basic test file in the project.
			
			usage: teapot generate Unit/Test Namespace::TestName
		#<Teapot::Configuration "local" visibility=private>
			- clones unit-test from https://github.com/kurocha/unit-test
			- clones platforms from https://github.com/dream-framework/platforms
			- clones build-files from https://github.com/dream-framework/build-files
			- clones variants from https://github.com/dream-framework/variants
			- clones platform-darwin-osx from https://github.com/dream-framework/platform-darwin-osx
			- clones platform-darwin-ios from https://github.com/dream-framework/platform-darwin-ios
			- clones build-clang from https://github.com/dream-framework/build-clang
			- clones build-darwin from https://github.com/dream-framework/build-darwin
		#<Teapot::Configuration "travis" visibility=private>
			- clones unit-test from https://github.com/kurocha/unit-test
			- clones platforms from https://github.com/dream-framework/platforms
			- clones build-files from https://github.com/dream-framework/build-files
			- clones variants from https://github.com/dream-framework/variants
			- clones platform-darwin-osx from https://github.com/dream-framework/platform-darwin-osx
			- clones platform-darwin-ios from https://github.com/dream-framework/platform-darwin-ios
			- clones build-clang from https://github.com/dream-framework/build-clang
			- clones build-darwin from https://github.com/dream-framework/build-darwin
	Package variants (from ./my-project/teapot/packages/my-project/variants):
		#<Teapot::Target "variant-generic">
			- provides "Variant/generic"
		#<Teapot::Target "variant-debug">
			- depends on "Variant/generic"
			- provides "Variant/debug"
			- provides :variant => ["Variant/debug"]
		#<Teapot::Target "variant-release">
			- depends on "Variant/generic"
			- provides "Variant/release"
			- provides :variant => ["Variant/release"]
	Package platform-darwin-osx (from ./my-project/teapot/packages/my-project/platform-darwin-osx):
		#<Teapot::Target "platform-darwin-osx">
			- depends on :variant
			- provides "Platform/darwin-osx"
			- provides :platform => ["Platform/darwin-osx"]
			- provides "Language/C++11"
			- provides "Library/OpenGL"
			- provides "Library/OpenAL"
			- provides "Library/z"
			- provides "Library/bz2"
	Package platform-darwin-ios (from ./my-project/teapot/packages/my-project/platform-darwin-ios):
		#<Teapot::Target "platform-darwin-ios">
			- depends on :variant
			- provides "Platform/darwin-ios"
			- provides :platform => ["Platform/darwin-ios"]
			- provides "Language/C++11"
			- provides "Library/OpenGLES"
			- provides "Library/OpenGL" => ["Library/OpenGLES"]
			- provides "Library/OpenAL"
			- provides "Library/z"
			- provides "Library/bz2"
			- provides "Aggregate/Display"
		#<Teapot::Target "platform-darwin-ios-simulator">
			- depends on :variant
			- provides "Platform/darwin-ios-simulator"
			- provides :platform => ["Platform/darwin-ios-simulator"]
			- provides "Language/C++11"
			- provides "Library/OpenGLES"
			- provides "Library/OpenGL" => ["Library/OpenGLES"]
			- provides "Library/OpenAL"
			- provides "Library/z"
			- provides "Library/bz2"
			- provides "Aggregate/Display"
	Package build-clang (from ./my-project/teapot/packages/my-project/build-clang):
		#<Teapot::Target "build-clang">
			- depends on :linker
			- provides "Build/Clang"
			- provides "Language/C++11"
	Package build-darwin (from ./my-project/teapot/packages/my-project/build-darwin):
		#<Teapot::Target "build-darwin">
			- provides :linker => ["Build/darwin"]
			- provides "Build/darwin"
	Elapsed Time: 0.007s

To only see things exported by your current project, you can run:

	$ teapot list root

The new project doesn't define any targets so we can do that now. Add the following to `teapot.rb`:

```ruby
# Build Targets

define_target "my-project-tests" do |target|
	target.build do
		run tests: 'UnitTest', source_files: target.package.path.glob("test/MyProject/**/*.cpp")
	end
	
	target.depends :platform
	target.depends "Language/C++11"
	target.depends "Library/UnitTest"
	
	target.provides "Test/MyProject"
end
```

We can now build and run unit tests (althoght there aren't any yet):

	$ teapot build Test/MyProject
	... snip ...
	[Summary] 0 passed out of 0 total

When you build, you need to specify dependencies. If you haven't specified all dependencies, they will be suggested to you.

The resulting executables and libraries will be framework dependent, but are typically located in:

	$ cd teapot/$PROJECT_NAME/platforms/$PLATFORM_NAME/bin/
	$ ./$PROJECT_NAME

### Example: Compiling TaggedFormat

	$ teapot create "Local Tagged Format" https://github.com/kurocha platforms tagged-format unit-test
	$ cd local-tagged-format
	$ teapot build Test/TaggedFormat variant-debug

You need to make sure any basic tools, e.g. compilers, system libraries, are installed correctly before building. Consult the platform and library documentation for any dependencies.

## Open Issues

- Should packages be built into a shared prefix or should they be built into unique prefixes and joined together either via install or `-L` and `-I`?
	- Relative include paths might fail to work correctly if headers are not installed into same directory.
- Should packages expose the tools required to build themselves as dependencies? e.g. should `build-cmake` as required by, say, `OpenCV`, be exposed to all who depend on `OpenCV`? Should there be a mechanism for non-public dependencies, i.e. dependencies which are not exposed to dependants? *YES - Implemented*.
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
