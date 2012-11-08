# Teapot

Teapot is a tool for managing complex cross-platform builds. It provides
advanced dependency management via the Teapot file and is supported by
the infusions ecosystem of packages and platform tooling.

## Installation

Add this line to your application's Gemfile:

    gem 'teapot'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install teapot

## Usage

Create a Teapot file in the root directory of your project:

	source "https://github.com/infusions"

	host /linux/ do
		platform "linux"
	end
	
	host /darwin/ do
		platform "darwin-osx"
	end

	package "png"
	package "freetype"
	package "vorbis"
	package "ogg"
	package "jpeg"

Then run

	$ teapot install

This will download and compile all the selected packages into the `build` directory.

### CMake ###

To use these packages in a CMake project, update your `CMakeLists.txt`:

	list(APPEND CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/build/${TEAPOT_PLATFORM}/")

Then configure like so:

	cmake path/to/src -DTEAPOT_PLATFORM=linux

### Xcode ###

To use these packages in an Xcode project, creating a custom `teapot.xcconfig` is recommended:

	TEAPOT_PLATFORM=darwin-osx
	TEAPOT_PREFIX_PATH=$(SRCROOT)/build/$(TEAPOT_PLATFORM)
	
	// Search paths:
	HEADER_SEARCH_PATHS=$(inherited) "$(TEAPOT_PREFIX_PATH)/include"
	LIBRARY_SEARCH_PATHS=$(inherited) "$(TEAPOT_PREFIX_PATH)/lib"

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
