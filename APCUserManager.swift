//
//  APCUserManger.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation
import Alamofire

public let TokenValidDaysInterval: Int = 7
public let DayInSeconds : Double = 60 * 60 * 24

typealias ResultBlock = @convention(block)(APCOperationResponse) -> Void

open class APCUserManager: NSObject {
    
    
    static open let sharedManager = APCUserManager()
    
    
    open fileprivate(set) var activeSession: APCUserSession?
    
    open var isSessionActive: Bool {
        return self.activeSession != nil
    }
    
    
    
    
    //MARK:- Initializers
    fileprivate override init() {
        super.init()
        self.loadCurrentSession()
    }
    
    
    //MARK:- Control methods
    fileprivate func saveCurrentSession(){
        if let unwrappedSession = self.activeSession {
            let archivedSession = NSKeyedArchiver.archivedData(withRootObject: unwrappedSession)
            let defaults = UserDefaults.standard
            defaults.set(archivedSession, forKey: "current_session")
            defaults.synchronize()
            if unwrappedSession.currentUser?.userAccountType == .apcAccount {
                if let unwrappedUser = self.activeSession?.currentUser, let unwrappedPass = unwrappedUser.password {
                    _ = self.saveUserPass(email: unwrappedUser.email, password: unwrappedPass)
                }
            }
        }
    }
    
    fileprivate func loadCurrentSession() {
        let defaults = UserDefaults.standard
        if let sessionData = defaults.object(forKey: "current_session") as? Data,let unachivedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? APCUserSession {
            self.activeSession = unachivedSession
            if let unwrappedUser = activeSession?.currentUser {
                if unwrappedUser.userAccountType == .apcAccount {
                    unwrappedUser.password = self.loadUserPass(email: unwrappedUser.email)
                }
            }
        }
        
        
    }
    
    fileprivate func saveUserPass(email: String, password: String) -> Bool{
        return KeychainWrapper.standardKeychainAccess().setString(password, forKey: email)
    }
    
    fileprivate func loadUserPass(email: String)-> String? {
        return KeychainWrapper.standardKeychainAccess().stringForKey(email)
    }
    
    fileprivate func clearPassword() {
        _ = KeychainWrapper.standardKeychainAccess().removeAllKeys()
    }
    

