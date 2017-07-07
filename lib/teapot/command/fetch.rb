# Copyright, 2016, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'samovar'
require 'rugged'

module Teapot
	module Command
		class Fetch < Samovar::Command
			self.description = "Fetch remote packages according to the specified configuration."
			
			# 3 typical use cases:
			# - fetch current packages according to lockfile
			# - write current pacakges into lockfile
			# - update packages and update lockfile
			
			options do
				option '--update', "Update dependencies to the latest versions."
				option '--local', "Don't update from source, assume updated local packages."
			end
			
			def invoke(parent)
				logger = parent.logger
				context = parent.context
				
				resolved = Set.new
				configuration = context.configuration
				unresolved = context.unresolved(configuration.packages)
				
				while true
					configuration.packages.each do |package|
						next if resolved.include? package
					
						fetch_package(context, configuration, package, logger, **@options)
					
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
					logger.error "Could not fetch all packages!".color(:red)
					unresolved.each do |package|
						logger.error "\t#{package}".color(:red)
					end
				else
					logger.info "Completed fetch successfully.".color(:green)
				end
			end
			
			private
			
			def current_metadata(package)
				repository = Rugged::Repository.new(package.path.to_s)
				
				return {
					commit: repository.head.target.oid,
					branch: repository.head.name.sub(/^refs\/heads\//, '')
				}
			end
			
			def link_local_package(context, configuration, package, logger)
				logger.info "Linking local #{package}...".color(:cyan)
		
				local_path = context.root + package.options[:local]

				# Where we are going to put the package:
				destination_path = package.path

				# Make the top level directory if required:
				destination_path.dirname.create

				unless destination_path.exist?
					destination_path.make_symlink(local_path)
				end
			end

			def clone_or_pull_package(context, configuration, package, package_lock, logger)
				logger.info "Processing #{package}...".color(:cyan)

				# Where we are going to put the package:
				destination_path = package.path

				base_uri = URI(package.options[:source].to_s)

				if base_uri.scheme == nil || base_uri.scheme == 'file'
					base_uri = URI "file://" + File.expand_path(base_uri.path, context.root) + "/"
				end

				branch = package.options.fetch(:branch, 'master')

				if package_lock
					logger.info "Package locked to commit: #{package_lock[:branch]}/#{package_lock[:commit]}"

					branch = package_lock[:branch]
				end

				commit = package_lock ? package_lock[:commit] : nil

				if destination_path.exist?
					logger.info "Updating package at path #{destination_path} ...".color(:cyan)

					repository = Rugged::Repository.new(destination_path.to_s)
					repository.checkout(commit || 'origin/master')
				else
					logger.info "Cloning package at path #{destination_path} ...".color(:cyan)
					
					external_url = package.external_url(context.root)
					repository = Rugged::Repository.clone_at(external_url.to_s, destination_path.to_s, checkout_branch: branch)
					repository.checkout(commit) if commit
				end
			end

			def fetch_package(context, configuration, package, logger, update: false, local: false)
				if package.local?
					link_local_package(context, configuration, package, logger)
				elsif package.external?
					lock_store = configuration.lock_store
					
					# If we are updating, don't bother reading the current branch/commit details.
					unless update
						package_lock = lock_store.transaction(true){|store| store[package.name]}
					end
					
					unless local
						clone_or_pull_package(context, configuration, package, package_lock, logger)
					end
					
					# Lock the package, unless it was already locked:
					unless package_lock
						metadata = current_metadata(package)
						
						lock_store.transaction do |store|
							store_metadata = store[package.name]
							
							if store_metadata.nil? or store_metadata[:commit] != metadata[:commit]
								logger.info "Updating lockfile for package #{package.name}: #{metadata[:commit]}..."
								store[package.name] = metadata
							end
						end
					end
				end
			end
		end
	end
end
