//
//  APCOperationResponse.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public struct APCOperationResponse {
    
    public var data: AnyObject?
    public var status: APCOperationResultStatus
    
    public init(data: AnyObject?, status: APCOperationResultStatus) {
        self.data = data
        self.status = status
    }
    
}

public enum APCOperationResultStatus {
    case CompletedSuccesfully
    case OperationUnauthorized
    case ConnectionError
    case InternalServerError
    case InvalidParamters
    case ResourceNotFound
    
}
