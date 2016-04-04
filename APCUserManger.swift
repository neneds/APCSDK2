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
public class APCUserManger: NSObject {
    
    
    static public var sharedManager = APCUserManger()
    
    
    private(set) var activeSession: APCUserSession?
    
    public var isSessionActive: Bool {
        return self.activeSession != nil
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
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : email,
            kSecValueData as String   : password]
        
        SecItemDelete(query as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(query as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    private func loadUserPass(email email: String)-> String? {
        let query = [
            kSecClass as String : kSecClassGenericPassword as String,
            kSecAttrAccount as String : email,
            kSecReturnData as String : kCFBooleanTrue,
            kSecMatchLimit as String : kSecMatchLimitOne
        ]

        var extractedData: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionaryRef, &extractedData)
        if status == noErr {
            return extractedData as? String
        } else {
            return nil
        }
    }
    
    private func clearPassword() {
        let query = [ kSecClass as String : kSecClassGenericPassword]
        SecItemDelete(query as CFDictionaryRef)
    }
    
    /**
     
     
     */
    public func clearSession() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("current_session")
        self.clearPassword()
    }
    
    
    //MARK:- Authentication methods
    /**
     
    */
    public func authenticate(email email: String, password: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "senha" : password]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     
     
     */
    public func authenticateFacebook(email email: String, facebookToken: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "facebookToken" : facebookToken]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(response: responseObject, result: result)
        }
    }
    
    public func authenticateTwitter(email email: String, twitterToken: String, appIdentifier: Int?, result: ((operationResponse: APCOperationResponse)-> Void)?) {
        var headers :[String : String] =  ["email" : email, "twitterToken" : twitterToken]
        if let unwrapperAppIdentifier = appIdentifier {
            headers.updateValue("\(unwrapperAppIdentifier)", forKey: "appIdentifier")
        }
        Alamofire.request(.GET, APCURLProvider.authenticateUserURL(), parameters: nil, encoding: .URLEncodedInURL, headers: headers).responseJSON { (responseObject) in
            self.authenticationResponseHandler(response: responseObject, result: result)
        }
    }
    
    
    //MARK:- Register Method
    
    /**
        
     
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
        print(userAsDictionary)
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
    private func authenticationResponseHandler(response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?) {
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
                print("\(String(data: responseObject.data!, encoding: NSUTF8StringEncoding))")
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



