# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../controller'
require_relative '../repository'

module Teapot
	class Controller
		def fetch(**options)
			resolved = Set.new
			configuration = context.configuration
			unresolved = context.unresolved(configuration.packages)
			
			while true
				configuration.packages.each do |package|
					next if resolved.include? package
				
					fetch_package(context, configuration, package, **options)
				
					# We are done with this package, don't try to process it again:
					resolved << package
				end
			
				# Resolve any/all imports:
				configuration.materialize
			
				previously_unresolved = unresolved
				unresolved = context.unresolved(configuration.packages)
			
				# No additional packages were resolved, we have reached a fixed point:
				if previously_unresolved == unresolved || unresolved.count == 0
					break
				end
			end
		
			if unresolved.count > 0
				log "Could not fetch all packages!".color(:red)
				unresolved.each do |package|
					log "\t#{package}".color(:red)
				end
			else
				log "Completed fetch successfully.".color(:green)
			end
		end
		
		private

		def current_commit(package)
			IO.popen(['git', '--git-dir', (package.path + '.git').to_s, 'rev-parse', '--verify', 'HEAD']) do |io|
				io.read.chomp!
			end
		end
		
		def current_branch(package)
			IO.popen(['git', '--git-dir', (package.path + '.git').to_s, 'rev-parse', '--abbrev-ref', 'HEAD']) do |io|
				io.read.chomp!
			end		
		end
		
		def current_metadata(package)
			{
				branch: current_branch(package),
				commit: current_commit(package)
			}
		end
		
		def link_local_package(context, configuration, package)
			log "Linking local #{package}...".color(:cyan)
	
			local_path = context.root + package.options[:local]

			# Where we are going to put the package:
			destination_path = package.path

			# Make the top level directory if required:
			destination_path.dirname.create

			unless destination_path.exist?
				destination_path.make_symlink(local_path)
			end
		end

		def clone_or_pull_package(context, configuration, package, package_lock)
			log "Fetching #{package}...".color(:cyan)

			# Where we are going to put the package:
			destination_path = package.path

			base_uri = URI(package.options[:source].to_s)

			if base_uri.scheme == nil || base_uri.scheme == 'file'
				base_uri = URI "file://" + File.expand_path(base_uri.path, context.root) + "/"
			end

			branch = package.options.fetch(:branch, 'master')

			if package_lock
				log "Package locked to commit: #{package_lock[:branch]}/#{package_lock[:commit]}"

				branch = package_lock[:branch]
			end

			commit = package_lock ? package_lock[:commit] : nil

			unless destination_path.exist?
				log "Cloning package at path #{destination_path} ...".color(:cyan)
		
				begin
					external_url = package.external_url(context.root)

					Repository.new(destination_path).clone!(external_url, branch, commit)
				rescue
					log "Failed to clone #{external_url}...".color(:red)

					raise
				end
			else
				log "Updating package at path #{destination_path} ...".color(:cyan)

				commit = package_lock ? package_lock[:commit] : nil
				Repository.new(destination_path).update(branch, commit)
			end
		end

		def fetch_package(context, configuration, package, update: false, local: false)
			if package.local?
				link_local_package(context, configuration, package)
			elsif package.external?
				lock_store = configuration.lock_store
				
				# If we are updating, don't bother reading the current branch/commit details.
				unless update
					package_lock = lock_store.transaction(true){|store| store[package.name]}
				end
				
				unless local
					clone_or_pull_package(context, configuration, package, package_lock)
				end
				
				# Lock the package, unless it was already locked:
				unless package_lock
					metadata = current_metadata(package)
					
					lock_store.transaction do |store|
						store_metadata = store[package.name]
						
						if store_metadata.nil? or store_metadata[:commit] != metadata[:commit]
							log("Updating lockfile for package #{package.name}: #{metadata[:commit]}...")
							store[package.name] = metadata
						end
					end
				end
			end
		end
	end
end
