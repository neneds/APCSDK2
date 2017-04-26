//
//  APCApplication.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/19/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

open class APCApplication: NSObject {

    open static let sharedApplication : APCApplication = APCApplication()
    
    //MARK: - Properties
    fileprivate(set) var applicationCode: Int?
    
    fileprivate override init() {
        
    }
    
    open func startWith(applicationCode code: Int) {
        self.applicationCode = code
    }
    
    //MARK:- Overrides
    open override var description: String  {
        return "APCApplication[ applicationCode = \(String(describing: self.applicationCode))]"
    }
}
