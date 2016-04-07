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
    
}

@objc public enum APCOperationResultStatus : Int {
    case CompletedSuccesfully
    case OperationUnauthorized
    case ConnectionError
    case InternalServerError
    case InvalidParamters
    case ResourceNotFound
    
}
