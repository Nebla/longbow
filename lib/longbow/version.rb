$:.push File.expand_path('../', __FILE__)
require 'colors'

module Longbow
  VERSION = '0.1.0'

  def self.check_for_newer_version
    unless Gem.latest_version_for('longbow').to_s == VERSION
      Longbow::purple "\n  A newer version of longbow is available. Run '[sudo] gem update longbow'."
    end
  end
end
