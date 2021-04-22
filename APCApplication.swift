//
//  APCApplication.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/19/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCApplication: NSObject {

    public static let sharedApplication: APCApplication = APCApplication()

    // MARK: - Properties
    fileprivate(set) var applicationCode: Int?

    fileprivate override init() {

    }

    public func startWith(applicationCode code: Int) {
        self.applicationCode = code
    }

    // MARK: - Overrides
    public override var description: String {
        return "APCApplication[ applicationCode = \(String(describing: self.applicationCode))]"
    }
}
