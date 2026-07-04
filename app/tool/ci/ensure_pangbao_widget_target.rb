#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

IOS_DIR = File.expand_path('../../ios', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
WIDGET_NAME = 'PangbaoWidget'
WIDGET_DIR = File.join(IOS_DIR, WIDGET_NAME)
DEPLOYMENT_TARGET = ENV.fetch('IOS_DEPLOYMENT_TARGET', '14.0')
MAIN_BUNDLE_ID = ENV.fetch('IOS_BUNDLE_ID', 'com.fzy.pangbaoApp')
WIDGET_BUNDLE_ID = ENV.fetch('IOS_WIDGET_BUNDLE_ID', "#{MAIN_BUNDLE_ID}.PangbaoWidget")

abort("缺少 #{PROJECT_PATH}") unless File.directory?(PROJECT_PATH)
abort("缺少 #{WIDGET_DIR}/PangbaoWidget.swift") unless File.exist?(File.join(WIDGET_DIR, 'PangbaoWidget.swift'))

project = Xcodeproj::Project.open(PROJECT_PATH)
if project.targets.any? { |t| t.name == WIDGET_NAME }
  puts "PangbaoWidget target 已存在，跳过"
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' }
abort('未找到 Runner target') unless runner

widget_group = project.main_group.groups.find { |g| g.display_name == WIDGET_NAME || g.path == WIDGET_NAME }
widget_group ||= project.main_group.new_group(WIDGET_NAME, WIDGET_NAME)

swift_ref = widget_group.files.find { |f| f.path == 'PangbaoWidget.swift' } ||
            widget_group.new_file('PangbaoWidget.swift')
widget_group.new_file('Info.plist') unless widget_group.files.any? { |f| f.path == 'Info.plist' }
widget_group.new_file('PangbaoWidget.entitlements') unless widget_group.files.any? {
  |f| f.path == 'PangbaoWidget.entitlements'
}

widget_target = project.new_target(:app_extension, WIDGET_NAME, :ios, DEPLOYMENT_TARGET)
widget_target.add_file_references([swift_ref])

widget_target.build_configurations.each do |config|
  settings = config.build_settings
  settings['INFOPLIST_FILE'] = "#{WIDGET_NAME}/Info.plist"
  settings['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_NAME}/PangbaoWidget.entitlements"
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SWIFT_VERSION'] = '5.0'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  settings['TARGETED_DEVICE_FAMILY'] = '1'
  settings['SKIP_INSTALL'] = 'YES'
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks',
  ]
end

embed_phase = runner.copy_files_build_phases.find { |p|
  p.name == 'Embed Foundation Extensions' || p.name == 'Embed App Extensions'
}
unless embed_phase
  embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_phase.name = 'Embed Foundation Extensions'
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << embed_phase
end

appex_ref = widget_target.product_reference
build_file = embed_phase.add_file_reference(appex_ref)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

runner.add_dependency(widget_target)

target_attributes = project.root_object.attributes['TargetAttributes'] ||= {}
team_id = ENV['IOS_TEAM_ID']
if team_id && !team_id.empty?
  target_attributes[widget_target.uuid] = {
    'DevelopmentTeam' => team_id,
    'ProvisioningStyle' => 'Manual',
  }
end

project.save
puts "已添加 PangbaoWidget Extension target（#{WIDGET_BUNDLE_ID}）并嵌入 Runner"
