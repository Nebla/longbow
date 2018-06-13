$:.push File.expand_path('../../', __FILE__)
require 'fileutils'
require 'distll-app-generator'

command :install do |c|
  c.syntax = 'distll-app-generator install [options]'
  c.summary = 'Creates the required files in your directory.'
  c.description = ''

  c.option '-a', '--appname APP_NAME', 'The new app name'
  c.option '-b', '--bundleid BUNDLE_ID', 'The bundle id for the new app'
  c.option '-x', '--brandid BRAND_ID', 'The brand id of the new app'
  c.option '-c', '--bannercolor BANNER_COLOR', 'The banner color for the new app in hexa format [ffffff]'
  c.option '-s', '--scheme URL_Scheme/Facebook_suffix', 'The URL schemes or facebook suffix that his app can handle'
  c.option '-i', '--itunes ITUNES_URL', 'The app itunes url'
  c.option '-m', '--mixpanel MIXPANEL_TOKEN', 'The partner mixpanel token'
  c.option '-B', '--branchiokey BRANCHIO_KEY', 'The branch io public key'
  c.option '-D', '--branchiodomain BRANCHIO_DOMAIN', 'The branch io domain'
  c.option '-L', '--branchiolink BRANCHIO_LINK', 'The branch io link'

  c.option '', '--video VIDEO_URL', 'The url where the login video is downloaded'

  c.option '', '--theme THEME_JSON_FILE', 'The json file name with the theme configuration for this brand [ClassicTheme]'
  c.option '', '--typekit TYPEKIT_NAME', 'The json file name for the typekit [Swiss]'
  c.option '', '--iconset ICON_SET_NAME', 'The icon set name [Basis]'

  c.option '-d', '--dark', 'Set this flag if you prefer a dark status bar'

  c.action do |args, options|

    # Set Up
    @directory = Dir.pwd
    @json_path = @directory + '/distll-app-generator.json'

    correct = true

    @app_name = options.appname
    correct = check_param(@app_name,"APP NAME")

    @bundle_id = options.bundleid
    correct = check_param(@bundle_id,"BUNDLE ID")

    @brand_id = options.brandid
    correct = check_param(@brand_id,"BRAND ID")

    @itunes_url = options.itunes
    correct = check_param(@itunes_url,"ITUNES URL")

    @video_url = options.video
    correct = check_param(@video_url,"VIDEO URL")

    @mixpanel_token = options.mixpanel
    correct = check_param(@mixpanel_token,"MIXPANEL TOKEN")

    @branchio_key = options.branchiokey
    correct = check_param(@branch_key,"BRANCHIO KEY")

    @branchio_domain = options.branchiodomain
    correct = check_param(@branchio_domain,"BRANCHIO DOMAIN")

    @branchio_link = options.branchiolink
    correct = check_param(@branchio_link,"BRANCHIO LINK")

    unless correct
      DistllAppGenerator::red 'Some parameters are missing. Fix them and run the script again'
      DistllAppGenerator::red 'Run: distll-app-generator install --help'
      exit -1
    end

    @theme_file = options.theme ? options.theme : 'ClassicTheme'
    @type_kit = options.typekit ? options.typekit : 'Swiss'
    @icon_set = options.iconset ? options.iconset : 'Basis'

    @url_scheme = options.scheme ? options.scheme : @app_name.delete(' ').downcase
    @banner_color = options.bannercolor ? options.bannercolor : 'ffffff'

    @light_status = options.dark ? 'false' : 'true'

    @file_string = '{
      "targets": [{
          "name": "'+@app_name+'",
          "icon_url": "https://somewhere.net/img.png",
          "launch_phone_p_url": "https://somewhere.net/img2.png",
          "info_plist": {
              "BannerColor":"'+@banner_color+'",
              "LightStatus":'+@light_status+',
              "CFBundleIdentifier": "'+@bundle_id+'",
              "BrandAppIdentifier": "'+@brand_id+'",
              "NSCameraUsageDescription": "The app needs access to the camera to update your user profile image.",
              "NSPhotoLibraryUsageDescription": "The app needs access to your photos to update your user profile image.",
              "CFBundleURLTypes": [{
                                   "CFBundleURLSchemes": [
                                                    "fb375100839351264'+@url_scheme+'",
                                                    "distll-'+@url_scheme+'"
                                                   ]
                        }],

              "DistllGlobalMixpanelToken": "8b0cf354b40298bcd3be52dc9e69c808",
              "DistllPartnerMixpanelToken": "'+@mixpanel_token+'",
              "FacebookAppID": "375100839351264",
              "FacebookDisplayName": "Powered By '+@app_name+'",
              "FacebookUrlSchemeSuffix": "'+@url_scheme+'",
              "Group": "com.distll",
              "ShareItunesLink": "'+@itunes_url+'",
              "CFBundleDisplayName":"'+@app_name+'",
              "Theme":"'+@theme_file+'",
              "TypeKit":"'+@type_kit+'",
              "IconSet":"'+@icon_set+'",
              "LoginVideoURL":"'+@video_url+'",
              "branch_app_domain":"'+@branchio_domain+'",
              "branch_key":"'+@branchio_key+'",
              "BranchLink":"'+@branchio_link+'"
          },
          "assets_url": "https://adminiu-media.s3.amazonaws.com/brand_images/'+@brand_id+'",
          "create_dir_for_plist": true
      }],
      "global_info_keys": {
      },
      "devices": ["iPhone"]
    }'

    DistllAppGenerator::purple @file_string

    # Install
    if File.exist?(@json_path)
      DistllAppGenerator::red 'distll-app-generator.json already exists at ' + @json_path
    else
      File.open(@json_path, 'w') do |f|
        f.write(@file_string)
      end
      DistllAppGenerator::green 'distll-app-generator.json created' unless $nolog
    end
  end
end

def check_param(param, message)
  unless param
    DistllAppGenerator::red message + ' is missing'
    return false
  end
  true
end