    /**
        Remove a sessão atualmente ativa limpando todos os dados relativos.
     
     */
    open func clearSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "current_session")
        defaults.synchronize()
        self.clearPassword()
        self.activeSession = nil
    }
    
    //MARK:- Authentication methods
    /**
        Autentica usuário com conta padrão do TCU. Se o login for efetuado com sucesso, o método irá preencher automaticamente a propriedade -activeSession
        - parameter email E-mail do usuário.
        - parameter password Senha do usuário.
        - parameter @optional appIdentifier Numero correspondente ao App no Servidor do TCU. Exemplo: 100 - Código do App Mapa da Saúde.
        - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
        - see APCOperationResponse.swift
    */
    open func authenticate(email: String, password: String, result: ((_ operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "senha" : password]
        
        Alamofire.request(APCURLProvider.authenticateUserURL(), method: .post, parameters: nil, encoding: URLEncoding(), headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(password: password, response: responseObject, result: result)
        }
    }
    
    /**
     Autentica usuário com o facebook. Se o login for efetuado com sucesso, o método irá preencher automaticamente a propriedade -activeSession
     - parameter email E-mail do usuário.
     - parameter facebookToken Token do facebook do usuário.
     - parameter @optional appIdentifier Numero correspondente ao App no Servidor do TCU. Exemplo: 100 - Código do App Mapa da Saúde.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func authenticateFacebook(email: String, facebookToken: String, result: ((_ operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "facebookToken" : facebookToken]
        
        Alamofire.request(APCURLProvider.authenticateUserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(password: nil, response: responseObject, result: result)
        }
    }
    /**
    Autentica usuário com o twitter. Se o login for efetuado com sucesso, o método irá preencher automaticamente a propriedade -activeSession
    - parameter email E-mail do usuário.
    - parameter facebookToken Token do facebook do usuário.
    - parameter @optional appIdentifier Numero correspondente ao App no Servidor do TCU. Exemplo: 100 - Código do App Mapa da Saúde.
    - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
    - see APCOperationResponse.swift
    */
    open func authenticateTwitter(email: String, twitterToken: String, result: ((_ operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "twitterToken" : twitterToken]
        
        Alamofire.request(APCURLProvider.authenticateUserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(password: nil, response: responseObject, result: result)
        }
    }
    
    
    //MARK:- Register Method
    
     /**
     Cadastra um usuário. Se o cadastro for efetuado com sucesso, o método irá authenticar e preencher automaticamente  propriedade -activeSession
     Caso o e-mail já esteja cadastrado na plataforma o resultado será APCOperationResultStatus.InvalidParamters.
     - parameter user Objeto de usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func registerUser(user: APCUser,  result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        if let request = self.requestForRegisterUser(user: user) {
            Alamofire.request(request).responseData(completionHandler: { (responseObject) in
                if let unwrappedResponse = responseObject.response {
                    switch unwrappedResponse.statusCode {
                    case 201:
                        self.backgroundAuthentication(user: user, result: result)
                    case 400:
                        result(APCOperationResponse(data: nil, status: .invalidParamters))
                    case 500:
                        result(APCOperationResponse(data: nil, status:.internalServerError))
                    default:
                        result(APCOperationResponse(data: nil, status: .connectionError))
                    }
                }
            })
        }else{
            result(APCOperationResponse(data: nil, status: .invalidParamters))
        }
    }
    
    
    //MARK:- Update Method
    
    /**
     Atualiza dados de um usuário.
     - parameter user Objeto de usuário. A propriedade cod do objeto deve estar preenchida para que a operação de atualização seja realizada.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func updateUser(user: APCUser,  result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        if user.cod != 0 {
            if let unwrappedSession = self.activeSession {
                if unwrappedSession.isSessionExpired {
                    self.refreshSession({ (operationResult) in
                        if operationResult.status == .completedSuccesfully {
                            self.updateUser(user: user, result: result)
                        }else{
                            result(operationResult)
                        }
                    })
                }else{
                    if let token = self.activeSession?.sessionToken {
                        var userData = user.asDictionary()
                        userData.removeValue(forKey: "cod")
                        userData.removeValue(forKey: "senha")
                        userData.removeValue(forKey: "email")
                        userData.removeValue(forKey: "emailVerificado")
                        let headers = ["appToken" : token]
                        
                        Alamofire.request(APCURLProvider.userURL(cod: user.cod), method: .post, parameters: userData, encoding: JSONEncoding(), headers: headers).responseJSON(completionHandler: { (responseObject) in
                   
                            APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                                return user
                                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
                        })
                    }
                }
            }else{
                result(APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
            }

        }else{
            result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 20, userInfo: [NSLocalizedDescriptionKey : "The user must have a cod != 0 to be updated"]),status: .invalidParamters))
        }
    }
    
    //MARK: - User picture methods
    /**
     
     Busca a foto de perfil do usuário.
     
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas/27/fotoPerfil
     - parameter userCod Código do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta com a imagem no campo data.
     - see APCOperationResponse.swift
     */

    open func getUserPicture(userCod cod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        Alamofire.request(APCURLProvider.userPictureURL(userCod: cod), method: .get).responseData(completionHandler: { (responseData) in
            self.getUserPictureResponseHandler(response: responseData, result: result)
        })
    }
    
    /**
     
     Cadastra a foto de perfil do usuário.
     
     Relacionado ao endpoint - POST: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas/27/fotoPerfil
     - parameter userCod Código do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto com o status da operação.
     - see APCOperationResponse.swift
     */
    open func setUserPicture(userCod cod: Int, picture: UIImage, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        if let unwrappedSession = self.activeSession {
            if unwrappedSession.isSessionExpired {
                self.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.setUserPicture(userCod: cod, picture: picture, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    if let imageData = UIImagePNGRepresentation(picture) {
                        
                        Alamofire.upload(
                            multipartFormData: { multipartFormData in
                                multipartFormData.append(imageData, withName: "file", fileName: "picture.png", mimeType: "image/png")
                                
                            },
                            usingThreshold: 4194304,
                            to: APCURLProvider.userPictureURL(userCod: cod),
                            headers: ["appToken" : token ],
                            encodingCompletion: { encodingResult in
                                switch encodingResult {
                                case .success(let upload, _, _):
                                    upload.responseJSON { response in
                                        if let unwrappedResponse = response.response{
                                            self.setPictureResponseHandler(unwrappedResponse, result: result)
                                        }
                                    }
                                case .failure(let encodingError):
                                    let _ = encodingError
                                    result(APCOperationResponse(data: nil, status: APCOperationResultStatus.noContentReturned))
                                    break
                                }
                            }
                        )
                    
                    }
                }
            }
        }else{
            result(APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }

    }
    
    fileprivate func setPictureResponseHandler(_ response: HTTPURLResponse , result: (_ operationResponse: APCOperationResponse)-> Void){
        
        switch response.statusCode {
            case 200,201:
                result(APCOperationResponse(data: nil, status: .completedSuccesfully))
            case 404:
                result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 404, userInfo: [NSLocalizedDescriptionKey : "The user with the code provided can't not be founded."]), status: APCOperationResultStatus.resourceNotFound))
            case 401:
                result(APCOperationResponse(data: nil, status: APCOperationResultStatus.operationUnauthorized))
            case 400:
                result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 400, userInfo: [NSLocalizedDescriptionKey : "An error to process the image on the server or the picture sended must have the size larger than max size allowed of 4MB."]), status: APCOperationResultStatus.invalidParamters))
            case 403:
                result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 403, userInfo: [NSLocalizedDescriptionKey : "The user owner of token isn't the same of the cod porvided."]), status: APCOperationResultStatus.operationUnauthorized))
            default:
                break
        }
    }
    
    fileprivate func getUserPictureResponseHandler(response responseObject: DataResponse<Data>, result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        if let unwrappedStatusCode = responseObject.response?.statusCode{
            switch unwrappedStatusCode {
            case 200:
                if let imageData = responseObject.data {
                    result?(APCOperationResponse(data: UIImage(data: imageData), status: .completedSuccesfully))
                }
            case 404:
                result?(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 404, userInfo: [NSLocalizedDescriptionKey : "The user not have a picture"]), status: APCOperationResultStatus.resourceNotFound))
            default:
                result?(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 56, userInfo: [NSLocalizedDescriptionKey : "Something wrong than expected."]), status: APCOperationResultStatus.resourceNotFound))
            }
        }
        
    }
    
    //MARK: - Find methods
    /**
     Encontra os dados de uma pessoa a partir do cod. Se encontrado o campo data em operationResponse retornará preenchido com um objeto APCUser com os dados do usuário.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas/{codPessoa}
     - parameter cod Código do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func find(cod: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.userURL(cod: cod), method: .get, parameters: nil, encoding: URLEncoding(), headers: nil).responseJSON { (responseObject) in
            
            APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                if let userData = responseValue as? [String : AnyObject]{
                    return JsonObjectCreator.createObject(dictionary: userData, objectClass: APCUser.self)
                }
                return nil

                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
        }
    }
    
    /**
     Encontra os dados de uma pessoa a partir do email. Se encontrado o campo data em operationResponse retornará preenchido com um objeto APCUser com os dados do usuário.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter email email do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func find(email: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["email" : email]).responseJSON { (responseObject) in
            self.findResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Encontra os dados de uma pessoa a partir do token do Facebook. Se encontrado o campo data em operationResponse retornará preenchido com um objeto APCUser com os dados do usuário.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter facebookToken token do facebook do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func find(facebookToken: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["facebookToken" : facebookToken]).responseJSON { (responseObject) in
            self.findResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Encontra os dados de uma pessoa a partir do token do Twitter. Se encontrado o campo data em operationResponse retornará preenchido com um objeto APCUser com os dados do usuário.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter twitterToken token do Twitter do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func find(twitterToken: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["twitterToken" : twitterToken]).responseJSON { (responseObject) in
            self.findResponseHandler(response: responseObject, result: result)
        }
        
    }
    
    //MARK: - Find Convenience
    fileprivate func findResponseHandler(response responseObject: DataResponse<Any>, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let users =  responseValue as? [[String : AnyObject]]{
                if !users.isEmpty {
                    return JsonObjectCreator.createObject(dictionary: users[0], objectClass: APCUser.self)
                }
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    fileprivate func existsResponseHandler(response responseObject: DataResponse<Any>, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){

        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            return true as AnyObject
            }, onNotFound: { (responseValue, responseHeaders) -> AnyObject? in
                return false as AnyObject
            }, onUnauthorized: { (responseValue, responseHeaders) -> AnyObject? in
                return false as AnyObject
            }, onInvalidParameters: { (responseValue, responseHeaders) -> AnyObject? in
                return false as AnyObject
            }, onConnectionError: { (responseValue, responseHeaders) -> AnyObject? in
                return false as AnyObject
            }, result: result)
    }
    
    /**
     Verifica se um email já se encontra cadastrado. O campo data em operationResponse retornará preenchido com o booleano que indica se ele existe ou não.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter twitterToken token do Twitter do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func exists(email: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void) {
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["email" : email]).responseJSON { (responseObject) in
            self.existsResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Verifica se um token do facebook já se encontra cadastrado. O campo data em operationResponse retornará preenchido com o booleano que indica se ele existe ou não.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter twitterToken token do Twitter do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func exists(facebookToken: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["facebookToken" : facebookToken]).responseJSON { (responseObject) in
            self.existsResponseHandler(response: responseObject, result: result)
        }
    }
    
    
    /**
     Verifica se um token do twitter já se encontra cadastrado. O campo data em operationResponse retornará preenchido com o booleano que indica se ele existe ou não.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter twitterToken token do Twitter do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    open func exists(twitterToken: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.userBaserURL(), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["twitterToken" : twitterToken]).responseJSON { (responseObject) in
            self.existsResponseHandler(response: responseObject, result: result)
        }
    }
    
    fileprivate func requestForRegisterUser(user: APCUser)-> URLRequest? {
        let userAsDictionary = user.asDictionary()
        if let jsonData = try? JSONSerialization.data(withJSONObject: userAsDictionary, options: .prettyPrinted){
            let request = NSMutableURLRequest(url: APCURLProvider.userBaserURL() as URL)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request as URLRequest
        }
        return nil
    }
    
    //MARK:- Redefine Password
    /**
        Gera uma senha aleatória e a envia por email para o usuário. Requer autenticação.
        - parameter email E-mail do usuário que irá resetar a senha.
        - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
        - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func redefinePassword(email: String, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        
        Alamofire.request(APCURLProvider.redefinePasswordURL(), method: .post, parameters: ["email" : email], encoding: URLEncoding(), headers: nil).responseJSON { (responseObject) in

            if let unwrappedStatusCode = responseObject.response?.statusCode {
                switch(unwrappedStatusCode){
                case 200:
                    result(APCOperationResponse(data: nil, status: .completedSuccesfully))
                    break
                case 404:
                    result(APCOperationResponse(data: nil, status: .resourceNotFound))
                    break
                case 500:
                    result(APCOperationResponse(data: nil, status: .internalServerError))
                    break
                case 401:
                    result(APCOperationResponse(data: nil, status: .operationUnauthorized))
                    break
                default:
                    break
                }
            }else{
                result(APCOperationResponse(data: nil, status: .connectionError))
            }
        }
        
    }
   
    
    //MARK:- Useful methods
    fileprivate func authenticationResponseHandler(password passowrd: String?, response responseObject: Alamofire.DataResponse<Any>, result: ((_ operationResponse: APCOperationResponse)-> Void)?) {
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in

            if let uwrappedHeaders : [String : AnyObject] = responseHeaders as? [String : AnyObject] {
                let appToken = uwrappedHeaders["appToken"] as! String
                let fm = DateFormatter()
                fm.locale = Locale(identifier: "en_US")
                fm.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                let expirationDate = fm.date(from: uwrappedHeaders["Date"] as! String)?.addingTimeInterval(DayInSeconds * (Double(TokenValidDaysInterval) - 1.0))
                let user = JsonObjectCreator.createObject(dictionary: responseValue as! [String : AnyObject], objectClass: APCUser.self) as! APCUser
                let session = APCUserSession(user: user, token: appToken, expirationDate: expirationDate!)
                session.currentUser?.password = passowrd
                self.activeSession = session
                self.saveCurrentSession()
                return session
            }else{
                return nil
            }
            //return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    
    //MARK:- Request New Session
    open func refreshSession(_ result: @escaping (_ operationResult: APCOperationResponse)-> Void){
        if let unwrappedSession = self.activeSession, let unwrappedUser = unwrappedSession.currentUser {
            self.backgroundAuthentication(user: unwrappedUser, result: result)
        }
    }
    
    //MARK:- Background authentication
    fileprivate func backgroundAuthentication(user: APCUser,result: @escaping (_ operationStatus: APCOperationResponse)-> Void ){
        if let unwrappedAccountType = user.userAccountType {
            switch unwrappedAccountType {
            case .apcAccount:
                if let unwrappedPass = user.password {
                    self.authenticate(email: user.email, password: unwrappedPass, result: { (operationResponse) in
                        result(operationResponse)
                    })
                }
                break
            case .facebookAccount:
                if let unwrappedFacebookToken = user.tokenFacebook {
                    self.authenticateFacebook(email: user.email, facebookToken: unwrappedFacebookToken, result: { (operationResponse) in
                        result(operationResponse)
                    })
                }
                break
            case .twitterAccount:
                if let unwrappedTwitterToken = user.tokenTwitter {
                    self.authenticateTwitter(email: user.email, twitterToken: unwrappedTwitterToken, result: { (operationResponse) in
                        result(operationResponse)
                    })
                }
                break
            default:
                break
            }
        }
    }
    
}

//MARK: Profile methods
extension APCUserManager {
    
    
    /**
     Cria um perfil e associa à um usuário no aplicativo. Requer autenticação.
     - parameter userCod Código do usuário à que será associado o perfil.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func associateProfile(userCod user: Int, profile: APCProfile, result: @escaping (_ operationResult: APCOperationResponse)-> Void){
        
        if let unwrappedSession = self.activeSession {
            if unwrappedSession.isSessionExpired {
                self.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.associateProfile(userCod: user, profile: profile, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    
                    let profileData = profile.asDictionary()
                    
                    Alamofire.request(APCURLProvider.userProfileURL(userCod: user), method: .post, parameters: profileData, encoding: JSONEncoding(), headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .operationUnauthorized))
        }
    }
    
    
    /**
     Busca o perfil do usuário no aplicativo.
     - parameter userCod Código do usuário à que será buscado o perfil.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func getUserProfile(userCod: Int, result: @escaping (_ operationResult: APCOperationResponse)-> Void){
        if let appCod = APCApplication.sharedApplication.applicationCode {
            
            Alamofire.request(APCURLProvider.userProfileURL(userCod: userCod), method: .get, parameters: nil, encoding: URLEncoding(), headers: ["appIdentifier": String(appCod)]).responseJSON(completionHandler: { (responseObject) in
                self.getUserProfileResponseHandler(response: responseObject, result: result)
            })
        }
    }
    
    
    
    /**
     Altera os dados do perfil de um usuário associado à um usuário no aplicativo. Requer autenticação.
     - parameter userCod Código do usuário à que será atualizado o perfil.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func updateUserProfile(userCod user: Int, profile: APCProfile, result: @escaping (_ operationResult: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .completedSuccesfully {
                        self.updateUserProfile(userCod: user, profile: profile, result: result)
                    }else{
                        result(operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    var profileData = profile.asDictionary()
                    profileData.updateValue(true as AnyObject, forKey: "verificado")
                    
                    Alamofire.request(APCURLProvider.userProfileURL(userCod: user), method: .put, parameters: profileData, encoding: JSONEncoding(), headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(APCOperationResponse(data: nil, status: .operationUnauthorized))
        }
    }
    /**
     Exclui perfil de um usuário em um no aplicativo. Requer autenticação.
     - parameter userCod Código do usuário que terá o perfil excluído.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func deleteUserProfile(userCod: Int, result: @escaping (_ operationResult: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if let appCod = APCApplication.sharedApplication.applicationCode {
                if session.isSessionExpired {
                    APCUserManager.sharedManager.refreshSession({ (operationResult) in
                        if operationResult.status == .completedSuccesfully {
                            self.deleteUserProfile(userCod: userCod, result: result)
                        }else{
                            result(operationResult)
                        }
                    })
                }else{
                    if let token = self.activeSession?.sessionToken {
                        let headers = ["appToken" : token , "appIdentifier" : String(appCod)]
                        
                        
                        Alamofire.request(APCURLProvider.userProfileURL(userCod: userCod), method: .delete, parameters: nil, encoding: URLEncoding(), headers: headers).responseJSON(completionHandler: { (responseObject) in
                            APCManagerUtils.responseHandler(response: responseObject, result: result)
                        })
                    }
                }
            }else{
                result(APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .operationUnauthorized))
            }
        }else{
            result(APCOperationResponse(data: nil, status: .operationUnauthorized))
        }
    }
    
    
    //MARK: - Profile response handlers
    
    fileprivate func getUserProfileResponseHandler(response responseObject: DataResponse<Any>, result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, reponseHeaders) -> AnyObject? in
            if let profileData = responseValue as? [String : AnyObject]{
                return JsonObjectCreator.createObject(dictionary: profileData, objectClass: APCProfile.self)
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    
}



