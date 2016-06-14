//
//  APCPostage.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/1/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import UIKit

public class APCPostage: NSObject, JsonConvertable{
    
    var cod: Int = 0
    var codAuthor : Int = 0
    var codObjetoDestino: Int?
    var codTipoObjetoDestino: Int?
    var codTipoPostagem: Int = 0
    var date: NSDate = NSDate()
    
    
    private override init(){
        
    }
    
    public convenience init(cod: Int, codAuthor: Int, codTipoPostagem: Int) {
        self.init()
        self.cod = cod
        self.codAuthor = codAuthor
        self.codTipoPostagem = codTipoPostagem
    }
    
    public convenience init(codAuthor: Int, codTipoPostagem: Int) {
        self.init()
        self.codAuthor = codAuthor
        self.codTipoPostagem = codTipoPostagem
    }
    
    
    //MARK: - Json Convertable
    public required init(dictionary: [String : AnyObject]) {
        if let cod = dictionary["codPostagem"] as? Int{
            self.cod = cod
        }
        if let dataHoraPostagem = dictionary["dataHoraPostagem"] as? String {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
            if let date = formatter.dateFromString(dataHoraPostagem) {
                self.date = date
            }
        }
        self.codObjetoDestino =  dictionary["codObjetoDestino"] as? Int
        self.codTipoObjetoDestino = dictionary["codTipoObjetoDestino"] as? Int
        
        if let codTipoPostagem = dictionary["codTipoPostagem"] as? Int{
            self.codTipoPostagem = codTipoPostagem
        }
    }
    
    public func asDictionary() -> [String : AnyObject] {
        var data : [String : AnyObject] = [:]
        var author : [String : AnyObject] = [:]
        author.updateValue(self.codAuthor, forKey: "codPessoa")
        data.updateValue(author, forKey: "autor")
        if let unwrappedCodObjDestino = self.codObjetoDestino {
            data.updateValue(unwrappedCodObjDestino, forKey: "codObjetoDestino")
        }
        if let unwrappedTipoObjDestino = self.codTipoObjetoDestino {
            data.updateValue(unwrappedTipoObjDestino, forKey: "codTipoObjetoDestino")
        }
        var tipo : [String : AnyObject] = [:]
        tipo.updateValue(self.codTipoPostagem, forKey: "codTipoPostagem")
        data.updateValue(tipo, forKey: "tipo")
        
        return data
    }
    
    
    override public var description: String {
        return "[cod = \(self.cod), codAuthor = \(self.codAuthor), codObjetoDestino = \(self.codObjetoDestino), codTipoObjetoDestino = \(self.codTipoObjetoDestino), codTipoPostagem = \(self.codTipoPostagem), date = \(self.date)]\n"
    }
    
    
//    
//    var codAuthor : Int = 0
//    var codObjetoDestino: Int?
//    var codTipoObjetoDestino: Int?
//    var codTipoPostagem: Int = 0
//    var date: NSDate = NSDate()
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
