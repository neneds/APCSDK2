//
//  APCPostageManager.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit
import Alamofire
open class APCPostageManager: NSObject {

    open static let sharedManager: APCPostageManager = APCPostageManager()
    
    fileprivate override init() {
        
    }
    
    /**
     Cria uma postagem na plataforma. Requer autenticação.
     - parameter postage Postagem que será registrada.
     - parameter relatedPostageCod Código de uma postagem relacionada que já deve estar registrada na plataforma.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func createPostage(postage: APCPostage,relatedPostageCod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        self.privateCreatePostage(postage: postage, relatedPostageCod: relatedPostageCod, result: result)
    }
    
    /**
     Cria uma postagem na plataforma. Requer autenticação.
     - parameter postage Postagem que será registrada.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func createPostage(postage: APCPostage, result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        self.privateCreatePostage(postage: postage, result: result)
    }
    
    
    // Convenience method to mantain other methods as headers public functions on objc header
    fileprivate func privateCreatePostage(postage: APCPostage,relatedPostageCod: Int? = nil, result: ((_ operationResponse: APCOperationResponse)-> Void)?) {
        if let session = APCUserManager.sharedManager.activeSession {
            if let codApp = APCApplication.sharedApplication.applicationCode {
                if session.isSessionExpired {
                    APCUserManager.sharedManager.refreshSession({ (operationResult) in
                        if operationResult.status == .completedSuccesfully {
                            self.privateCreatePostage(postage: postage, relatedPostageCod: relatedPostageCod, result: result)
                        }else{
                            result?(operationResult)
                        }
                    })
                }else{
                    var postageDic = postage.asDictionary()
                    if let unwrappedRelatedPostageCod = relatedPostageCod {
                        var relatedDic : [String : AnyObject] = [:]
                        relatedDic.updateValue(unwrappedRelatedPostageCod as AnyObject, forKey: "codPostagem")
                        postageDic.updateValue(relatedDic as AnyObject, forKey: "postagemRelacionada")
                    }
                    if let token = session.sessionToken {
                        Alamofire.request(APCURLProvider.postageBaseURL(), method: .get, parameters: postageDic, encoding: .json, headers: ["appIdentifier" : String(codApp), "appToken" : token]).responseJSON(completionHandler: { (response) in
                            self.postageCreateResponseHandler(postage: postage,response: response, result: result)
                        })
                    }else{
                        result?(APCOperationResponse(data: nil, status: .operationUnauthorized))
                    }
                }
            }else{
                result?(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .operationUnauthorized))
            }
        }else{
            result?(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
    }
    
    
    /**
     Busca os dados de uma postagem por código. Abstrai o endpoint /rest/postagens/{codPostagem}
     - parameter postageCod Código da postagem que será buscada.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso os dados da postagem.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func findPostage(codPostage cod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(APCURLProvider.postageURL(postageCod: cod),method: .get).responseJSON { (responseObject) in
            APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                if let postageData = responseValue as? [String : AnyObject] {
                    return JsonObjectCreator.createObject(dictionary: postageData, objectClass: APCPostage.self)
                }
                return nil
                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
        }
    }
    
    
    /**
     Método de busca de postagens. Esse método é apenas uma abstração do endpoint GET - /rest/postagens. Você pode ver documentação completa no link : [GET - /rest/postagens](https://github.com/AppCivicoPlataforma/AppCivico/blob/master/MetamodeloAPI.md#buscar-postagens)
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso um array com as postagens de resultado.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func queryPostages(_ authorCod: Int?,
                       destinatedGroupCod: Int?,
                       destinatedPersonCod: Int?,
                       relatedPostageCod: Int?,
                       postageTypesCods: [Int]?,
                       hashtag: String?,
                       codDestinationObjectType: Int?,
                       codDestinationObject: NSNumber?,
                       page: Int?,
                       maxPostageReturned: Int?,
                       result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
            if let session = APCUserManager.sharedManager.activeSession {
                if let codApp = APCApplication.sharedApplication.applicationCode {
                    if session.isSessionExpired {
                        APCUserManager.sharedManager.refreshSession({ (operationResult) in
                            if operationResult.status == .completedSuccesfully {
                                self.queryPostages(authorCod, destinatedGroupCod: destinatedGroupCod,
                                                    destinatedPersonCod:  destinatedPersonCod, relatedPostageCod: relatedPostageCod,
                                                    postageTypesCods: postageTypesCods, hashtag: hashtag, codDestinationObjectType:codDestinationObjectType,
                                                    codDestinationObject: codDestinationObject, page: page, maxPostageReturned: maxPostageReturned, result: result)
                            }else{
                                result(operationResult)
                            }
                        })
                    }else{
                        if let token = session.sessionToken {
                            var parameters : [String: AnyObject] = [:]
                            parameters.updateValue(codApp as AnyObject, forKey: "codAplicativo")
                            parameters.updateOptionalValue(authorCod as AnyObject?, forKey: "codAutor")
                            parameters.updateOptionalValue(destinatedPersonCod as AnyObject?, forKey: "codPessoaDestino")
                            parameters.updateOptionalValue(destinatedGroupCod as AnyObject?, forKey: "codGrupoDestino")
                            parameters.updateOptionalValue(relatedPostageCod as AnyObject?, forKey: "codPostagemRelacionada")
                            if let unwrappedTypesCods = postageTypesCods {
                                if !unwrappedTypesCods.isEmpty {
                                    let types = unwrappedTypesCods.reduce("", { (string, value) -> String in
                                        if(string.isEmpty){
                                            return String(value)
                                        }
                                        return "\(string),\(value)"
                                    })
                                    parameters.updateValue(types as AnyObject, forKey: "codTiposPostagem")
                                }

                            }
                            parameters.updateOptionalValue(hashtag as AnyObject?, forKey: "hashtag")
                            parameters.updateOptionalValue(codDestinationObjectType as AnyObject?, forKey: "codTipoObjetoDestino")
                            parameters.updateOptionalValue(codDestinationObject, forKey: "codObjetoDestino")
                            parameters.updateOptionalValue(page as AnyObject?, forKey: "pagina")
                            parameters.updateOptionalValue(maxPostageReturned as AnyObject?, forKey: "quantidadeDeItens")

                            Alamofire.request(APCURLProvider.postageBaseURL(), method: .get, parameters: parameters, encoding: .urlEncodedInURL, headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                                APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                                    if let postagesData = responseValue as? [[String : AnyObject]] {
                                        return JsonObjectCreator.create(dictionaryArray: postagesData, objectClass: APCPostage.self)
                                    }
                                    return nil
                                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
                            })
                        }else{
                            result(APCOperationResponse(data: nil, status: .operationUnauthorized))
                        }
                    }
                }else{
                    result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .operationUnauthorized))
                }
            }else{
                result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
            }
    }
    
    
    /**
     Exclui uma postagem na plataforma. Ao excluir uma postagem, seus conteúdos são também excluídos. Requer autenticação.
     - parameter postageCod Código da postagem que será excluída.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */

