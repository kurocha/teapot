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

require_relative 'selection'
require 'rugged'

module Teapot
	module Command
		class FetchError < StandardError
			def initialize(package, message)
				super(message)
				@package = package
			end
			
			attr :package
		end
		
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
			
			many :packages, "Only update the specified packages, or all packages if none specified."
			
			def context
				parent.context
			end
			
			def call
				selection = context.select
				
				packages = selection.configuration.packages
				
				if specified_packages = self.packages
					packages = packages.slice(specified_packages)
				end
				
				logger = parent.logger
				
				# If no additional packages were resolved, we have reached a fixed point:
				while packages.any?
					packages.each do |package|
						fetch_package(context, selection.configuration, package, logger, **@options)
					end
					
					selection = context.select
					
					# If there are no unresolved packages, we are done.
					if selection.unresolved.empty?
						break
					end
					
					packages = selection.unresolved
				end
			
				if selection.unresolved.count > 0
					logger.error(self) do |buffer|
						buffer.puts "Could not fetch all packages!"
						
						selection.unresolved.each do |package|
							buffer.puts "\t#{package}"
						end
					end
				else
					logger.info "Completed fetch successfully."
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
				logger.info "Linking local #{package}..." #.color(:cyan)
		
				local_path = context.root + package.options[:local]

				# Where we are going to put the package:
				destination_path = package.path

				# Make the top level directory if required:
				destination_path.dirname.create

				unless destination_path.exist?
					destination_path.make_symlink(local_path)
				end
			end
			
			def credentials(url, username, types)
				# We should prompt for username/password if required...
				return Rugged::Credentials::SshKeyFromAgent.new(username: username)
			end

			def clone_or_pull_package(context, configuration, package, package_lock, logger)
				logger.info "Processing #{package}..." #.color(:cyan)

				# Where we are going to put the package:
				destination_path = package.path

				base_uri = URI(package.options[:source].to_s)

				if base_uri.scheme == nil || base_uri.scheme == 'file'
					base_uri = URI "file://" + File.expand_path(base_uri.path, context.root) + "/"
				end

				branch_name = package.options[:branch]

				if package_lock
					logger.info "Package locked to commit: #{package_lock[:branch]}/#{package_lock[:commit]}"

					branch_name = package_lock[:branch]
					commit_id = package_lock[:commit]
				end

				if destination_path.exist?
					logger.info "Updating package at path #{destination_path}..."

					repository = Rugged::Repository.new(destination_path.to_s)

					# Are there uncommitted changes in the work tree?
					if repository.to_enum(:status).any?
						raise FetchError.new(package, "Uncommited local modifications")
					end
					
					repository.fetch('origin', credentials: self.method(:credentials))
					repository.checkout(branch_name) if branch_name
					
					# Essentially implement git pull:
					if commit_id
						# Lookup the named branch:
						branch = repository.branches[branch_name].resolve
					else
						# Lookup the current branch and upstream commit:
						branch = repository.branches[repository.head.name]
						commit_id = branch.upstream.target_id
					end
					
					# Reset it to the requested commit if required:
					repository.reset(commit_id, :hard)
				else
					logger.info "Cloning package at path #{destination_path}..." #.color(:cyan)
					
					external_url = package.external_url(context.root)
					
					# Clone the repository with the specified branch:
					repository = Rugged::Repository.clone_at(external_url.to_s, destination_path.to_s, checkout_branch: branch_name, credentials: self.method(:credentials))
					
					# Reset it to the requested commit if required:
					repository.reset(commit_id, :hard) if commit_id
				end
				
				# Rugged currently doesn't have good (any?) support for submodules, so we diretly invoke git here:
				if repository.submodules.any?
					system("git", "submodule", "update", "--init", "--recursive", chdir: package.path)
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
