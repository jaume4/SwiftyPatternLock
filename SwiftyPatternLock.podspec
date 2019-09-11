#
# Be sure to run `pod lib lint SwiftyPatternLock.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyPatternLock'
  s.version          = '0.1.1'
  s.summary          = 'A swifty pattern lock ViewController.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.swift_version = '5.0'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jaume4/SwiftyPatternLock'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jaume Corbi' => 'jaume@corbi.co' }
  s.source           = { :git => 'https://github.com/jaume4/SwiftyPatternLock.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jaume4'

  s.ios.deployment_target = '9.0'

  s.source_files = 'SwiftyPatternLock/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SwiftyPatternLock' => ['SwiftyPatternLock/Assets/*.png']
  # }

end
