Pod::Spec.new do |s|
  s.name         = "CreditCardReader"
  s.version      = "1.0.0"
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.3"
  s.summary      = "Extracts credit card information with the device's camera"
  s.description  = <<-DESC
                  Customizable library for credit card information detection.
                   DESC
  s.homepage     = "https://github.com/rakutentech/iOS-CreditCardReader"
  s.license      = "MIT"
  s.author       = { "Kevin Wong" => "kevin.a.wong@rakuten.com" }
  s.source       = { :git => "https://github.com/rakutentech/iOS-CreditCardReader.git", :tag => "#{s.version}" }

  s.subspec 'SwiftUI' do |u|
    u.source_files = ["Sources/Model/*.swift", "Sources/Views/*.swift", "Sources/SwiftUI/*.swift"]
  end

  s.subspec 'AltSwiftUI' do |u|
    u.source_files = ["Sources/Model/*.swift", "Sources/Views/*.swift", "Sources/AltSwiftUI/*.swift"]
    u.dependency 'AltSwiftUI', '~> 1.5' 
  end

  s.subspec 'UIKit' do |u|
    u.source_files = ["Sources/Model/*.swift", "Sources/Views/*.swift", "Sources/UIKit/*.swift"]
  end
end