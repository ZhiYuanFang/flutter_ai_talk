#!/usr/bin/env ruby
# frozen_string_literal: true

# CocoaPods：为 PangbaoWidget Extension 挂上 home_widget，
# 使 WidgetBackgroundIntent 能 `import home_widget`。
# 须在 ensure_pangbao_widget_target.rb 创建 Extension 之后、再次 pod install 之前运行。

require 'fileutils'

IOS_DIR = File.expand_path('../../ios', __dir__)
PODFILE = File.join(IOS_DIR, 'Podfile')
WIDGET_NAME = 'PangbaoWidget'
# 相对 ios/ 目录；flutter pub get 后存在
HOME_WIDGET_POD_PATH = File.join('.symlinks', 'plugins', 'home_widget', 'ios')
HOME_WIDGET_ABS = File.expand_path(HOME_WIDGET_POD_PATH, IOS_DIR)

abort("缺少 #{PODFILE}（请先 flutter create / flutter pub get 生成 iOS 工程）") unless File.exist?(PODFILE)
abort("缺少 home_widget 插件路径 #{HOME_WIDGET_ABS}（请先在 app/ 下 flutter pub get）") unless File.directory?(HOME_WIDGET_ABS)

MARKER_BEGIN = '# BEGIN pangbao_widget_home_widget'
MARKER_END = '# END pangbao_widget_home_widget'

WIDGET_POD_BLOCK = <<~RUBY
  #{MARKER_BEGIN}
  # 交互「跳过」：Extension 须能 import home_widget（CocoaPods 路径）
  target '#{WIDGET_NAME}' do
    use_frameworks!
    use_modular_headers!

    pod 'home_widget', :path => '#{HOME_WIDGET_POD_PATH}'
  end
  #{MARKER_END}
RUBY

text = File.read(PODFILE)

# 已有本脚本标记块：保持幂等
if text.include?(MARKER_BEGIN) && text.include?(MARKER_END)
  puts "Podfile 已含 #{WIDGET_NAME} home_widget 块，跳过写入"
  exit 0
end

# 已有手写 target 且含 home_widget：不重复插入
if text.match?(/target\s+['"]#{WIDGET_NAME}['"]/) && text.include?("pod 'home_widget'")
  puts "Podfile 已为 #{WIDGET_NAME} 声明 home_widget，跳过写入"
  exit 0
end

# 插在文件末尾（post_install 之后亦可；CocoaPods 允许多 target）
# 若存在 post_install，插在其前，避免部分团队习惯把自定义 target 放在 helper 之前
if (idx = text.index(/^post_install\s+do\b/))
  text = text.dup.insert(idx, "\n#{WIDGET_POD_BLOCK}\n")
else
  text = "#{text.rstrip}\n\n#{WIDGET_POD_BLOCK}\n"
end

File.write(PODFILE, text)
puts "已向 Podfile 写入 #{WIDGET_NAME} → home_widget（#{HOME_WIDGET_POD_PATH}）"
puts '请接着执行: (cd ios && pod install)'
