Pod::Spec.new do |s|
  s.name         = "isgl3d"
  s.version      = "1.3.3"
  s.summary      = "iSGL3D (iOS Scene Graph Library) is a 3D framework for the iPhone, iPad and iPod touch written in Objective-C."
  s.homepage     = "http://isgl3d.com/"
  s.license      = { :type => 'MIT'} # , :file => 'LICENSE.isgl3d' }
  s.author       = { "Stuart Caunt" => "isgl3d@gmail.com" }
  s.source       = { :git => "https://github.com/ElegantCodeFTW/isgl3d.git", :tag => "1.3.3" } #, "0.0.1" }
  s.platform     = :ios, '5.0'
  s.source_files = 'isgl3d/**/*.{h,m,c,mm,cpp}', 'isgl3dbullet/**/*.{h,m,c,mm,cpp}', 'external/**/*.{h,m,c,mm,cpp}', 'external/**/**/*.{h,m,c,mm,cpp}' 
  s.header_mappings_dir = '.'
  s.resources    = "Resources/**/*.{fsh,vsh}"
  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
  s.frameworks  = 'Foundation', 'QuartzCore', 'OpenGLES', 'UIKit', 'CoreGraphics', 'GLKit'
  s.requires_arc = false
  s.prefix_header_file = 'isgl3d/isgl3d-Apps-Prefix.pch'
  s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) BUILD_OGLES2' }
end