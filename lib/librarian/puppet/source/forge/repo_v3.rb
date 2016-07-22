require 'librarian/puppet/source/forge/repo'
require 'puppet_forge'
require 'librarian/puppet/version'

module Librarian
  module Puppet
    module Source
      class Forge
        class RepoV3 < Librarian::Puppet::Source::Forge::Repo

          PuppetForge.user_agent = "librarian-puppet/#{Librarian::Puppet::VERSION}"

          def initialize(source, name)
            PuppetForge.host = source.uri.clone
            super(source, name)
          end

          def get_versions
            get_module.releases.select{|r| r.deleted_at.nil?}.map{|r| r.version}
          end

          def dependencies(version)
            array = get_release(version).metadata[:dependencies].map{|d| [d[:name], d[:version_requirement]]}
            Hash[*array.flatten(1)]
          end

          def download(name, version, path)
            if name == "#{get_module().owner.username}/#{get_module().name}"
              release = get_release(version)
            else
              # should never get here as we use one repo object for each module (to be changed in the future)
              debug { "Looking up url for #{name}@#{version}" }
              release = PuppetForge::V3::Release.find("#{name}-#{version}")
            end
            debug { "Downloading #{release.download_url} into #{path}"}
            release.download(Pathname.new(path))
          end

        private

          def get_module
            begin
              @module ||= PuppetForge::V3::Module.find(name)
            rescue Faraday::ResourceNotFound => e
              raise(Error, "Unable to find module '#{name}' on #{source}")
            end
            @module
          end

          def get_release(version)
            release = get_module.releases.find{|r| r.version == version.to_s}
            if release.nil?
              versions = get_module.releases.map{|r| r.version}
              raise Error, "Unable to find version '#{version}' for module '#{name}' on #{source} amongst #{versions}"
            end
            release
          end

        end
      end
    end
  end
end
