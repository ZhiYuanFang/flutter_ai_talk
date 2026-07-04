#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

IOS_DIR = File.expand_path('../../ios', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
SCHEME_PATH = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
WIDGET_NAME = 'PangbaoWidget'
WIDGET_DIR = File.join(IOS_DIR, WIDGET_NAME)
DEPLOYMENT_TARGET = ENV.fetch('IOS_DEPLOYMENT_TARGET', '14.0')
MAIN_BUNDLE_ID = ENV.fetch('IOS_BUNDLE_ID', 'com.fzy.pangbaoApp')
WIDGET_BUNDLE_ID = ENV.fetch('IOS_WIDGET_BUNDLE_ID', "#{MAIN_BUNDLE_ID}.PangbaoWidget")

abort("缺少 #{PROJECT_PATH}") unless File.directory?(PROJECT_PATH)
abort("缺少 #{WIDGET_DIR}/PangbaoWidget.swift") unless File.exist?(File.join(WIDGET_DIR, 'PangbaoWidget.swift'))

def add_system_framework(target, project, name)
  frameworks_group = project.frameworks_group
  ref = frameworks_group.files.find { |f| f.path&.end_with?("#{name}.framework") }
  unless ref
    ref = frameworks_group.new_reference("System/Library/Frameworks/#{name}.framework")
    ref.name = "#{name}.framework"
    ref.source_tree = 'SDKROOT'
  end
  return if target.frameworks_build_phase.files_references.include?(ref)

  target.frameworks_build_phase.add_file_reference(ref)
end

def apply_widget_build_settings(widget_target, runner_target)
  runner_by_name = runner_target.build_configuration_list.build_configurations.index_by(&:name)
  widget_target.build_configuration_list.build_configurations.each do |config|
    runner_config = runner_by_name[config.name]
    config.base_configuration_reference = runner_config.base_configuration_reference if runner_config&.base_configuration_reference

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
    settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
    settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    settings['LD_RUNPATH_SEARCH_PATHS'] = [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks',
    ]
  end
end

def ensure_embed_extension_phase(runner, project, widget_target)
  embed_phase = runner.copy_files_build_phases.find { |p|
    p.name == 'Embed Foundation Extensions' || p.name == 'Embed App Extensions'
  }
  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = 'Embed Foundation Extensions'
    embed_phase.symbol_dst_subfolder_spec = :plug_ins
    runner.build_phases << embed_phase
  end

  # 放到最后，确保在 [CP] Embed Pods Frameworks 之后执行
  runner.build_phases.delete(embed_phase)
  runner.build_phases << embed_phase

  appex_ref = widget_target.product_reference
  existing = embed_phase.files.find { |f| f.file_ref == appex_ref }
  build_file = existing || embed_phase.add_file_reference(appex_ref)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy', 'CodeSignOnCopy'] }
end

def ensure_scheme_builds_widget(project, widget_target)
  return unless File.exist?(SCHEME_PATH)

  scheme = Xcodeproj::XCScheme.new(SCHEME_PATH)
  widget_uuid = widget_target.uuid
  already_listed = scheme.build_action.entries.any? do |entry|
    entry.buildable_references.any? { |ref| ref.target_uuid == widget_uuid }
  end
  return if already_listed

  entry = Xcodeproj::XCScheme::BuildAction::Entry.new
  entry.build_for_archiving = true
  entry.build_for_running = true
  entry.build_for_profiling = true
  entry.build_for_testing = true
  entry.build_for_analyzing = true
  entry.buildable_references << Xcodeproj::XCScheme::BuildableReference.new(project, widget_target)
  scheme.build_action.entries << entry
  scheme.save!
  puts 'Runner.xcscheme: 已加入 PangbaoWidget build 条目'
end

def apply_team_attributes(project, widget_target)
  team_id = ENV['IOS_TEAM_ID']
  return if team_id.nil? || team_id.empty?

  target_attributes = project.root_object.attributes['TargetAttributes'] ||= {}
  target_attributes[widget_target.uuid] = {
    'DevelopmentTeam' => team_id,
    'ProvisioningStyle' => 'Manual',
  }
end

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
abort('未找到 Runner target') unless runner

widget_target = project.targets.find { |t| t.name == WIDGET_NAME }
created = false

unless widget_target
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
  runner.add_dependency(widget_target)
  created = true
end

add_system_framework(widget_target, project, 'WidgetKit')
add_system_framework(widget_target, project, 'SwiftUI')
apply_widget_build_settings(widget_target, runner)
ensure_embed_extension_phase(runner, project, widget_target)
apply_team_attributes(project, widget_target)
ensure_scheme_builds_widget(project, widget_target)

project.save
if created
  puts "已添加 PangbaoWidget Extension target（#{WIDGET_BUNDLE_ID}）并嵌入 Runner"
else
  puts "PangbaoWidget target 已存在，已补全 Flutter 配置 / embed / scheme"
end
