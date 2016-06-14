//
//  APCPostageManager.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit
import Alamofire
public class APCPostageManager: NSObject {

    public static let sharedManager: APCPostageManager = APCPostageManager()
    
    private override init() {
        
    }
    
    
    public func createPostage(postage postage: APCPostage, codApp: Int,relatedPostageCod: NSNumber?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.createPostage(postage: postage, codApp: codApp,relatedPostageCod: relatedPostageCod, result: result)
                    }else{
                        result?(operationResponse: operationResult)
                    }
                })
            }else{
                var postageDic = postage.asDictionary()
                if let unwrappedRelatedPostageCod = relatedPostageCod {
                    var relatedDic : [String : AnyObject] = [:]
                    relatedDic.updateValue(unwrappedRelatedPostageCod.integerValue, forKey: "codPostagem")
                    postageDic.updateValue(relatedDic, forKey: "postagemRelacionada")
                }
                if let token = session.sessionToken {
                    Alamofire.request(.POST, APCURLProvider.postageBaseURL(), parameters: postageDic, encoding: .JSON, headers: ["appIdentifier" : String(codApp), "appToken" : token]).responseJSON(completionHandler: { (response) in
                        self.postageCreateResponseHandler(postage: postage,response: response, result: result)
                    })
                }else{
                    result?(operationResponse: APCOperationResponse(data: nil, status: .OperationUnauthorized))
                }
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: ["Error" : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    
    
    public func setPostageContent(postageCod postageCod: Int, postageContent: APCPostageContent, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.setPostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result?(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let content = postageContent.asDictionary()
                    let headers = ["appToken" : token]
                    postageContent.postageCod = postageCod
                    Alamofire.request(.POST, APCURLProvider.postageContentURL(postageCod: postageCod), parameters: content, encoding: .JSON, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.postageContentCreateResponseHandler(postage: postageContent, response: responseObject, result: result)
                    })
                }
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: ["Error" : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    public func updatePostageContent(postageCod postageCod: Int, postageContent: APCPostageContent, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.updatePostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result?(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    if postageContent.cod == 0{
                        result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 20, userInfo: ["Error" : "The content must have a cod != 0 to be updated"]),status: .InvalidParamters))
                    }else{
                        let content = postageContent.asDictionary()
                        let headers = ["appToken" : token]
                        postageContent.postageCod = postageCod
                        Alamofire.request(.PUT, APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: postageContent.cod), parameters: content, encoding: .JSON, headers: headers).responseJSON(completionHandler: { (responseObject) in
                            self.updatePostageContentResponseHandler(postage: postageContent, response: responseObject, result: result)
                        })
                    }
                }
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: ["Error" : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    
    }
    
    public func deletePostage(postageCod postageCod: Int, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.deletePostage(postageCod: postageCod, result: result)
                    }else{
                        result?(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(.DELETE, APCURLProvider.postageURL(postageCod: postageCod), parameters: nil, encoding: .URL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.defaultResponseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: ["Error" : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }

    }
    
    public func deletePostageContent(postageCod postageCod: Int, postageContentCod: Int, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.deletePostageContent(postageCod: postageCod, postageContentCod: postageContentCod, result: result)
                    }else{
                        result?(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(.DELETE, APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: postageContentCod), parameters: nil, encoding: .URL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.defaultResponseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: ["Error" : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    
    //MARK: - Private methods
    private func postageCreateResponseHandler(postage postage: APCPostage,response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let status = responseObject.response?.statusCode {
            switch status {
            case 201:
                if let location = responseObject.response?.allHeaderFields["location"] as? String{
                    if let cod = APCManagerUtils.codFromLocation(location){
                            postage.cod = cod
                            result?(operationResponse: APCOperationResponse(data: postage,status: .CompletedSuccesfully))
                    }
                }
                
            case 404:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ResourceNotFound))
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InternalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: nil,status: .OperationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InvalidParamters))
            default:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ConnectionError))

            }
        }
    }
    
    private func postageContentCreateResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let status = responseObject.response?.statusCode {
            switch status {
            case 201:
                if let location = responseObject.response?.allHeaderFields["location"] as? String{
                    if let cod = APCManagerUtils.codFromLocation(location){
                        postageContent.cod = cod
                        result?(operationResponse: APCOperationResponse(data: postageContent,status: .CompletedSuccesfully))
                    }
                }
                
            case 404:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ResourceNotFound))
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InternalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: nil,status: .OperationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InvalidParamters))
            default:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ConnectionError))
                
            }
        }
    }
    
    private func updatePostageContentResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let status = responseObject.response?.statusCode {
            switch status {
            case 200:
                  result?(operationResponse: APCOperationResponse(data: postageContent,status: .CompletedSuccesfully))
            case 404:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ResourceNotFound))
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InternalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: nil,status: .OperationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InvalidParamters))
            default:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ConnectionError))
                
            }
        }
    }
    
    private func defaultResponseHandler(response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let status = responseObject.response?.statusCode {
            switch status {
            case 200:
                result?(operationResponse: APCOperationResponse(data: nil,status: .CompletedSuccesfully))
            case 404:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ResourceNotFound))
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InternalServerError))
            case 401, 403:
                result?(operationResponse: APCOperationResponse(data: nil,status: .OperationUnauthorized))
            case 400:
                result?(operationResponse: APCOperationResponse(data: nil,status: .InvalidParamters))
            default:
                result?(operationResponse: APCOperationResponse(data: nil,status: .ConnectionError))
                
            }
        }

    }
//    
//    if let session = APCUserManager.sharedManager.activeSession {
//        if session.isSessionExpired {
//            APCUserManager.sharedManager.refreshSession({ (operationResult) in
//                if operationResult.status == .CompletedSuccesfully {
//                    
//                }else{
//                    result?(operationResponse: operationResult)
//                }
//            })
//        }else{
//            
//            // Implementation of method
//        }
//    }else{
//    result?(operationResponse: APCOperationResponse(data: nil, status: .OperationUnauthorized))
//    }
    //    {
    //    "autor": {
    //    "codPessoa": 0
    //    },
    //    "codObjetoDestino": 0,
    //    "codTipoObjetoDestino": 0,
    //    "postagemRelacionada": {
    //    "codPostagem": 0
    //    },
    //    "tipo": {
    //    "codTipoPostagem": 0
    //    }
    //    }
    
    
    
}
