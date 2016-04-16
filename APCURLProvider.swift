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
    class var baseAPCService: String {
        return serverDomain + "/appCivicoRS/rest"
    }
    
    
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
}
