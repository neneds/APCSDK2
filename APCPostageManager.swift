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
    
    /**
     Cria uma postagem na plataforma. Requer autenticação.
     - parameter postage Postagem que será registrada.
     - parameter relatedPostageCod Código de uma postagem relacionada que já deve estar registrada na plataforma.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func createPostage(postage postage: APCPostage,relatedPostageCod: Int, result: (operationResponse: APCOperationResponse)-> Void) {
        self.privateCreatePostage(postage: postage, relatedPostageCod: relatedPostageCod, result: result)
    }
    
    /**
     Cria uma postagem na plataforma. Requer autenticação.
     - parameter postage Postagem que será registrada.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func createPostage(postage postage: APCPostage, result: (operationResponse: APCOperationResponse)-> Void) {
        self.privateCreatePostage(postage: postage, result: result)
    }
    
    
    // Convenience method to mantain other methods as headers public functions on objc header
    private func privateCreatePostage(postage postage: APCPostage,relatedPostageCod: Int? = nil, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        if let session = APCUserManager.sharedManager.activeSession {
            if let codApp = APCApplication.sharedApplication.applicationCode {
                if session.isSessionExpired {
                    APCUserManager.sharedManager.refreshSession({ (operationResult) in
                        if operationResult.status == .CompletedSuccesfully {
                            self.privateCreatePostage(postage: postage, relatedPostageCod: relatedPostageCod, result: result)
                        }else{
                            result?(operationResponse: operationResult)
                        }
                    })
                }else{
                    var postageDic = postage.asDictionary()
                    if let unwrappedRelatedPostageCod = relatedPostageCod {
                        var relatedDic : [String : AnyObject] = [:]
                        relatedDic.updateValue(unwrappedRelatedPostageCod, forKey: "codPostagem")
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
                result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .OperationUnauthorized))
            }
        }else{
            result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    
    /**
     Busca os dados de uma postagem por código. Abstrai o endpoint /rest/postagens/{codPostagem}
     - parameter postageCod Código da postagem que será buscada.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso os dados da postagem.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func findPostage(codPostage cod: Int, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.postageURL(postageCod: cod)).responseJSON { (responseObject) in
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
    public func queryPostages(authorCod: Int?,
                       destinatedGroupCod: Int?,
                       destinatedPersonCod: Int?,
                       relatedPostageCod: Int?,
                       postageTypesCods: [Int]?,
                       hashtag: String?,
                       codDestinationObjectType: Int?,
                       codDestinationObject: NSNumber?,
                       page: Int?,
                       maxPostageReturned: Int?,
                       result: (operationResponse: APCOperationResponse)-> Void){
        
            if let session = APCUserManager.sharedManager.activeSession {
                if let codApp = APCApplication.sharedApplication.applicationCode {
                    if session.isSessionExpired {
                        APCUserManager.sharedManager.refreshSession({ (operationResult) in
                            if operationResult.status == .CompletedSuccesfully {
                                self.queryPostages(authorCod, destinatedGroupCod: destinatedGroupCod,
                                                    destinatedPersonCod:  destinatedPersonCod, relatedPostageCod: relatedPostageCod,
                                                    postageTypesCods: postageTypesCods, hashtag: hashtag, codDestinationObjectType:codDestinationObjectType,
                                                    codDestinationObject: codDestinationObject, page: page, maxPostageReturned: maxPostageReturned, result: result)
                            }else{
                                result(operationResponse: operationResult)
                            }
                        })
                    }else{
                        if let token = session.sessionToken {
                            var parameters : [String: AnyObject] = [:]
                            parameters.updateValue(codApp, forKey: "codAplicativo")
                            parameters.updateOptionalValue(authorCod, forKey: "codAutor")
                            parameters.updateOptionalValue(destinatedPersonCod, forKey: "codPessoaDestino")
                            parameters.updateOptionalValue(destinatedGroupCod, forKey: "codGrupoDestino")
                            parameters.updateOptionalValue(relatedPostageCod, forKey: "codPostagemRelacionada")
                            if let unwrappedTypesCods = postageTypesCods {
                                if !unwrappedTypesCods.isEmpty {
                                    let types = unwrappedTypesCods.reduce("", combine: { (string, value) -> String in
                                        if(string.isEmpty){
                                            return String(value)
                                        }
                                        return "\(string),\(value)"
                                    })
                                    parameters.updateValue(types, forKey: "codTiposPostagem")
                                }

                            }
                            parameters.updateOptionalValue(hashtag, forKey: "hashtag")
                            parameters.updateOptionalValue(codDestinationObjectType, forKey: "codTipoObjetoDestino")
                            parameters.updateOptionalValue(codDestinationObject, forKey: "codObjetoDestino")
                            parameters.updateOptionalValue(page, forKey: "pagina")
                            parameters.updateOptionalValue(maxPostageReturned, forKey: "quantidadeDeItens")

                            Alamofire.request(.GET, APCURLProvider.postageBaseURL(), parameters: parameters, encoding: .URLEncodedInURL, headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                                APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                                    if let postagesData = responseValue as? [[String : AnyObject]] {
                                        return JsonObjectCreator.create(dictionaryArray: postagesData, objectClass: APCPostage.self)
                                    }
                                    return nil
                                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
                            })
                        }else{
                            result(operationResponse: APCOperationResponse(data: nil, status: .OperationUnauthorized))
                        }
                    }
                }else{
                    result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .OperationUnauthorized))
                }
            }else{
                result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
            }
    }
    
    
    /**
     Exclui uma postagem na plataforma. Ao excluir uma postagem, seus conteúdos são também excluídos. Requer autenticação.
     - parameter postageCod Código da postagem que será excluída.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */

    public func deletePostage(postageCod postageCod: Int, result: (operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.deletePostage(postageCod: postageCod, result: result)
                    }else{
                        result(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(.DELETE, APCURLProvider.postageURL(postageCod: postageCod), parameters: nil, encoding: .URL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
        
    }
    
    
    
    
    
    //MARK: - Private methods
    private func postageCreateResponseHandler(postage postage: APCPostage,response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
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
    public func setPostageContent(postageCod postageCod: Int, postageContent: APCPostageContent, result: (operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.setPostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result(operationResponse: operationResult)
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
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    
    
    /**
     Atualiza um conteúdo de postagem na plataforma. Requer autenticação.
     - parameter postageCod Postagem à qual será associada o conteúdo. O conteúdo deve conter o campo cod preenchido.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso a postagem com o campo código preenchido.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func updatePostageContent(postageCod postageCod: Int, postageContent: APCPostageContent, result: (operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.updatePostageContent(postageCod: postageCod, postageContent: postageContent, result: result)
                    }else{
                        result(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    if postageContent.cod == 0{
                        result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 20, userInfo: [NSLocalizedDescriptionKey : "The content must have a cod != 0 to be updated"]),status: .InvalidParamters))
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
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
        
    }
    
    /**
     Exclui um conteúdo de postagem na plataforma. Requer autenticação.
     - parameter postageCod Código da postagem à qual pertence o conteúdo.
     - parameter postageContentCod Código do conteúdo que será excluído.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func deletePostageContent(postageCod postageCod: Int, postageContentCod: Int, result: (operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.deletePostageContent(postageCod: postageCod, postageContentCod: postageContentCod, result: result)
                    }else{
                        result(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(.DELETE, APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: postageContentCod), parameters: nil, encoding: .URL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    /**
     Encontra os dados de um conteúdo de postagem na plataforma por código. Requer autenticação.
     - parameter postageCod Código da postagem à qual pertence o conteúdo.
     - parameter postageContentCod Código do conteúdo que será buscado.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso um objeto de APCPostageContent no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func findPostageContent(postageCod postageCod: Int,contentCod: Int,result: (operationResponse: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.findPostageContent(postageCod: postageCod, contentCod: contentCod, result: result)
                    }else{
                        result(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = session.sessionToken {
                    let headers = ["appToken" : token]
                    Alamofire.request(.GET, APCURLProvider.postageContentURL(postageCod: postageCod, contentCod: contentCod), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                        self.findPostageContentResponseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }

    }
    
    /**
     Método de busca conteúdos de uma postagem. O método busca os conteúdos a partir da propriedade contentsCodes no objeto de postagem.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso um array com os conteúdos da postagem como resultado além de popular a propriedade contents no objeto de postagem enviado como parâmetro.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func postageContents(postage postage: APCPostage, result: (operationResponse: APCOperationResponse)-> Void){
        let contents = [APCPostageContent]()
        if !postage.contentsCodes.isEmpty {
            self.postageContents(contents, postageCod: postage.cod, contentsCods: postage.contentsCodes, index: 0,  result: {(operationResponse) in
                if let pcontents = operationResponse.data as? [APCPostageContent]{
                    postage.contents = pcontents
                }
                result(operationResponse: operationResponse)
            })
        }
    }
    
    /**
     Método de busca conteúdos de várias postagens. O método busca os conteúdos a partir da propriedade contentsCodes no objeto de postagem.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e se sucesso irá popular a propriedade contents nos objetos de postagem enviados como parâmetro.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func postagesContents(postages postages: [APCPostage], result: (operationResponse: APCOperationResponse)-> Void){
        self.postagensContents(postages: postages, index: 0, result: result)
    }
    
    
    private func postagensContents(postages postages: [APCPostage], index: Int, result: (operationResponse: APCOperationResponse)-> Void){
        if index >= postages.count {
            result(operationResponse: APCOperationResponse(data: nil, status: .CompletedSuccesfully))
        }else{
            self.postageContents(postage: postages[index], result: { (operationResponse) in
                
                switch operationResponse.status{
                case .CompletedSuccesfully, .ResourceNotFound, .NoContentReturned:
                    self.postagensContents(postages: postages, index: index + 1, result: result)
                default:
                    result(operationResponse: operationResponse)
                }
            })
        }
    }
    
    
    private func postageContents(contents: [APCPostageContent],postageCod: Int, contentsCods: [Int], index: Int, result: (operationResponse: APCOperationResponse)-> Void ){
        var localContents : [APCPostageContent] = []
        localContents.appendContentsOf(contents)
        if index >= contentsCods.count {
            result(operationResponse: APCOperationResponse(data: localContents, status: .CompletedSuccesfully))
        }else{
            self.findPostageContent(postageCod: postageCod, contentCod: contentsCods[index], result: { (operationResponse) in
                
                switch operationResponse.status{
                case .CompletedSuccesfully, .ResourceNotFound, .NoContentReturned:
                    if let content = operationResponse.data as? APCPostageContent {
                        localContents.append(content)
                    }
                    self.postageContents(localContents, postageCod: postageCod, contentsCods: contentsCods, index: index + 1, result: result)
                default:
                    result(operationResponse: operationResponse)
                }
            })
        }
    }
    
    //MARK: - Postage content handlers
    private func postageContentCreateResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){
        
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
    
    private func updatePostageContentResponseHandler(postage postageContent: APCPostageContent,response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, reponseHeaders) -> AnyObject? in
            return postageContent
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    private func findPostageContentResponseHandler(response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let contentDic = responseValue as? [String : AnyObject] {
                return JsonObjectCreator.createObject(dictionary: contentDic, objectClass: APCPostageContent.self)
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    

}