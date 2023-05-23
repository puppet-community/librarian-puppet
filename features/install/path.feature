Feature: cli/install/path
  Puppet librarian needs to install modules from local paths

  Scenario: Install a module with dependencies specified in a Puppetfile
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/with_puppetfile', :path => '../../features/examples/with_puppetfile'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/with_puppetfile/metadata.json" should match /"name": "librarian-with_puppetfile"/
    And the file "modules/test/metadata.json" should match /"name": "librarian-test"/

  Scenario: Install a module with recursive path dependencies
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/path_dependencies', :path => '../../features/examples/path_dependencies'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/path_dependencies/metadata.json" should match /"name": "librarian-path_dependencies"/
    And the file "modules/test/metadata.json" should match /"name": "librarian-test"/
    And a file named "modules/stdlib/metadata.json" should exist

  Scenario: Install a module with dependencies specified in a Puppetfile and metadata.json
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/with_puppetfile', :path => '../../features/examples/with_puppetfile_and_metadata_json'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/with_puppetfile/metadata.json" should match /"name": "librarian-with_puppetfile_and_metadata_json"/
    And the file "modules/test/metadata.json" should match /"name": "maestrodev-test"/

  Scenario: Install a module from path without version
    Given a file named "Puppetfile" with:
    """
    forge "https://forgeapi.puppetlabs.com"

    mod 'test', :path => '../../features/examples/dependency_without_version'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/test/metadata.json" should match /"version": "0\.0\.1"/
    And a file named "modules/stdlib/metadata.json" should exist

  @spaces
  Scenario: Installing a module in a path with spaces
    Given a file named "Puppetfile" with:
    """
    mod 'librarian/test', :path => '../../features/examples/test'
    mod 'puppetlabs/stdlib', :git => 'https://github.com/puppetlabs/puppetlabs-stdlib', :ref => 'main'
    """
    When I successfully run `librarian-puppet install`
    And the file "modules/test/metadata.json" should match /"name": "librarian-test"/
