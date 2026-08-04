#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

IOS_DIR = File.expand_path('../../ios', __dir__)
PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')
SCHEME_PATH = File.join(PROJECT_PATH, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
WIDGET_NAME = 'PangbaoWidget'
WIDGET_DIR = File.join(IOS_DIR, WIDGET_NAME)
# Extension 须 17（对齐 home_widget example；否则 WidgetBackgroundIntent +
# ForegroundContinuableIntent 在 DT<17 下编不过）。主 App / Runner 仍保持工程内 14.0。
WIDGET_DEPLOYMENT_TARGET = ENV.fetch('IOS_WIDGET_DEPLOYMENT_TARGET', '17.0')
MAIN_BUNDLE_ID = ENV.fetch('IOS_BUNDLE_ID', 'com.fzy.pangbao')
WIDGET_BUNDLE_ID = ENV.fetch('IOS_WIDGET_BUNDLE_ID', "#{MAIN_BUNDLE_ID}.widget")

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

def read_pubspec_version
  path = File.expand_path('../pubspec.yaml', IOS_DIR)
  text = File.read(path)
  ver = text[/^version:\s*(\S+)/, 1] || '1.0.0+1'
  name, _, number = ver.partition('+')
  number = '1' if number.empty?
  [name.strip, number.strip]
end

def apply_widget_build_settings(widget_target, _runner_target)
  marketing_version, current_version = read_pubspec_version
  widget_target.build_configuration_list.build_configurations.each do |config|
    # Extension 不得继承 Flutter Release.xcconfig（会链接 Flutter.framework，导致 undefined symbol）
    config.base_configuration_reference = nil

    settings = config.build_settings
    settings['INFOPLIST_FILE'] = "#{WIDGET_NAME}/Info.plist"
    settings['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_NAME}/PangbaoWidget.entitlements"
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
    settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    settings['SWIFT_VERSION'] = '5.0'
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = WIDGET_DEPLOYMENT_TARGET
    settings['TARGETED_DEVICE_FAMILY'] = '1'
    settings['SKIP_INSTALL'] = 'YES'
    settings['WRAPPER_EXTENSION'] = 'appex'
    settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
    settings['MARKETING_VERSION'] = marketing_version
    settings['CURRENT_PROJECT_VERSION'] = current_version
    settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    settings['LD_RUNPATH_SEARCH_PATHS'] = [
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

  appex_ref = widget_target.product_reference
  existing = embed_phase.files.find { |f| f.file_ref == appex_ref }
  build_file = existing || embed_phase.add_file_reference(appex_ref)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }

  # Flutter #135056：Embed Foundation Extensions 必须在 Thin Binary 之前，否则 Info.plist 构建循环
  thin_phase = runner.build_phases.find { |phase|
    phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && phase.name == 'Thin Binary'
  }
  runner.build_phases.delete(embed_phase)
  if thin_phase
    runner.build_phases.insert(runner.build_phases.index(thin_phase), embed_phase)
  else
    runner.build_phases << embed_phase
  end
end

def ensure_scheme_builds_widget(_project, widget_target)
  return unless File.exist?(SCHEME_PATH)

  scheme = Xcodeproj::XCScheme.new(SCHEME_PATH)
  widget_uuid = widget_target.uuid
  before = scheme.build_action.entries.size
  scheme.build_action.entries.reject! do |entry|
    entry.buildable_references.any? { |ref| ref.target_uuid == widget_uuid }
  end
  if scheme.build_action.entries.size != before
    scheme.save!
    puts 'Runner.xcscheme: 已移除 PangbaoWidget 独立 build 条目（改由 Runner dependency 串行构建）'
  end
end

def disable_parallel_target_builds(project)
  attrs = project.root_object.attributes
  if attrs['BuildIndependentTargetsInParallel'] != 'NO'
    attrs['BuildIndependentTargetsInParallel'] = 'NO'
    puts 'Runner.xcodeproj: BuildIndependentTargetsInParallel=NO（Extension embed 需串行构建）'
  end
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

def ensure_widget_resource(widget_group, widget_target, filename)
  ref = widget_group.files.find { |f| f.path == filename }
  ref ||= widget_group.new_file(filename)
  return if widget_target.resources_build_phase.files_references.include?(ref)

  widget_target.resources_build_phase.add_file_reference(ref)
end

def ensure_source_on_target(group, target, filename)
  ref = group.files.find { |f| f.path == filename }
  ref ||= group.new_file(filename)
  return if target.source_build_phase.files_references.include?(ref)

  target.source_build_phase.add_file_reference(ref)
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

  widget_target = project.new_target(:app_extension, WIDGET_NAME, :ios, WIDGET_DEPLOYMENT_TARGET)
  widget_target.add_file_references([swift_ref])
  created = true
else
  widget_group = project.main_group.groups.find { |g| g.display_name == WIDGET_NAME || g.path == WIDGET_NAME }
  widget_group ||= project.main_group.new_group(WIDGET_NAME, WIDGET_NAME)
end

ensure_widget_resource(widget_group, widget_target, 'BrandLogo.png')

# 跳过按钮 AppIntent：Widget Extension + Runner 双 target
intent_file = 'WidgetBackgroundIntent.swift'
if File.exist?(File.join(WIDGET_DIR, intent_file))
  ensure_source_on_target(widget_group, widget_target, intent_file)
  ensure_source_on_target(widget_group, runner, intent_file)
  puts "已确保 #{intent_file} 加入 Runner 与 PangbaoWidget"
end

unless runner.dependencies.any? { |dep| dep.target == widget_target }
  runner.add_dependency(widget_target)
end

add_system_framework(widget_target, project, 'WidgetKit')
add_system_framework(widget_target, project, 'SwiftUI')
add_system_framework(widget_target, project, 'AppIntents')

# 交互「跳过」：Extension 须 SPM 链接 FlutterGeneratedPluginSwiftPackage 才能 import home_widget。
# 禁止再给 PangbaoWidget 单独 pod home_widget（会撞 Flutter-static）。
def ensure_flutter_plugin_package_on_widget(project, widget_target, runner_target)
  pkg_name = 'FlutterGeneratedPluginSwiftPackage'
  pkg_dir = File.join(IOS_DIR, 'Flutter', 'ephemeral', 'Packages', pkg_name)
  unless File.directory?(pkg_dir)
    abort(
      "缺少 #{pkg_dir}。请先 flutter config --enable-swift-package-manager && " \
      "flutter pub get && flutter build ios --config-only（勿用 CocoaPods 给 Extension 挂 home_widget）",
    )
  end

  runner_deps = runner_target.package_product_dependencies || []
  runner_dep = runner_deps.find { |d|
    (d.product_name == pkg_name) || (d.display_name == pkg_name)
  }
  abort(
    "Runner 尚未声明 SPM 产品 #{pkg_name}。请确认已启用 Swift Package Manager 并完成 " \
    "`flutter build ios --config-only`。",
  ) unless runner_dep

  # xcodeproj：保证 package_product_dependencies 可追加
  if widget_target.package_product_dependencies.nil?
    widget_target.package_product_dependencies = []
  end
  widget_deps = widget_target.package_product_dependencies
  widget_dep = widget_deps.find { |d|
    (d.respond_to?(:product_name) && d.product_name == pkg_name) ||
      (d.respond_to?(:display_name) && d.display_name == pkg_name)
  }
  unless widget_dep
    widget_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    widget_dep.product_name = pkg_name
    # 复用 Runner 的本地包引用（同一 XCLocalSwiftPackageReference）
    widget_dep.package = runner_dep.package if runner_dep.respond_to?(:package)
    widget_deps << widget_dep
    puts "已为 PangbaoWidget 添加 packageProductDependencies → #{pkg_name}"
  end

  # Frameworks 阶段以 productRef 链接（非普通 fileRef）
  already = widget_target.frameworks_build_phase.files.any? { |bf|
    next false unless bf.respond_to?(:product_ref) && bf.product_ref

    bf.product_ref == widget_dep ||
      (bf.product_ref.respond_to?(:product_name) && bf.product_ref.product_name == pkg_name)
  }
  unless already
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    if build_file.respond_to?(:product_ref=)
      build_file.product_ref = widget_dep
    else
      abort('当前 xcodeproj 不支持 PBXBuildFile#product_ref=，请升级 gem xcodeproj')
    end
    widget_target.frameworks_build_phase.files << build_file
    puts "已为 PangbaoWidget Frameworks 链接 #{pkg_name}（SPM product）"
  end
end

ensure_flutter_plugin_package_on_widget(project, widget_target, runner)
apply_widget_build_settings(widget_target, runner)
ensure_embed_extension_phase(runner, project, widget_target)
apply_team_attributes(project, widget_target)
disable_parallel_target_builds(project)
ensure_scheme_builds_widget(project, widget_target)

project.save
if created
  puts "已添加 PangbaoWidget Extension target（#{WIDGET_BUNDLE_ID}）并嵌入 Runner"
else
  puts "PangbaoWidget target 已存在，已补全 Extension 配置 / embed / scheme"
end
