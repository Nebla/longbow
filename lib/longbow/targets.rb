require 'xcodeproj'
require 'colors'
require 'plist'
require 'utilities'
require 'fileutils'
require 'pathname'
require 'assets'

module Longbow

  def self.add_file (file, target, current_group)
    i = current_group.new_file(File.basename(file))
    target.add_resources([i])
  end

  def self.add_files (proj, direc, current_group, target)
    Dir.glob(direc) do |item|
      next if item == '.' or item == '.DS_Store'

      if File.directory?(item)
        folder_name = File.basename(item)
        if folder_name.end_with? '.xcassets'
          self.add_file(item, target, current_group)
          return
        end
        created_group = current_group.new_group(folder_name)
        add_files(proj, "#{item}/", created_group, target)
      else
        self.add_file(item, target, current_group)
      end
    end
  end

  def self.get_project(directory)
    # Find Project File
    project_paths = []
    Dir.foreach(directory) do |fname|
      project_paths << fname if fname.include? '.xcodeproj'
    end

    # Open The Project
    return nil if project_paths.length == 0
    proj = Xcodeproj::Project.open(project_paths[0])
    return proj
  end

  def self.get_plist_relative_path(main_plist, target, create_dir_for_plist)
    base_path = main_plist.split('/')[0]
    if create_dir_for_plist
      return base_path + '/' + target + '/' + target + '-Info.plist'
    end
    base_path + '/' + target + '-Info.plist'
  end

  def self.get_plist_path(base_dir, main_plist, target, create_dir_for_plist)
    if create_dir_for_plist
      plist_directory = main_plist.split('/')[0] + '/' + target
      FileUtils::mkdir_p plist_directory
      Longbow::blue 'Created plist dir ' + plist_directory
    end
    base_dir + '/' + self.get_plist_relative_path(main_plist, target, create_dir_for_plist)
  end

  def self.delete_default_build_configs(target)
    configs_to_delete = %w(Release Debug)
    target.build_configuration_list.default_configuration_name = 'Dev'
    configs_to_delete.each do |config_name|
      index = target.build_configuration_list.build_configurations.find_index { |item|
        item.to_s == config_name
      }
      if index != nil
        target.build_configuration_list.build_configurations[index].remove_from_project
      end
    end
  end

  def self.update_target(directory, target, global_keys, info_keys, icon, launch, assets, video, create_dir_for_plist)
    unless directory && target
      Longbow::red '  Invalid parameters. Could not create/update target named: ' + target
      return false
    end

    proj = get_project(directory)
    return false if proj == nil

    # Get Main Target's Basic Info
    @target = nil
    proj.targets.each do |t|
      if t.to_s == target
        @target = t
        Longbow::blue '  ' + target + ' found.' unless $nolog
        break
      end
    end
    if @target
      Longbow::red 'Target ' + target + ' already exists.' unless $nolog
      return false
    end

    # Create Target if Necessary
    main_target = proj.targets.first
    @target = create_target(proj, directory, target, assets, video)

    main_plist = Longbow::get_main_plist_path(main_target)
    main_plist_contents = File.read(directory + '/' + main_plist)

    target_plist_path = self.get_plist_path(directory, main_plist, target, create_dir_for_plist)
    plist_text = Longbow::create_plist_from_old_plist main_plist_contents, info_keys, global_keys
    File.open(target_plist_path, 'w') do |f|
      f.write(plist_text)
    end
    Longbow::green '  - ' + target + '-Info.plist Updated.' unless $nolog


    # Add Build Settings
    @target.build_configurations.each do |b|
      # Main Settings
      main_settings = nil
      base_config = nil
      main_target.build_configurations.each do |bc|
        main_settings = bc.build_settings if bc.to_s == b.to_s
        base_config = bc.base_configuration_reference if bc.to_s == b.to_s
      end
      settings = b.build_settings

      if main_settings
        main_settings.each_key do |key|
          settings[key] = main_settings[key]
        end
      end

      # Plist & Icons
      settings['INFOPLIST_FILE'] = self.get_plist_relative_path(main_plist, target, create_dir_for_plist)
      settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon' + Longbow::stripped_text(target) if icon
      settings['ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME'] = 'LaunchImage' + Longbow::stripped_text(target) if launch
      settings['SKIP_INSTALL'] = 'NO'

      if File.exists? directory + '/Pods'
        b.base_configuration_reference = base_config
        settings['PODS_ROOT'] = '${SRCROOT}/Pods'
      end
    end

    proj.save
  end

  def self.create_scheme project_path, target
    scheme = Xcodeproj::XCScheme.new

    build_action = Xcodeproj::XCScheme::BuildAction.new
    build_action.add_entry(Xcodeproj::XCScheme::BuildAction::Entry.new(target))
    scheme.build_action = build_action
    scheme.add_build_target(target)

    launch_action = Xcodeproj::XCScheme::LaunchAction.new
    launch_action.build_configuration = 'Production'
    launch_action.buildable_product_runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new(target)
    scheme.launch_action = launch_action
    scheme.set_launch_target(target)

    archive_action = Xcodeproj::XCScheme::ArchiveAction.new
    archive_action.build_configuration = 'Production'
    scheme.archive_action = archive_action

    scheme.save_as(project_path, target.name, true)
    Longbow::green 'Create scheme for ' + target.name unless $nolog
  end

  def self.find_group (parent, name)
    index = parent.children.index { |group|
      group.path == name
    }

    return parent.children[index]
  end

  def self.create_target (project, directory, target, assets, video)
    main_target = project.targets.first
    deployment_target = main_target.deployment_target

    # Create New Target
    new_target = Xcodeproj::Project::ProjectHelper.new_target project, :application, target, :ios, deployment_target, project.products_group, 'en'
    if new_target
      self.add_build_phases_to_new_target(main_target, new_target)
      self.delete_default_build_configs(new_target)
      self.create_scheme(project.path, new_target)

      # Create asset catalog
      Longbow::Assets.create_asset_catalog(project, target, assets)
      apps_group = self.find_group(project.main_group, 'Apps')
      target_group = apps_group.new_group(target)
      target_group.set_source_tree(apps_group.source_tree)
      target_group.set_path(target)
      self.add_files(project, "Apps/#{target}/*", target_group, new_target)

      # Create login video
      Longbow::Assets.create_login_video(directory, target, video)
      distll_group = self.find_group(project.main_group, 'Distll')
      resources_group = self.find_group(distll_group, 'Resources')
      assets_group = self.find_group(resources_group, 'Assets')
      videos_group = self.find_group(assets_group, 'Videos')
      target_group = videos_group.new_group(target)
      target_group.set_source_tree(videos_group.source_tree)
      self.add_files(project, "Distll/Resources/Assets/Videos/#{target}/*", target_group, new_target)

      Longbow::blue '  ' + target + ' created.' unless $nolog
    else
      puts
      Longbow::red '  Target Creation failed for target named: ' + target
      puts
    end

    return new_target
  end

  def self.add_build_phases_to_new_target(main_target, new_target)
    main_target.build_phases.objects.each do |b|
      if b.isa == 'PBXSourcesBuildPhase'
        b.files_references.each do |f|
          new_target.source_build_phase.add_file_reference f
        end
      elsif b.isa == 'PBXFrameworksBuildPhase'
        b.files_references.each do |f|
          new_target.frameworks_build_phase.add_file_reference f
        end
      elsif b.isa == 'PBXResourcesBuildPhase'
        b.files_references.each do |f|
          #Ignore main target specific assets
          next if f.path == 'AppIcons-Distll.xcassets'
          next if f.path == 'Distll.entitlements'
          next if f.path == 'Distll-Info.plist'
          next if f.path == 'V5.mp4'
          new_target.resources_build_phase.add_file_reference f
        end
      elsif b.isa == 'PBXShellScriptBuildPh ase'
        phase = new_target.new_shell_script_build_phase(name = b.display_name)
        phase.shell_script = b.shell_script
      end
    end
  end
end