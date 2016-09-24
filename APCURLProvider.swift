//
//  APCURLProvider.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

class APCURLProvider: NSObject {

    static let serverDomain: String = "http://mobile-aceite.tcu.gov.br"
    static let healthMapBase: String = "http://mobile-aceite.tcu.gov.br/mapa-da-saude/rest"
    
    class var baseAPCService: String {
        return serverDomain + "/appCivicoRS/rest"
    }
    
    //MARK: - User
    class func userBaserURL() -> URL {
        return URL(string: self.baseAPCService + "/pessoas")!
    }
    
    class func userURL(cod: Int) -> URL {
        return URL(string: self.baseAPCService + "/pessoas/\(cod)")!
    }
    
    class func authenticateUserURL()-> URL {
        return URL(string: self.baseAPCService + "/pessoas/autenticar")!
    
    }
    
    class func redefinePasswordURL()-> URL {
        return URL(string: self.baseAPCService + "/pessoas/redefinirSenha")!
    }
    
    //MARK: - Picture
    class func userPictureURL(userCod cod: Int) -> URL{
        return URL(string: self.baseAPCService + "/pessoas/\(cod)/fotoPerfil")!
    }
    
    
    //MARK: - Profile
    class func userProfileURL(userCod: Int) -> URL{
        return URL(string: self.baseAPCService + "/pessoas/\(userCod)/perfil")!
    }
    
    
}

//MARK: - Postage

extension APCURLProvider {
    
    class func postageBaseURL()-> URL{
        return URL(string: self.baseAPCService + "/postagens")!
    }
    
    class func postageURL(postageCod: Int) -> URL {
        return URL(string: self.baseAPCService + "/postagens/\(postageCod)")!
    }
    
    class func postageContentURL(postageCod: Int)-> URL {
        return URL(string: self.baseAPCService + "/postagens/\(postageCod)/conteudos")!
    }
    
    class func postageContentURL(postageCod: Int, contentCod: Int)-> URL {
        return URL(string: self.baseAPCService + "/postagens/\(postageCod)/conteudos/\(contentCod)")!
    }
}

//MARK: - Health Map

extension APCURLProvider {
    class func medicinesURL()-> URL{
        return URL(string: self.healthMapBase + "/remedios")!
    }
}

