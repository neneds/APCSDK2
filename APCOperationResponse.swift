//
//  APCOperationResponse.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCOperationResponse : NSObject{
    
    public var data: AnyObject?
    public var status: APCOperationResultStatus
    
    public init(data: AnyObject?, status: APCOperationResultStatus) {
        self.data = data
        self.status = status
    }
    
    public override var description: String{
        return "OperationResponse = [data = \(self.data), status = \(self.status.rawValue)]"
    }
}

@objc public enum APCOperationResultStatus : Int {
    case CompletedSuccesfully = 0
    case OperationUnauthorized = 1
    case ConnectionError = 2
    case InternalServerError = 3
    case InvalidParamters = 4
    case ResourceNotFound = 5
    case NoContentReturned = 6
    
}
