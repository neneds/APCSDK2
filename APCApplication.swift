//
//  APCApplication.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/19/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCApplication: NSObject {

    public static let sharedApplication : APCApplication = APCApplication()
    
    //MARK: - Properties
    private(set) var applicationCode: Int?
    
    private override init() {
        
    }
    
    public func startWith(applicationCode code: Int) {
        self.applicationCode = code
    }
    
    //MARK:- Overrides
    public override var description: String  {
        return "APCApplication[ applicationCode = \(self.applicationCode)]"
    }
}
