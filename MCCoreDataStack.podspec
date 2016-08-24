Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '7.0'
s.name = "MCCoreDataStack"
s.summary = "MCCoreDataStack is a simple SWIFT wrapper around Apple's Core Data Framework to create, save and fetch Managed Objects"
s.requires_arc = true
s.version = "0.1.0"
s.license = { :type => "MIT", :file => "LICENSE" }
s.author = { "[Marco Cattai]" => "[cattai.marco@gmail.com]" }
s.homepage = "[http://marcocattai.github.io/]"
s.source = { :git => "https://github.com/marcocattai/MCCoreDataStack.git", :tag => "#{s.version}"}
s.framework = ['Foundation', 'CoreData']
s.source_files = 'MCCoreDataStack/Library/*.swift', 'MCCoreDataStack/Library/**/*.swift'

end
