Pod::Spec.new do |spec|
  spec.name             = "ChatSDK"
  spec.version          = "3.3.1"
  spec.summary          = "The embeddable Chat module."
  spec.homepage         = "https://git.lgn.me/technolab/pr1me/chat_ios"
  spec.license          = "Proprietary"
  spec.author           = { "Yakov Manshin" => "git@yakovmanshin.com" }
  spec.swift_version    = "5.9"
  spec.platform         = :ios, "13.0"
  spec.source           = { :git => "https://git.lgn.me/technolab/pr1me/chat_ios.git", :tag => "#{spec.version}" }
  spec.source_files     = "Sources/**/*.{h,m,swift}"
  spec.resources        = "Resources/**"
  
  spec.dependency "GRDB.swift", "~> 5.11"
  spec.dependency "Starscream", "~> 3.1"
  spec.dependency "SwiftTryCatch"
  
  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.swift'
  end
end
