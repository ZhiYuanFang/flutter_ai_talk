#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

bundle_id = ENV.fetch('IOS_BUNDLE_ID')
team_id = ENV.fetch('IOS_TEAM_ID')
profile_name = ENV.fetch('PROFILE_NAME')
profile_uuid = ENV['PROFILE_UUID']
export_method = ENV.fetch('EXPORT_METHOD')

signing_identity = export_method == 'development' ? 'Apple Development' : 'Apple Distribution'
project_path = File.join(Dir.pwd, 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |target| target.name == 'Runner' }
abort('未找到 iOS Runner target') unless runner_target

runner_target.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
  settings['DEVELOPMENT_TEAM'] = team_id
  settings['CODE_SIGN_STYLE'] = 'Manual'
  settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = signing_identity
  settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
  settings['PROVISIONING_PROFILE'] = profile_uuid if profile_uuid && !profile_uuid.empty?
end

target_attributes = project.root_object.attributes['TargetAttributes'] ||= {}
runner_attributes = target_attributes[runner_target.uuid] ||= {}
runner_attributes['DevelopmentTeam'] = team_id
runner_attributes['ProvisioningStyle'] = 'Manual'

(project.targets - [runner_target]).each do |target|
  next unless target.name.start_with?('Runner')

  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  end
end

project.save
puts "Configured iOS signing for #{bundle_id}"
