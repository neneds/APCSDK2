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

public class APCUserManager: NSObject {
    
    
    static public let sharedManager = APCUserManager()
    
    
    public private(set) var activeSession: APCUserSession?
    
    public var isSessionActive: Bool {
        return self.activeSession != nil
    }
    
    
    
    
    //MARK:- Initializers
    private override init() {
        super.init()
        self.loadCurrentSession()
    }
    
    
    //MARK:- Control methods
    private func saveCurrentSession(){
        if let unwrappedSession = self.activeSession {
            let archivedSession = NSKeyedArchiver.archivedDataWithRootObject(unwrappedSession)
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(archivedSession, forKey: "current_session")
            defaults.synchronize()
            if unwrappedSession.currentUser?.userAccountType == .APCAccount {
                if let unwrappedUser = self.activeSession?.currentUser, let unwrappedPass = unwrappedUser.password {
                    self.saveUserPass(email: unwrappedUser.email, password: unwrappedPass)
                }
            }
        }
    }
    
    private func loadCurrentSession() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let sessionData = defaults.objectForKey("current_session") as? NSData,let unachivedSession = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as? APCUserSession {
            self.activeSession = unachivedSession
            if let unwrappedUser = activeSession?.currentUser {
                if unwrappedUser.userAccountType == .APCAccount {
                    unwrappedUser.password = self.loadUserPass(email: unwrappedUser.email)
                }
            }
        }
        
        
    }
    
    private func saveUserPass(email email: String, password: String) -> Bool{
        return KeychainWrapper.standardKeychainAccess().setString(password, forKey: email)
    }
    
    private func loadUserPass(email email: String)-> String? {
        return KeychainWrapper.standardKeychainAccess().stringForKey(email)
    }
    
    private func clearPassword() {
        KeychainWrapper.standardKeychainAccess().removeAllKeys()
    }
    

    /**
        Remove a sessão atualmente ativa limpando todos os dados relativos.
     
     */
    public func clearSession() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("current_session")
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
    public func authenticate(email email: String, password: String, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "senha" : password]
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
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
    public func authenticateFacebook(email email: String, facebookToken: String, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "facebookToken" : facebookToken]
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
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
    public func authenticateTwitter(email email: String, twitterToken: String, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        let headers :[String : String] =  ["email" : email, "twitterToken" : twitterToken]
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
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
    public func registerUser(user user: APCUser,  result: (operationResponse: APCOperationResponse)-> Void) {
        if let request = self.requestForRegisterUser(user: user) {
            Alamofire.request(request).responseData(completionHandler: { (responseObject) in
                if let unwrappedResponse = responseObject.response {
                    switch unwrappedResponse.statusCode {
                    case 201:
                        self.backgroundAuthentication(user: user, result: result)
                    case 400:
                        result(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
                    case 500:
                        result(operationResponse: APCOperationResponse(data: nil, status:.InternalServerError))
                    default:
                        result(operationResponse: APCOperationResponse(data: nil, status: .ConnectionError))
                    }
                }
            })
        }else{
            result(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
        }
    }
    
    
    //MARK:- Update Method
    
    /**
     Atualiza dados de um usuário.
     - parameter user Objeto de usuário. A propriedade cod do objeto deve estar preenchida para que a operação de atualização seja realizada.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    public func updateUser(user user: APCUser,  result: (operationResponse: APCOperationResponse)-> Void) {
        if user.cod != 0 {
            if let unwrappedSession = self.activeSession {
                if unwrappedSession.isSessionExpired {
                    self.refreshSession({ (operationResult) in
                        if operationResult.status == .CompletedSuccesfully {
                            self.updateUser(user: user, result: result)
                        }else{
                            result(operationResponse: operationResult)
                        }
                    })
                }else{
                    if let token = self.activeSession?.sessionToken {
                        var userData = user.asDictionary()
                        userData.removeValueForKey("cod")
                        userData.removeValueForKey("senha")
                        userData.removeValueForKey("email")
                        userData.removeValueForKey("emailVerificado")
                        let headers = ["appToken" : token]
                        Alamofire.request(.POST, APCURLProvider.userURL(cod: user.cod), parameters: userData, encoding: .JSON, headers: headers).responseJSON(completionHandler: { (responseObject) in
                   
                            APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
                                return user
                                }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
                        })
                    }
                }
            }else{
                result(operationResponse: APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
            }

        }else{
            result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 20, userInfo: [NSLocalizedDescriptionKey : "The user must have a cod != 0 to be updated"]),status: .InvalidParamters))
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
    public func getUserPicture(userCod cod: Int, result: (operationResponse: APCOperationResponse)-> Void) {
        Alamofire.request(.GET, APCURLProvider.userPictureURL(userCod: cod)).responseData(completionHandler: { (responseData) in
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
    public func setUserPicture(userCod cod: Int, picture: UIImage, result: (operationResponse: APCOperationResponse)-> Void){
        if let unwrappedSession = self.activeSession {
            if unwrappedSession.isSessionExpired {
                self.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.setUserPicture(userCod: cod, picture: picture, result: result)
                    }else{
                        result(operationResponse: operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    if let imageData = UIImagePNGRepresentation(picture) {
                        Alamofire.upload(.POST, APCURLProvider.userPictureURL(userCod: cod), headers: ["appToken" : token ], multipartFormData: { (multipartForm) in
                            multipartForm.appendBodyPart(data: imageData, name: "file", fileName: "picture.png", mimeType: "image/png")
                        }, encodingMemoryThreshold: 4194304, encodingCompletion: { (encodeResult) in
                            switch encodeResult {
                            case .Success(let request, _, _):
                                request.response(completionHandler: { (_,response, _, _) -> Void in
                                    if let unwrappedResponse = response{
                                        self.setPictureResponseHandler(unwrappedResponse, result: result)
                                    }
                                })
                                break
                            case .Failure(_):
                                result(operationResponse: APCOperationResponse(data: nil, status: APCOperationResultStatus.NoContentReturned))
                                break
                            }

                        })
                    }
                }
            }
        }else{
            result(operationResponse: APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }

    }
    
    private func setPictureResponseHandler(response: NSHTTPURLResponse , result: (operationResponse: APCOperationResponse)-> Void){
        
        switch response.statusCode {
            case 200,201:
                result(operationResponse: APCOperationResponse(data: nil, status: .CompletedSuccesfully))
            case 404:
                result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 404, userInfo: [NSLocalizedDescriptionKey : "The user with the code provided can't not be founded."]), status: APCOperationResultStatus.ResourceNotFound))
            case 401:
                result(operationResponse: APCOperationResponse(data: nil, status: APCOperationResultStatus.OperationUnauthorized))
            case 400:
                result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 400, userInfo: [NSLocalizedDescriptionKey : "An error to process the image on the server or the picture sended must have the size larger than max size allowed of 4MB."]), status: APCOperationResultStatus.InvalidParamters))
            case 403:
                result(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 403, userInfo: [NSLocalizedDescriptionKey : "The user owner of token isn't the same of the cod porvided."]), status: APCOperationResultStatus.OperationUnauthorized))
            default:
                break
        }
    }
    
    private func getUserPictureResponseHandler(response responseObject: Response<NSData, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        if let unwrappedStatusCode = responseObject.response?.statusCode{
            switch unwrappedStatusCode {
            case 200:
                if let imageData = responseObject.data {
                    result?(operationResponse: APCOperationResponse(data: UIImage(data: imageData), status: .CompletedSuccesfully))
                }
            case 404:
                result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 404, userInfo: [NSLocalizedDescriptionKey : "The user not have a picture"]), status: APCOperationResultStatus.ResourceNotFound))
            default:
                result?(operationResponse: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 56, userInfo: [NSLocalizedDescriptionKey : "Something wrong than expected."]), status: APCOperationResultStatus.ResourceNotFound))
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
    public func find(cod cod: Int, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.userURL(cod: cod), parameters: nil, encoding: .URLEncodedInURL, headers: nil).responseJSON { (responseObject) in
            
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
    public func find(email email: String, result: (operationResponse: APCOperationResponse)-> Void) {
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["email" : email]).responseJSON { (responseObject) in
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
    public func find(facebookToken facebookToken: String, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["facebookToken" : facebookToken]).responseJSON { (responseObject) in
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
    public func find(twitterToken twitterToken: String, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["twitterToken" : twitterToken]).responseJSON { (responseObject) in
            self.findResponseHandler(response: responseObject, result: result)
        }
        
    }
    
    //MARK: - Find Convenience
    private func findResponseHandler(response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let users =  responseValue as? [[String : AnyObject]]{
                if !users.isEmpty {
                    return JsonObjectCreator.createObject(dictionary: users[0], objectClass: APCUser.self)
                }
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    private func existsResponseHandler(response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){

        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            return true
            }, onNotFound: { (responseValue, responseHeaders) -> AnyObject? in
                return false
            }, onUnauthorized: { (responseValue, responseHeaders) -> AnyObject? in
                return false
            }, onInvalidParameters: { (responseValue, responseHeaders) -> AnyObject? in
                return false
            }, onConnectionError: { (responseValue, responseHeaders) -> AnyObject? in
                return false
            }, result: result)
    }
    
    /**
     Verifica se um email já se encontra cadastrado. O campo data em operationResponse retornará preenchido com o booleano que indica se ele existe ou não.
     Relacionado ao endpoint - GET: http://mobile-aceite.tcu.gov.br/appCivicoRS/rest/pessoas
     - parameter twitterToken token do Twitter do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    public func exists(email email: String, result: (operationResponse: APCOperationResponse)-> Void) {
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["email" : email]).responseJSON { (responseObject) in
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
    public func exists(facebookToken facebookToken: String, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["facebookToken" : facebookToken]).responseJSON { (responseObject) in
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
    public func exists(twitterToken twitterToken: String, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.GET, APCURLProvider.userBaserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: ["twitterToken" : twitterToken]).responseJSON { (responseObject) in
            self.existsResponseHandler(response: responseObject, result: result)
        }
    }
    
    private func requestForRegisterUser(user user: APCUser)-> NSURLRequest? {
        let userAsDictionary = user.asDictionary()
        if let jsonData = try? NSJSONSerialization.dataWithJSONObject(userAsDictionary, options: .PrettyPrinted){
            let request = NSMutableURLRequest(URL: APCURLProvider.userBaserURL())
            request.HTTPMethod = "POST"
            request.HTTPBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request
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
    public func redefinePassword(email email: String, result: (operationResponse: APCOperationResponse)-> Void){
        Alamofire.request(.POST, APCURLProvider.redefinePasswordURL(), parameters: ["email" : email], encoding: .URL, headers: nil).responseData { (responseObject) in
            if let unwrappedStatusCode = responseObject.response?.statusCode {
                switch(unwrappedStatusCode){
                case 200:
                    result(operationResponse: APCOperationResponse(data: nil, status: .CompletedSuccesfully))
                    break
                case 404:
                    result(operationResponse: APCOperationResponse(data: nil, status: .ResourceNotFound))
                    break
                case 500:
                    result(operationResponse: APCOperationResponse(data: nil, status: .InternalServerError))
                    break
                case 401:
                    result(operationResponse: APCOperationResponse(data: nil, status: .OperationUnauthorized))
                    break
                default:
                    break
                }
            }else{
                result(operationResponse: APCOperationResponse(data: nil, status: .ConnectionError))
            }
        }
        
    }
    
    
    //MARK:- Useful methods
    private func authenticationResponseHandler(password passowrd: String?, response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let uwrappedHeaders  = responseHeaders {
                let appToken = uwrappedHeaders["apptoken"] as! String
                let fm = NSDateFormatter()
                fm.locale = NSLocale(localeIdentifier: "en_US")
                fm.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                let expirationDate = fm.dateFromString(uwrappedHeaders["date"] as! String)?.dateByAddingTimeInterval(DayInSeconds * (Double(TokenValidDaysInterval) - 1.0))
                let user = JsonObjectCreator.createObject(dictionary: responseValue as! [String : AnyObject], objectClass: APCUser.self) as! APCUser
                let session = APCUserSession(user: user, token: appToken, expirationDate: expirationDate!)
                session.currentUser?.password = passowrd
                self.activeSession = session
                self.saveCurrentSession()
                return session
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    
    //MARK:- Request New Session
    public func refreshSession(result: (operationResult: APCOperationResponse)-> Void){
        if let unwrappedSession = self.activeSession, let unwrappedUser = unwrappedSession.currentUser {
            self.backgroundAuthentication(user: unwrappedUser, result: result)
        }
    }
    
    //MARK:- Background authentication
    private func backgroundAuthentication(user user: APCUser,result: (operationStatus: APCOperationResponse)-> Void ){
        if let unwrappedAccountType = user.userAccountType {
            switch unwrappedAccountType {
            case .APCAccount:
                if let unwrappedPass = user.password {
                    self.authenticate(email: user.email, password: unwrappedPass, result: { (operationResponse) in
                        result(operationStatus: operationResponse)
                    })
                }
                break
            case .FacebookAccount:
                if let unwrappedFacebookToken = user.tokenFacebook {
                    self.authenticateFacebook(email: user.email, facebookToken: unwrappedFacebookToken, result: { (operationResponse) in
                        result(operationStatus: operationResponse)
                    })
                }
                break
            case .TwitterAccount:
                if let unwrappedTwitterToken = user.tokenTwitter {
                    self.authenticateTwitter(email: user.email, twitterToken: unwrappedTwitterToken, result: { (operationResponse) in
                        result(operationStatus: operationResponse)
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
    public func associateProfile(userCod user: Int, profile: APCProfile, result: (operationResult: APCOperationResponse)-> Void){
        
        if let unwrappedSession = self.activeSession {
            if unwrappedSession.isSessionExpired {
                self.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.associateProfile(userCod: user, profile: profile, result: result)
                    }else{
                        result(operationResult: operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    
                    let profileData = profile.asDictionary()
                    Alamofire.request(.POST, APCURLProvider.userProfileURL(userCod: user), parameters: profileData, encoding: .JSON, headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(operationResult: APCOperationResponse(data:  NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have a active session to perform this operation. See APCUserManager.sharedManager.authenticate(...)"]), status: .OperationUnauthorized))
        }
    }
    
    
    /**
     Busca o perfil do usuário no aplicativo.
     - parameter userCod Código do usuário à que será buscado o perfil.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func getUserProfile(userCod userCod: Int, result: (operationResult: APCOperationResponse)-> Void){
        if let appCod = APCApplication.sharedApplication.applicationCode {
            Alamofire.request(.GET, APCURLProvider.userProfileURL(userCod: userCod), parameters: nil, encoding: .URLEncodedInURL, headers: ["appIdentifier": String(appCod)]).responseJSON { (responseObject) in
                self.getUserProfileResponseHandler(response: responseObject, result: result)
            }
        }
    }
    
    
    
    /**
     Altera os dados do perfil de um usuário associado à um usuário no aplicativo. Requer autenticação.
     - parameter userCod Código do usuário à que será atualizado o perfil.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func updateUserProfile(userCod user: Int, profile: APCProfile, result: (operationResult: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if session.isSessionExpired {
                APCUserManager.sharedManager.refreshSession({ (operationResult) in
                    if operationResult.status == .CompletedSuccesfully {
                        self.updateUserProfile(userCod: user, profile: profile, result: result)
                    }else{
                        result(operationResult: operationResult)
                    }
                })
            }else{
                if let token = self.activeSession?.sessionToken {
                    var profileData = profile.asDictionary()
                    profileData.updateValue(true, forKey: "verificado")
                    Alamofire.request(.PUT, APCURLProvider.userProfileURL(userCod: user), parameters: profileData, encoding: .JSON, headers: ["appToken" : token]).responseJSON(completionHandler: { (responseObject) in
                        APCManagerUtils.responseHandler(response: responseObject, result: result)
                    })
                }
            }
        }else{
            result(operationResult: APCOperationResponse(data: nil, status: .OperationUnauthorized))
        }

    }
    /**
     Exclui perfil de um usuário em um no aplicativo. Requer autenticação.
     - parameter userCod Código do usuário que terá o perfil excluído.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func deleteUserProfile(userCod userCod: Int, result: (operationResult: APCOperationResponse)-> Void){
        if let session = APCUserManager.sharedManager.activeSession {
            if let appCod = APCApplication.sharedApplication.applicationCode {
                if session.isSessionExpired {
                    APCUserManager.sharedManager.refreshSession({ (operationResult) in
                        if operationResult.status == .CompletedSuccesfully {
                            self.deleteUserProfile(userCod: userCod, result: result)
                        }else{
                            result(operationResult: operationResult)
                        }
                    })
                }else{
                    if let token = self.activeSession?.sessionToken {
                        let headers = ["appToken" : token , "appIdentifier" : String(appCod)]
                        Alamofire.request(.DELETE, APCURLProvider.userProfileURL(userCod: userCod), parameters: nil, encoding: .URL, headers: headers).responseJSON(completionHandler: { (responseObject) in
                            APCManagerUtils.responseHandler(response: responseObject, result: result)
                        })
                    }
                }
            }else{
                result(operationResult: APCOperationResponse(data: NSError(domain: "com.bepid.APCAccessSDK", code: 10, userInfo: [NSLocalizedDescriptionKey : "You must have an aplication configured to perform this operation. See APCApplication.sharedApplication"]), status: .OperationUnauthorized))
            }
        }else{
            result(operationResult: APCOperationResponse(data: nil, status: .OperationUnauthorized))
        }
    }
    
    
    //MARK: - Profile response handlers
    
    private func getUserProfileResponseHandler(response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, reponseHeaders) -> AnyObject? in
            if let profileData = responseValue as? [String : AnyObject]{
                return JsonObjectCreator.createObject(dictionary: profileData, objectClass: APCProfile.self)
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    
}



