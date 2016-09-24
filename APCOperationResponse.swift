//
//  APCOperationResponse.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

open class APCOperationResponse : NSObject{
    
    open var data: AnyObject?
    open var status: APCOperationResultStatus
    
    public init(data: AnyObject?, status: APCOperationResultStatus) {
        self.data = data
        self.status = status
    }
    
    open override var description: String{
        return "OperationResponse = [data = \(self.data), status = \(self.statusToString())]"
    }
    
    fileprivate func statusToString()-> String{
        switch status {
        case .completedSuccesfully:
            return "CompletedSuccesfully"
        case .operationUnauthorized:
            return "OperationUnauthorized"
        case .connectionError:
            return "ConnectionError"
        case .internalServerError:
            return "InternalServerError"
        case .invalidParamters:
            return "InvalidParamters"
        case .resourceNotFound:
            return "ResourceNotFound"
        case .noContentReturned:
            return "NoContentReturned"
        }
    }
}

@objc public enum APCOperationResultStatus : Int {
    case completedSuccesfully = 0
    case operationUnauthorized = 1
    case connectionError = 2
    case internalServerError = 3
    case invalidParamters = 4
    case resourceNotFound = 5
    case noContentReturned = 6
    
}
