//
//  AutoMockable.swift
//  ChatSDK
//
//  Created by Hayk Kolozyan on 10.05.24.
//

import Foundation

/**
 this is the base mock generating protocol used as mark

 # Notes: #
 - this is the base to mark every necessary mockable protocols to get generated mocks
 - just inherit your protocol from it

 # Example #
 ```
 // protocol SomethingDoable: AutoMockable
 ```

 to generate mocks add the next line to the build phase
 Sourcery/bin/sourcery --sources ./../../chat_ios/Sources/ --templates ./Sourcery/Templates/AutoMockable.stencil --output ./../../chat_ios/Sources/TestsSpecs/Mocks
 */
public protocol AutoMockable {}
