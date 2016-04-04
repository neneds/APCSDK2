//
//  APCUserManger.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation
import Security
import Alamofire

public let TokenValidDaysInterval: Int = 7
public let DayInSeconds : Double = 60 * 60 * 24
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
    public func authenticate(email email: String, password: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
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
    public func authenticateFacebook(email email: String, facebookToken: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
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
    public func authenticateTwitter(email email: String, twitterToken: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
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
    //func redefinePassword()
    
    
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
    private func refreshSession(appIdentifier appIdentifier: Int?, result: (operationStatus: APCOperationResultStatus)-> Void){
        if let unwrappedSession = self.activeSession, let unwrappedUser = unwrappedSession.currentUser {
            self.backgroundAuthentication(appIdentifier: appIdentifier, user: unwrappedUser, result: result)
        }
    }
    
    //MARK:- Background authentication
    private func backgroundAuthentication(appIdentifier appIdentifier: Int?, user: APCUser,result: (operationStatus: APCOperationResultStatus)-> Void ){
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



