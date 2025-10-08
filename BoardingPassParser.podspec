Pod::Spec.new do |spec|
  spec.name         = "BoardingPassParser"
  spec.version      = "2.1.1"
  spec.summary      = "A Swift framework for parsing airline boarding pass barcodes and QR codes that conform to the IATA BCBP standard."
  spec.description  = <<-DESC
  BoardingPassKit is a comprehensive Swift framework for parsing airline boarding pass barcodes and QR codes that conform to the IATA Bar Coded Boarding Pass (BCBP) standard Version 8. It supports single and multi-leg itineraries, bag tags, frequent flyer information, and includes comprehensive debugging capabilities.
  DESC

  spec.homepage     = "https://github.com/anomaddev/BoardingPassKit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Justin Ackermann" => "justin@example.com" }
  
  spec.platforms    = { :ios => "15.0", :osx => "10.15" }
  spec.swift_version = "5.7"
  
  spec.source       = { :git => "https://github.com/anomaddev/BoardingPassKit.git", :tag => "#{spec.version}" }
  
  spec.source_files = "Sources/BoardingPassKit/**/*.swift"
  spec.exclude_files = "Sources/BoardingPassKit/BoardingPassKit.h"
  
  spec.dependency "SwiftDate", "~> 7.0"
  
  spec.frameworks = "Foundation"
  spec.ios.frameworks = "UIKit"
  
  spec.requires_arc = true
end