    open func deletePostage(postageCod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.deletePostage(postageCod: postageCod, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(APCURLProvider.postageURL(postageCod: postageCod), method: .delete, parameters: nil, encoding: .url, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
        
    }
    
    
    
    
    
    //MARK: - Private methods
    fileprivate func postageCreateResponseHandler(postage: APCPostage,response responseObject: Response<AnyObject, NSError>, result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let location = responseHeaders?["location"] as? String{
                if let cod = APCManagerUtils.codFromLocation(location){
                    postage.cod = cod
                    return postage
                }
            }
            return nil

            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
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
// MARK: - Postage Content Manager
extension APCPostageManager {
    
    
    /**
     Cria um conteúdo de postagem na plataforma associado à uma postagem. Requer autenticação.
     - parameter postageCod Postagem à qual será associada o conteúdo.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func setPostageContent(postageCod: Int, postageContent: APCPostageContent, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.setPostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let content = postageContent.asDictionary()
                    let headers = ["appToken" : token]
                    postageContent.postageCod = postageCod
                    Alamofire.request(APCURLProvider.postageContentURL(postageCod: postageCod), method: .post, parameters: content, encoding: .json, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.postageContentCreateResponseHandler(postage: postageContent, response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
    }
    
    
    
    /**
     Atualiza um conteúdo de postagem na plataforma. Requer autenticação.
     - parameter postageCod Postagem à qual será associada o conteúdo. O conteúdo deve conter o campo cod preenchido.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func updatePostageContent(postageCod: Int, postageContent: APCPostageContent, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.updatePostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    if postageContent.cod == 0{
                        result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 20, userInfo: [NSLocalizedDescriptionKey : "The content must have a cod != 0 to be updated"]),status: .invalidParamters))
                    }else{
                        let content = postageContent.asDictionary()
                        let headers = ["appToken" : token]
                        postageContent.postageCod = postageCod
                        Alamofire.request(APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: postageContent.cod), method: .put, parameters: content, encoding: .json, headers: headers).responseJSON(completionHandler: { (responseObject) in
                            self.updatePostageContentResponseHandler(postage: postageContent, response: responseObject, result: result)
                        })
                    }
                }
            }
        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
        
    }
    
    /**
     Exclui um conteúdo de postagem na plataforma. Requer autenticação.
     - parameter postageCod Código da postagem à qual pertence o conteúdo.
     - parameter postageContentCod Código do conteúdo que será excluído.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func deletePostageContent(postageCod: Int, postageContentCod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.deletePostageContent(postageCod: postageCod, postageContentCod: postageContentCod, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: postageContentCod), method: .delete, parameters: nil, encoding: .url, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
    }
    
    /**
     Encontra os dados de um conteúdo de postagem na plataforma por código. Requer autenticação.
     - parameter postageCod Código da postagem à qual pertence o conteúdo.
     - parameter postageContentCod Código do conteúdo que será buscado.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso um objeto de APCPostageContent no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func findPostageContent(postageCod: Int,contentCod: Int,result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.findPostageContent(postageCod: postageCod, contentCod: contentCod, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: contentCod), method: .get, parameters: nil, encoding: .urlEncodedInURL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.findPostageContentResponseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }

    }
    
    /**
     Método de busca conteúdos de uma postagem. O método busca os conteúdos a partir da propriedade contentsCodes no objeto de postagem.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso um array com os conteúdos da postagem como resultado além de popular a propriedade contents no objeto de postagem enviado como parâmetro.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func postageContents(postage: APCPostage, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        let contents = [APCPostageContent]()
        if !postage.contentsCodes.isEmpty {
            self.postageContents(contents, postageCod: postage.cod, contentsCods: postage.contentsCodes, index: 0,  result: {(operationResponse) in
                if let pcontents = operationResponse.data as? [APCPostageContent]{
                    postage.contents = pcontents
                }
                result(operationResponse)
            })
        }
    }
    
    /**
     Método de busca conteúdos de várias postagens. O método busca os conteúdos a partir da propriedade contentsCodes no objeto de postagem.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso irá popular a propriedade contents nos objetos de postagem enviados como parâmetro.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func postagesContents(postages: [APCPostage], result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        self.postagensContents(postages: postages, index: 0, result: result)
    }
    
    
    fileprivate func postagensContents(postages: [APCPostage], index: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if index >= postages.count {
            result(APCOperationResponse(data: nil, status: .completedSuccesfully))
        }else{
            self.postageContents(postage: postages[index], result: { (operationResponse) in
                
                switch operationResponse.status{
                case .completedSuccesfully, .resourceNotFound, .noContentReturned:
                    self.postagensContents(postages: postages, index: index + 1, result: result)
                default:
                    result(operationResponse)
                }
            })
        }
    }
    
    
    fileprivate func postageContents(_ contents: [APCPostageContent],postageCod: Int, contentsCods: [Int], index: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void ){
        var localContents : [APCPostageContent] = []
        localContents.append(contentsOf: contents)
        if index >= contentsCods.count {
            result(APCOperationResponse(data: localContents as AnyObject?, status: .completedSuccesfully))
        }else{
            self.findPostageContent(postageCod: postageCod, contentCod: contentsCods[index], result: { (operationResponse) in
                
                switch operationResponse.status{
                case .completedSuccesfully, .resourceNotFound, .noContentReturned:
                    if let content = operationResponse.data as? APCPostageContent {
                        localContents.append(content)
                    }
                    self.postageContents(localContents, postageCod: postageCod, contentsCods: contentsCods, index: index + 1, result: result)
                default:
                    result(operationResponse)
                }
            })
        }
    }
    
    //MARK: - Postage content handlers
    fileprivate func postageContentCreateResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: (_ operationResponse: APCOperationResponse)-> Void){
        
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let location = responseHeaders?["location"] as? String{
                if let cod = APCManagerUtils.codFromLocation(location){
                    postageContent.cod = cod
                    return postageContent
                }
            }
            return nil
            
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    fileprivate func updatePostageContentResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: (_ operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, reponseHeaders) -> AnyObject? in
            return postageContent
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    fileprivate func findPostageContentResponseHandler(response responseObject: Response<AnyObject, NSError>, result: (_ operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let contentDic = responseValue as? [String : AnyObject] {
                return JsonObjectCreator.createObject(dictionary: contentDic, objectClass: APCPostageContent.self)
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    

}
