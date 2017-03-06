$:.push File.expand_path('../../', __FILE__)
require 'fileutils'
require 'distll-app-generator/cocoapods'
require 'distll-app-generator/targets'
require 'distll-app-generator/colors'
require 'distll-app-generator/images'
require 'distll-app-generator/json'
require 'json'

command :update do |c|
  c.syntax = 'distll-app-generator update [options]'
  c.summary = 'Updates a target or all targets in your workspace or project.'
  c.description = ''
  c.option '-n', '--name NAME', 'Target name from the corresponding distll-app-generator.json file.'
  c.option '-d', '--directory DIRECTORY', 'Path where the .xcodeproj or .xcworkspace file && the distll-app-generator.json file live.'
  c.option '-u', '--url URL', 'URL of a distll-app-generator formatted JSON file.'
  c.option '-i', '--images', 'Set this flag to not recreate images in the distll-app-generator file.'

  c.action do |args, options|
    # Check for newer version
    DistllAppGenerator::check_for_newer_version unless $nolog

    # Set Up
    @target_name = options.name ? options.name : nil
    @directory = options.directory ? options.directory : Dir.pwd

    @noimages = options.images ? true : false
    @url = options.url ? options.url : nil
    @targets = []

    # Create JSON object
    if @url
      obj = DistllAppGenerator::json_object_from_url @url
    else
      obj = DistllAppGenerator::json_object_from_directory @directory
    end

    # Break if Bad
    unless obj || DistllAppGenerator::lint_json_object(obj)
      DistllAppGenerator::red "\n  Invalid JSON. Please lint the file, and try again.\n"
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

    # Begin
    @targets.each do |t|
      assets = t['assets_url']
      video = t['video_url']

      proj = DistllAppGenerator::get_project(@directory)
      return false if proj == nil
      DistllAppGenerator::Assets.create_asset_catalog(proj, t['name'], assets)
      DistllAppGenerator::Assets.create_login_video(@directory, t['name'], video)

      DistllAppGenerator::green "  Finished: #{t['name']}\n" unless $nolog
    end
  end
end
