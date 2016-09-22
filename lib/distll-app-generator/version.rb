$:.push File.expand_path('../', __FILE__)
require 'colors'

module DistllAppGenerator
  VERSION = '0.1.0'

  def self.check_for_newer_version
    unless Gem.latest_version_for('distll-app-generator').to_s == VERSION
      DistllAppGenerator::purple "\n  A newer version of distll-app-generator is available. Run '[sudo] gem update distll-app-generator'."
    end
  end
end
