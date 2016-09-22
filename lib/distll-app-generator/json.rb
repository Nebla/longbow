$:.push File.expand_path('../', __FILE__)
require 'colors'
require 'open-uri'
require 'json'

module DistllAppGenerator

  def self.json_object_from_directory directory
    return nil unless directory

    # Check for distll-app-generator.json
    @json_path = directory + '/distll-app-generator.json'
    unless File.exists?(@json_path)
      DistllAppGenerator::red "\n  Couldn't find distll-app-generator.json at #{@json_path}\n"
      puts "  Run this command to install the correct files:\n  distll-app-generator install\n"
      return nil
    end

    # Create hash from distll-app-generator.json
    json_contents = File.open(@json_path).read
    return json_object_from_string json_contents
  end


  def self.json_object_from_url url
    return nil unless url
    contents = ''
    open(url) {|io| contents = io.read}
    return json_object_from_string contents
  end


  def self.json_object_from_string contents
    begin
      !!JSON.parse(contents)
    rescue
      return nil
    end

    return JSON.parse(contents)
  end


  def self.lint_json_object obj
    return false unless obj
    return false unless obj['targets']
    return true
  end

end