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
    class func userBaserURL() -> NSURL {
        return NSURL(string: self.baseAPCService + "/pessoas")!
    }
    
    class func userURL(cod cod: Int) -> NSURL {
        return NSURL(string: self.baseAPCService + "/pessoas/\(cod)")!
    }
    
    class func authenticateUserURL()-> NSURL {
        return NSURL(string: self.baseAPCService + "/pessoas/autenticar")!
    
    }
    
    class func redefinePasswordURL()-> NSURL {
        return NSURL(string: self.baseAPCService + "/pessoas/redefinirSenha")!
    }
    
    //MARK: - Profile
    class func userProfileURL(userCod userCod: Int) -> NSURL{
        return NSURL(string: self.baseAPCService + "/pessoas/\(userCod)/perfil")!
    }
    
    
}

//MARK: - Postage

extension APCURLProvider {
    
    class func postageBaseURL()-> NSURL{
        return NSURL(string: self.baseAPCService + "/postagens")!
    }
    
    class func postageURL(postageCod postageCod: Int) -> NSURL {
        return NSURL(string: self.baseAPCService + "/postagens/\(postageCod)")!
    }
    
    class func postageContentURL(postageCod postageCod: Int)-> NSURL {
        return NSURL(string: self.baseAPCService + "/postagens/\(postageCod)/conteudos")!
    }
    
    class func postageContentURL(postageCod postageCod: Int, contentCod: Int)-> NSURL {
        return NSURL(string: self.baseAPCService + "/postagens/\(postageCod)/conteudos/\(contentCod)")!
    }
}

//MARK: - Health Map

extension APCURLProvider {
    class func medicinesURL()-> NSURL{
        return NSURL(string: self.healthMapBase + "/remedios")!
    }
}

