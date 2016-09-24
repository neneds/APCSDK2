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
    
    class func responseHandler(response responseObject: Response<AnyObject, NSError>,
                                        onSuccess: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onNotFound: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onUnauthorized: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onInvalidParameters: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        onConnectionError: ((_ responseValue: AnyObject?, _ responseHeaders: [AnyHashable: Any]?)-> AnyObject?)? = nil,
                                        result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        
        if let status = responseObject.response?.statusCode {
            let responseValue = responseObject.result.value
            let responseHeaders = responseObject.response?.allHeaderFields
            switch status {
            case 200, 201:
                result?(operationResponse: APCOperationResponse(data: onSuccess?(responseValue: responseValue, responseHeaders: responseHeaders),status: .completedSuccesfully))
            case 404:
                result?(operationResponse: APCOperationResponse(data: onNotFound?(responseValue: responseValue, responseHeaders: responseHeaders),status: .resourceNotFound))
            case 500:
                result?(APCOperationResponse(data: nil,status: .internalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: onUnauthorized?(responseValue: responseValue, responseHeaders: responseHeaders),status: .operationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: onInvalidParameters?(responseValue: responseValue, responseHeaders: responseHeaders),status: .invalidParamters))
            case 204:
                result?(APCOperationResponse(data: nil, status: .noContentReturned))
            default:
                result?(operationResponse: APCOperationResponse(data: onConnectionError?(responseValue: responseValue, responseHeaders: responseHeaders),status: .connectionError))
                
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: onConnectionError?(responseValue: responseObject.result.error, responseHeaders: nil),status: .connectionError))
        }
    }

}
