require 'fileutils'
require 'distll-app-generator/colors'
require 'distll-app-generator/targets'
require 'distll-app-generator/images'
require 'distll-app-generator/json'
require 'json'

command :aim do |c|
  c.syntax = 'distll-app-generator aim'
  c.syntax = 'Takes screenshots for each target in your workspace or project based on a UIAutomation script.'
  c.description = ''
  c.option '-s', '--script SCRIPT', 'Script used to get the app into the proper state for each screenshot'
  c.option '-d', '--directory DIRECTORY', 'Path where the .xcodeproj or .xcworkspace file && the distll-app-generator.json file live.'
  c.option '-u', '--url URL', 'URL of a distll-app-generator formatted JSON file.'
  c.option '-n', '--name NAME', 'Name of the target to get a screenshot for.'
  c.option '-v', '--verbose', 'Output all logs from UIAutomation/xcodebuild'

  c.action do |args, options|
    # Check for newer version
    DistllAppGenerator::check_for_newer_version unless $nolog

    # Set Up
    @script = options.script ? options.script : nil
    @directory = options.directory ? options.directory : Dir.pwd
    @url = options.url ? options.url : nil
    @target_name = options.name
    @targets = []

    # Create JSON object
    if @url
      obj = DistllAppGenerator::json_object_from_url @url
    else
      obj = DistllAppGenerator::json_object_from_directory @directory
    end

    # Break if Bad
    unless obj || DistllAppGenerator::lint_json_object(obj)
      DistllAppGenerator::red "\n Invalid JSON. Please lint the file, and try again.\n"
      next
    end

    # Check for Target Name
    if @target_name
      obj['targets'].each do |t|
        @targets << t if t['name'] == @target_name
      end

      if @targets.length == 0
        DistllAppGenerator::red "\n  Couldn't find a target named #{@target_name} in the distll-app-generator.json file.\n"
        next
      end
    else
      @targets = obj['targets']
    end

    resources_path = File.dirname(__FILE__) + '/../../../resources'

    FileUtils.cp "#{resources_path}/capture.js", "capture.js"
    FileUtils.cp "#{resources_path}/config-screenshots.sh", "config-screenshots.sh"
    FileUtils.cp "#{resources_path}/ui-screen-shooter.sh", "ui-screen-shooter.sh"
    FileUtils.cp "#{resources_path}/unix_instruments.sh", "unix_instruments.sh"
    @target_names = []
    @targets.each do |t|
      @target_names << t['name']
    end
    target_string = @target_names.join(',')
    DistllAppGenerator::blue "  Beginning screenshots..."
    exec "#{resources_path}/aim.sh #{target_string} verbose" if options.verbose
    exec "#{resources_path}/aim.sh #{target_string}" if !options.verbose
  end
end
