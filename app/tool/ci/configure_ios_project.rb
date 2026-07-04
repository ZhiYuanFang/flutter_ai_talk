#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

bundle_id = ENV.fetch('IOS_BUNDLE_ID')
widget_bundle_id = ENV.fetch('IOS_WIDGET_BUNDLE_ID', "#{bundle_id}.PangbaoWidget")
team_id = ENV.fetch('IOS_TEAM_ID')
profile_name = ENV.fetch('PROFILE_NAME')
profile_uuid = ENV['PROFILE_UUID']
widget_profile_name = ENV.fetch('WIDGET_PROFILE_NAME', profile_name)
widget_profile_uuid = ENV['WIDGET_PROFILE_UUID']
export_method = ENV.fetch('EXPORT_METHOD')

signing_identity = export_method == 'development' ? 'Apple Development' : 'Apple Distribution'
deployment_target = ENV.fetch('IOS_DEPLOYMENT_TARGET', '14.0')
project_path = File.join(Dir.pwd, 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner_target = project.targets.find { |target| target.name == 'Runner' }
abort('未找到 iOS Runner target') unless runner_target

root_object = project.root_object
root_object.development_region = 'zh-Hans'
known_regions = root_object.known_regions
known_regions << 'zh-Hans' unless known_regions.include?('zh-Hans')

def apply_manual_signing(target, team_id:, signing_identity:, profile_name:, profile_uuid:, bundle_id:, deployment_target:)
  target.build_configurations.each do |config|
    settings = config.build_settings
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
    settings['TARGETED_DEVICE_FAMILY'] = '1'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
    settings['DEVELOPMENT_TEAM'] = team_id
    settings['CODE_SIGN_STYLE'] = 'Manual'
    settings['CODE_SIGN_IDENTITY'] = signing_identity
    settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = signing_identity
    settings['CODE_SIGNING_REQUIRED'] = 'YES'
    settings['CODE_SIGNING_ALLOWED'] = 'YES'
    settings['PROVISIONING_PROFILE_SPECIFIER'] = profile_name
    settings['PROVISIONING_PROFILE'] = profile_uuid if profile_uuid && !profile_uuid.empty?
  end

  target_attributes = target.project.root_object.attributes['TargetAttributes'] ||= {}
  attrs = target_attributes[target.uuid] ||= {}
  attrs['DevelopmentTeam'] = team_id
  attrs['ProvisioningStyle'] = 'Manual'
end

apply_manual_signing(
  runner_target,
  team_id: team_id,
  signing_identity: signing_identity,
  profile_name: profile_name,
  profile_uuid: profile_uuid,
  bundle_id: bundle_id,
  deployment_target: deployment_target,
)

widget_target = project.targets.find { |target| target.name == 'PangbaoWidget' }
if widget_target
  apply_manual_signing(
    widget_target,
    team_id: team_id,
    signing_identity: signing_identity,
    profile_name: widget_profile_name,
    profile_uuid: widget_profile_uuid,
    bundle_id: widget_bundle_id,
    deployment_target: deployment_target,
  )
  puts "Configured PangbaoWidget signing for #{widget_bundle_id} profile=#{widget_profile_name}"
end

(project.targets - [runner_target, widget_target].compact).each do |target|
  next unless target.name.start_with?('Runner')

  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
  end
end

project.save
puts "Configured iOS signing for #{bundle_id} (iOS #{deployment_target}+)"
