require 'plist'

module DistllAppGenerator
  module Assets
    def self.download_resource url
      DistllAppGenerator::green "Downloading url " + url
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      request = Net::HTTP::Get.new(uri.request_uri)
      return http.start { |http| http.request request }
    end

    def self.download_content directory, base_url, asset_name
      contents_url = base_url + '/' + asset_name + '/contents.js'
      contents_response = self.download_resource contents_url
      if contents_response.code == "200"
        File.open(directory+'/Contents.json', 'w') { |file| file.write(contents_response.body) }

        result = JSON.parse(contents_response.body)

        result['images'].each do |image|

          image_url = base_url + '/' + asset_name + '/' + File.basename(image['filename'], ".*")
          image_response = self.download_resource image_url
          if image_response.code == "200"
            File.open(directory+'/'+image['filename'], 'w') { |file| file.write(image_response.body) }
          else
            DistllAppGenerator::red "Error downloading Image: " + image['filename']
          end
        end

      else
        DistllAppGenerator::red "Error downloading Contents.json"
      end
    end

    def self.create_asset_catalog project, target, assets
      main_target = project.targets.first
      main_plist = DistllAppGenerator::get_main_plist_path(main_target)

      # Assets directory
      assets_directory = main_plist.split('/')[0] + '/' + target + '/AppIcons-' + target + '.xcassets'
      FileUtils::mkdir_p assets_directory

      # Contents.json file
      json_file = "{\"info\" : {\"version\" : 1,\"author\" : \"xcode\"}}"
      filename = File.join(assets_directory, 'Contents.json')
      File.open(filename, 'w') { |file|
        file.write(json_file)
      }

      # Icons
      icons_directory = assets_directory + '/AppIcon'+target+'.appiconset'
      FileUtils::mkdir_p icons_directory
      download_content(icons_directory, assets, 'icon')

      # Top banner
      banner_directory = assets_directory + '/banner.imageset'
      FileUtils::mkdir_p banner_directory
      download_content(banner_directory, assets, 'top')

      # Launch Image
      launch_directory = assets_directory + '/LaunchImage'+target+'.launchimage'
      FileUtils::mkdir_p launch_directory
      download_content(launch_directory, assets, 'launch')

      # Login background
      #login_directory = assets_directory + '/login_background.imageset'
      #FileUtils::mkdir_p login_directory
      #download_content(login_logo_directory, assets, 'login_background')

      # Login logo
      login_logo_directory = assets_directory + '/logo.imageset'
      FileUtils::mkdir_p login_logo_directory
      download_content(login_logo_directory, assets, 'logo')

    end

    def self.create_login_video(directory, target, video)
      video_url = video
      contents_response = self.download_resource video_url
      if contents_response.code == "200"
        video_path = directory + '/Distll/Resources/Assets/Videos/' + target
        FileUtils.mkdir_p(video_path) unless File.exists?(video_path)
        File.open(video_path + "/V5.mp4", 'w') { |file| file.write(contents_response.body) }
      else
        DistllAppGenerator::red "Error downloading video"
      end
    end
  end
end
