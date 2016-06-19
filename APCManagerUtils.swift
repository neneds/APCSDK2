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

    
    class func codFromLocation(location: String)-> Int? {
        let paths = location.componentsSeparatedByString("/")
        if let strCod = paths.last{
            if let cod = Int(strCod){
                return cod
            }
        }
        return nil
    }
    
    class func responseHandler(response responseObject: Response<AnyObject, NSError>,
                                        onSuccess: ((responseValue: AnyObject?, responseHeaders: [NSObject: AnyObject]?)-> AnyObject?)? = nil,
                                        onNotFound: ((responseValue: AnyObject?, responseHeaders: [NSObject: AnyObject]?)-> AnyObject?)? = nil,
                                        onUnauthorized: ((responseValue: AnyObject?, responseHeaders: [NSObject: AnyObject]?)-> AnyObject?)? = nil,
                                        onInvalidParameters: ((responseValue: AnyObject?, responseHeaders: [NSObject: AnyObject]?)-> AnyObject?)? = nil,
                                        onConnectionError: ((responseValue: AnyObject?, responseHeaders: [NSObject: AnyObject]?)-> AnyObject?)? = nil,
                                        result: ((operationResponse: APCOperationResponse)-> Void)?){
        
        if let status = responseObject.response?.statusCode {
            let responseValue = responseObject.result.value
            let responseHeaders = responseObject.response?.allHeaderFields
            switch status {
            case 200, 201:
                result?(operationResponse: APCOperationResponse(data: onSuccess?(responseValue: responseValue, responseHeaders: responseHeaders),status: .CompletedSuccesfully))
            case 404:
                result?(operationResponse: APCOperationResponse(data: onNotFound?(responseValue: responseValue, responseHeaders: responseHeaders),status: .ResourceNotFound))
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InternalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: onUnauthorized?(responseValue: responseValue, responseHeaders: responseHeaders),status: .OperationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: onInvalidParameters?(responseValue: responseValue, responseHeaders: responseHeaders),status: .InvalidParamters))
            default:
                result?(operationResponse: APCOperationResponse(data: onConnectionError?(responseValue: responseValue, responseHeaders: responseHeaders),status: .ConnectionError))
                
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: onConnectionError?(responseValue: responseObject.result.error, responseHeaders: nil),status: .ConnectionError))
        }
    }

}
