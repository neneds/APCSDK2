//
//  APCApplication.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/19/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

public class APCApplication: NSObject {

    public static let sharedApplication : APCApplication = APCApplication()
    
    //MARK: - Properties
    private(set) var applicationCode: Int?
    private(set) var applicationSecretToken: String?
    
    private override init() {
        
    }
    
    public func startWith(applicationCode code: Int, applicationSecretToken: String) {
        self.applicationCode = code
        self.applicationSecretToken = applicationSecretToken
    }
    
    //MARK:- Overrides
    public override var description: String  {
        return "APCApplication[ applicationCode = \(self.applicationCode), applicationSecretToken = \(self.applicationSecretToken)]"
    }
}
