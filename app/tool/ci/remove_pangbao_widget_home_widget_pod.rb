#!/usr/bin/env ruby
# frozen_string_literal: true

# 若曾写入 CocoaPods PangbaoWidget→home_widget（会撞 Flutter-static），则移除该块。
# Extension 改走 SPM：FlutterGeneratedPluginSwiftPackage。

IOS_DIR = File.expand_path('../../ios', __dir__)
PODFILE = File.join(IOS_DIR, 'Podfile')
MARKER_BEGIN = '# BEGIN pangbao_widget_home_widget'
MARKER_END = '# END pangbao_widget_home_widget'

unless File.exist?(PODFILE)
  puts '无 Podfile，跳过清理'
  exit 0
end

text = File.read(PODFILE)
unless text.include?(MARKER_BEGIN)
  puts 'Podfile 无 PangbaoWidget home_widget 标记块，跳过清理'
  exit 0
end

cleaned = text.gsub(
  /\n?#{Regexp.escape(MARKER_BEGIN)}.*?#{Regexp.escape(MARKER_END)}\n?/m,
  "\n",
)
File.write(PODFILE, cleaned)
puts '已从 Podfile 移除 PangbaoWidget→home_widget（改走 SPM）'
puts '请接着执行: (cd ios && pod install)'
