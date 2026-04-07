# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "samovar"
require "build/name"

require_relative "fetch"
require "rugged"

require "build/uri"

module Teapot
	module Command
		# A command to clone a remote repository and fetch all dependencies.
		class Clone < Samovar::Command
			self.description = "Clone a remote repository and fetch all dependencies."
			
			one :source, "The source repository to clone.", required: true
			
			# Clone packages from their remote repositories using git, parallelizing the operations.
			def call
				logger = parent.logger
				
				name = File.basename(::Build::URI[@source].path, ".git")
				
				nested = parent["--root", parent.options[:root] || name]
				root = nested.root
				
				if root.exist?
					raise ArgumentError.new("#{root} already exists!")
				end
				
				logger.info "Cloning #{@source} to #{root}..."
				_repository = Rugged::Repository.clone_at(@source, root.to_s, credentials: self.method(:credentials))
				
				# Fetch the initial packages:
				Fetch[parent: nested].call
			end
			
			# Provide credentials for repository authentication.
			# @parameter url [String] The repository URL.
			# @parameter username [String] The username.
			# @parameter types [Array] The credential types allowed.
			# @returns [Rugged::Credentials] The credentials object.
			def credentials(url, username, types)
				# We should prompt for username/password if required...
				return Rugged::Credentials::SshKeyFromAgent.new(username: username)
			end
		end
	end
end
