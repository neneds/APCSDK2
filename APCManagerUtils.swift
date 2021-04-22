//
//  APCManagerUtils.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/13/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit
import Alamofire

class APCManagerUtils: NSObject {

    
    class func codFromLocation(_ location: String)-> Int? {
        let paths = location.components(separatedBy: "/")
        if let strCod = paths.last{
            if let cod = Int(strCod){
                return cod
            }
        }
        return nil
    }
    
    class func responseHandler(response responseObject: AFDataResponse<Any>,
                                        onSuccess: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onNotFound: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onUnauthorized: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onInvalidParameters: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onConnectionError: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        
        switch responseObject.result {
        case let .success(value):
            if let status = responseObject.response?.statusCode {
                let responseValue = value
                let responseHeaders = responseObject.response?.allHeaderFields
                
             
                
                switch status {
                    
                case 200, 201:
                    result?(APCOperationResponse(data: onSuccess?(responseValue as AnyObject?, responseHeaders),status: .completedSuccesfully))
                case 404:
                    result?(APCOperationResponse(data: onNotFound?(responseValue as AnyObject?, responseHeaders),status: .resourceNotFound))
                case 500:
                    result?(APCOperationResponse(data: nil,status: .internalServerError))
                case 401, 403:
                    result?(APCOperationResponse(data: onUnauthorized?(responseValue as AnyObject?, responseHeaders),status: .operationUnauthorized))
                case 400:
                    result?(APCOperationResponse(data: onInvalidParameters?(responseValue as AnyObject?, responseHeaders),status: .invalidParamters))
                case 204:
                    result?(APCOperationResponse(data: nil, status: .noContentReturned))
                default:
                    result?(APCOperationResponse(data: onConnectionError?(responseValue as AnyObject?, responseHeaders),status: .connectionError))
                    
                }
            }
        case let .failure(error):
            result?(APCOperationResponse(data: onConnectionError?(error as AnyObject?, nil),status: .connectionError))
        }
    }

}
