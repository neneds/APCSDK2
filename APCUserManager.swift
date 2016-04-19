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
    
    
    static public var sharedManager = APCUserManager()
    
    
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
    public func authenticate(email email: String, password: String, appIdentifier: NSNumber?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "senha" : password]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
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
    public func authenticateFacebook(email email: String, facebookToken: String, appIdentifier: NSNumber?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "facebookToken" : facebookToken]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
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
    public func authenticateTwitter(email email: String, twitterToken: String, appIdentifier: NSNumber?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "twitterToken" : twitterToken]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(password: nil, response: responseObject, result: result)
        }
    }
    
    
    //MARK:- Register Method
    
     /**
     Cadastra um usuário. Se o cadastro for efetuado com sucesso, o método irá authenticar e preencher automaticamente  propriedade -activeSession
     - parameter user E-mail do usuário.
     - parameter result Bloco chamado após completar a operação. Retornando um objeto de resposta.
     - see APCOperationResponse.swift
     */
    public func registerUser(user user: APCUser,  result: (operationResponse: APCOperationResponse)-> Void) {
        if let request = self.requestForRegisterUser(user: user) {
            Alamofire.request(request).responseData(completionHandler: { (responseObject) in
                if let unwrappedResponse = responseObject.response {
                    switch unwrappedResponse.statusCode {
                    case 201:
                        self.backgroundAuthentication(appIdentifier: nil, user: user, result: { (operationStatus) in
                            if operationStatus == .CompletedSuccesfully{
                                result(operationResponse: APCOperationResponse(data: self.activeSession, status: operationStatus))
                            }else{
                                result(operationResponse: APCOperationResponse(data: nil, status: operationStatus))
                            }
                        })
                        break
                    case 400:
                        result(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
                        break
                    case 500:
                        result(operationResponse: APCOperationResponse(data: nil, status:.InternalServerError))
                        break
                    default:
                        result(operationResponse: APCOperationResponse(data: nil, status: .ConnectionError))
                        break
                    }
                }
            })
        }else{
            result(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
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
            if let unwrappedStatusCode = responseObject.response?.statusCode {
                switch(unwrappedStatusCode){
                case 200:
                    let user = JsonObjectCreator.createObject(dictionary: responseObject.result.value as! [String : AnyObject], objectClass: APCUser.self)
                    result(operationResponse: APCOperationResponse(data: user, status: .CompletedSuccesfully))
                    break
                case 404:
                    result(operationResponse: APCOperationResponse(data: nil, status: .ResourceNotFound))
                    break
                case 500:
                    result(operationResponse: APCOperationResponse(data: nil, status: .InternalServerError))
                    break
                default:
                    break
                }
            }else{
                result(operationResponse: APCOperationResponse(data: nil, status: .ConnectionError))
            }

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
        if let unwrappedStatusCode = responseObject.response?.statusCode {
            switch unwrappedStatusCode {
            case 200:
                if let users =  responseObject.result.value as? [[String : AnyObject]]{
                    if !users.isEmpty {
                        let user = JsonObjectCreator.createObject(dictionary: users[0], objectClass: APCUser.self)
                        result(operationResponse: APCOperationResponse(data: user, status: .CompletedSuccesfully))
                    }
                }
            case 204:
                result(operationResponse: APCOperationResponse(data: nil, status: .ResourceNotFound))
            case 400:
                result(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
            case 500:
                result(operationResponse: APCOperationResponse(data: nil, status: .InternalServerError))
            default:
                result(operationResponse: APCOperationResponse(data: nil, status: .ConnectionError))
            }
            
        }
    }
    
    private func existsResponseHandler(response responseObject: Response<AnyObject, NSError>, result: (operationResponse: APCOperationResponse)-> Void){
        if let unwrappedStatusCode = responseObject.response?.statusCode {
            switch unwrappedStatusCode {
            case 200:
                result(operationResponse: APCOperationResponse(data: true, status: .CompletedSuccesfully))
                break
            case 204:
                result(operationResponse: APCOperationResponse(data: false, status: .ResourceNotFound))
            case 400:
                result(operationResponse: APCOperationResponse(data: false, status: .InvalidParamters))
            case 500:
                result(operationResponse: APCOperationResponse(data: false, status: .InternalServerError))
            default:
                result(operationResponse: APCOperationResponse(data: false, status: .ConnectionError))
            }
            
        }
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
        if let uwrappedResponse = responseObject.response {
            switch uwrappedResponse.statusCode {
            case 200:
                let appToken = uwrappedResponse.allHeaderFields["apptoken"] as! String
                let fm = NSDateFormatter()
                fm.locale = NSLocale(localeIdentifier: "en_US")
                fm.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                let expirationDate = fm.dateFromString(uwrappedResponse.allHeaderFields["date"] as! String)?.dateByAddingTimeInterval(DayInSeconds * (Double(TokenValidDaysInterval) - 1.0))
                let user = JsonObjectCreator.createObject(dictionary: responseObject.result.value as! [String : AnyObject], objectClass: APCUser.self) as! APCUser
                let session = APCUserSession(user: user, token: appToken, expirationDate: expirationDate!)
                session.currentUser?.password = passowrd
                self.activeSession = session
                self.saveCurrentSession()
                result?(operationResponse: APCOperationResponse(data: session, status: .CompletedSuccesfully))
                break
            case 401:
                result?(operationResponse: APCOperationResponse(data: nil, status: .OperationUnauthorized))
                break
            case 400:
                result?(operationResponse: APCOperationResponse(data: nil, status: .InvalidParamters))
                break
            case 500:
                result?(operationResponse: APCOperationResponse(data: nil, status: .InternalServerError))
                break
            default:
                break
            }
        }
    }
    
    
    //MARK:- Request New Session
    private func refreshSession(appIdentifier appIdentifier: NSNumber?, result: (operationStatus: APCOperationResultStatus)-> Void){
        if let unwrappedSession = self.activeSession, let unwrappedUser = unwrappedSession.currentUser {
            self.backgroundAuthentication(appIdentifier: appIdentifier, user: unwrappedUser, result: result)
        }
    }
    
    //MARK:- Background authentication
    private func backgroundAuthentication(appIdentifier appIdentifier: NSNumber?, user: APCUser,result: (operationStatus: APCOperationResultStatus)-> Void ){
        if let unwrappedAccountType = user.userAccountType {
            switch unwrappedAccountType {
            case .APCAccount:
                if let unwrappedPass = user.password {
                    self.authenticate(email: user.email, password: unwrappedPass, appIdentifier: appIdentifier, result: { (operationResponse) in
                        result(operationStatus: operationResponse.status)
                    })
                }
                break
            case .FacebookAccount:
                if let unwrappedFacebookToken = user.tokenFacebook {
                    self.authenticateFacebook(email: user.email, facebookToken: unwrappedFacebookToken, appIdentifier: appIdentifier, result: { (operationResponse) in
                        result(operationStatus: operationResponse.status)
                    })
                }
                break
            case .TwitterAccount:
                if let unwrappedTwitterToken = user.tokenTwitter {
                    self.authenticateTwitter(email: user.email, twitterToken: unwrappedTwitterToken, appIdentifier: appIdentifier, result: { (operationResponse) in
                        result(operationStatus: operationResponse.status)
                    })
                }
                break
            default:
                break
            }
        }
    }
    
}



