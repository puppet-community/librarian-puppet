Feature: cli/update
  Puppet librarian needs to update modules properly

  Scenario: Updating a module with no Puppetfile and with metadata.json
    Given a file named "metadata.json" with:
    """
    {
      "name": "random name",
      "dependencies": [
        {
          "name": "puppetlabs/stdlib",
          "version_requirement": "3.1.x"
        }
      ]
    }
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update puppetlabs/stdlib`
    Then the exit status should be 0
    And the file "Puppetfile" should not exist
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module with no Puppetfile and with Modulefile
    Given a file named "Modulefile" with:
    """
    name "random name"
    dependency "puppetlabs/stdlib", "3.1.x"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update puppetlabs/stdlib`
    Then the exit status should be 0
    And the file "Puppetfile" should not exist
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/Modulefile" should match /name *'puppetlabs-stdlib'/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update puppetlabs-stdlib`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module using organization/module
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update --verbose puppetlabs/stdlib`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should match /puppetlabs.stdlib \(3\.1\.1\)/
    And the file "modules/stdlib/metadata.json" should match /"name": "puppetlabs-stdlib"/
    And the file "modules/stdlib/Modulefile" should match /version *'3\.1\.1'/

  Scenario: Updating a module from git with a branch ref
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod "puppetlabs-stdlib",
      :git => "https://github.com/puppetlabs/puppetlabs-stdlib.git", :ref => "3.2.x"
    """
    And a file named "Puppetfile.lock" with:
    """
    GIT
      remote: https://github.com/puppetlabs/puppetlabs-stdlib.git
      ref: 3.2.x
      sha: 326a8fd801ecba11005189c10ca8749872ef6577
      specs:
        puppetlabs-stdlib (3.2.1)

    DEPENDENCIES
      puppetlabs-stdlib (>= 0)
    """
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the git revision of module "stdlib" should be "326a8fd801ecba11005189c10ca8749872ef6577"
    When I run `librarian-puppet update`
    Then the exit status should be 0
    And the git revision of module "stdlib" should be "c0b5ce3b015db9f50d486040c16d8de56c6b4991"

  Scenario: Updating a module with invalid versions in git
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod "apache",
      :git => "https://github.com/puppetlabs/puppetlabs-apache.git", :ref => "0.5.0-rc1"
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/firewall (0.0.4)
        puppetlabs/stdlib (3.2.0)

    GIT
      remote: https://github.com/puppetlabs/puppetlabs-apache.git
      ref: 0.5.0-rc1
      sha: 94ebca3aaaf2144a7b9ce7ca6a13837ec48a7e2a
      specs:
        apache ()
          puppetlabs/firewall (>= 0.0.4)
          puppetlabs/stdlib (>= 2.2.1)

    DEPENDENCIES
      apache (>= 0)
    """
    When I run `librarian-puppet update apache`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should match /sha: d81999533af54a6fe510575d3b143308184a5005/
    And the file "modules/apache/Modulefile" should match /name *'puppetlabs-apache'/
    And the file "modules/apache/Modulefile" should match /version *'0\.5\.0-rc1'/

  Scenario: Updating a module that is not in the Puppetfile
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod 'puppetlabs/stdlib', '3.1.x'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        puppetlabs/stdlib (3.1.0)

    DEPENDENCIES
      puppetlabs/stdlib (~> 3.0)
    """
    When I run `librarian-puppet update stdlib`
    Then the exit status should be 1
    And the output should contain "Unable to find module stdlib"

  Scenario: Updating a module to a .10 release to ensure versions are correctly ordered
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod 'maestrodev/test'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        maestrodev/test (1.0.2)

    DEPENDENCIES
      maestrodev/test (>= 0)
    """
    When I run `librarian-puppet update --verbose`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should match /maestrodev.test \(1\.0\.[1-9][0-9]\)/
    And the file "modules/test/Modulefile" should contain "name 'maestrodev-test'"
    And the file "modules/test/Modulefile" should match /version '1\.0\.[1-9][0-9]'/

  Scenario: Updating a forge module with the rsync configuration
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod 'maestrodev/test'
    """
    And a file named "Puppetfile.lock" with:
    """
    FORGE
      remote: https://forge.puppet.com
      specs:
        maestrodev/test (1.0.2)

    DEPENDENCIES
      maestrodev/test (>= 0)
      """
    And a file named ".librarian/puppet/config" with:
    """
    ---
    LIBRARIAN_PUPPET_RSYNC: 'true'
    """
    When I run `librarian-puppet config`
    Then the exit status should be 0
    And the output should contain "rsync: true"
    When I run `librarian-puppet update --verbose`
    Then the exit status should be 0
    And a directory named "modules/test" should exist
    And the file "modules/test" should have an inode and ctime
    When I run `librarian-puppet update --verbose`
    Then the exit status should be 0
    And a directory named "modules/test" should exist
    And the file "modules/test" should have the same inode and ctime as before

  @announce
  Scenario: Updating a git module with the rsync configuration
    Given a file named "Puppetfile" with:
    """
    forge "https://forge.puppet.com"

    mod "puppetlabs-stdlib",
      :git => "https://github.com/puppetlabs/puppetlabs-stdlib.git", :ref => "3.2.x"
    """
    And a file named "Puppetfile.lock" with:
    """
    GIT
      remote: https://github.com/puppetlabs/puppetlabs-stdlib.git
      ref: 3.2.x
      sha: 326a8fd801ecba11005189c10ca8749872ef6577
      specs:
        puppetlabs-stdlib (3.2.1)

    DEPENDENCIES
      puppetlabs-stdlib (>= 0)
    """
    And a file named ".librarian/puppet/config" with:
    """
    ---
    LIBRARIAN_PUPPET_RSYNC: 'true'
    """
    When I run `librarian-puppet config`
    Then the exit status should be 0
    And the output should contain "rsync: true"
    When I run `librarian-puppet install`
    Then the exit status should be 0
    And the file "Puppetfile.lock" should contain "326a8fd801ecba11005189c10ca8749872ef6577"
    And the git revision of module "stdlib" should be "326a8fd801ecba11005189c10ca8749872ef6577"
    And a directory named "modules/stdlib" should exist
    When I run `librarian-puppet update --verbose`
    Then the exit status should be 0
    And a directory named "modules/stdlib" should exist
    And the file "modules/stdlib" should have an inode and ctime
    And the file "Puppetfile.lock" should contain "c0b5ce3b015db9f50d486040c16d8de56c6b4991"
    And the git revision of module "stdlib" should be "c0b5ce3b015db9f50d486040c16d8de56c6b4991"
    When I run `librarian-puppet update --verbose`
    Then the exit status should be 0
    And a directory named "modules/stdlib" should exist
    And the file "modules/stdlib" should have the same inode and ctime as before
    And the file "Puppetfile.lock" should contain "c0b5ce3b015db9f50d486040c16d8de56c6b4991"
    And the git revision of module "stdlib" should be "c0b5ce3b015db9f50d486040c16d8de56c6b4991"
