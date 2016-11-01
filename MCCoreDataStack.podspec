Pod::Spec.new do |s|

s.ios.deployment_target = '8.0'
s.name = 'MCCoreDataStack'
s.summary = 'MCCoreDataStack is a simple SWIFT wrapper around CoreData Framework to create, save and fetch Managed Objects'
s.requires_arc = true
s.version = '0.9.0'
s.homepage = 'https://github.com/marcocattai/MCCoreDataStack'
s.license = { :type => 'MIT', :file => 'LICENSE' }
s.author = { '[Marco Cattai]' => '[cattai.marco@gmail.com]' }
s.source = { :git => 'https://github.com/marcocattai/MCCoreDataStack.git', :tag => '0.9.0'}
s.framework = ['Foundation', 'CoreData']
s.source_files = 'MCCoreDataStack/Library/*.swift', 'MCCoreDataStack/Library/**/*.swift'

end
