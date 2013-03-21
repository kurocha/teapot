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

	$ teapot init $PROJECT_NAME https://github.com/dream-framework project

In the resulting project directory (`$PROJECT_NAME`/) that has been created, you can see the list of dependencies:

	$ cd $PROJECT_NAME
	$ teapot list
	Package project:
		<Teapot::Generator "project">
			Generates a basic project for use with the dream-framework.
		<Teapot::Generator "class">
			Generates a basic class file in the project.
	Package root:
		<Teapot::Configuration "foobar">
	Elapsed Time: (0.000795)

To build your project:

	$ teapot build

The resulting libraries will be framework dependent, but are typically located in

	$ cd teapot/$PROJECT_NAME/platforms/$PLATFORM_NAME/bin/
	$ ./$PROJECT_NAME

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
