#
# Be sure to run `pod lib lint GStackScrollView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GStackScrollView'
  s.version          = '0.1.2'
  s.summary          = '提供了一种简洁且高效的方式，轻松应对多种嵌套滚动场景。'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  GStackScrollView 是一个基于Objective-c实现的嵌套滚动处理组件，专为实现复杂的嵌套滚动需求而设计。它提供了一种简洁且高效的方式，轻松应对多种嵌套滚动场景。
                       DESC

  s.homepage         = 'https://github.com/GIKICoder/GStackScrollView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'GIKI' => 'giki.biu@gmail.com' }
  s.source           = { :git => 'https://github.com/GIKICoder/GStackScrollView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  s.source_files = 'GStackScrollView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'GStackScrollView' => ['GStackScrollView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
end
