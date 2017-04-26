//
//  APCPostage.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/1/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

open class APCPostage: NSObject, JsonConvertable{
    
    open var cod: Int = 0
    open var codAuthor : Int = 0
    open var codDestinatedObject: Int64 = 0
    open var codDestinatedObjectType: Int = 0
    open var codPostageType: Int = 0
    open var date: Date = Date()
    
    open var contentsCodes: [Int] = []
    
    open var contents: [APCPostageContent]?
    
    fileprivate override init(){
        
    }
    
    public convenience init(cod: Int, codAuthor: Int, codPostageType: Int) {
        self.init(codAuthor: codAuthor, codPostageType: codPostageType)
        self.cod = cod
    }
    
    public convenience init(codAuthor: Int, codPostageType: Int) {
        self.init()
        self.codAuthor = codAuthor
        self.codPostageType = codPostageType
    }
    
    
    //MARK: - Json Convertable
    public required init(dictionary: [String : AnyObject]) {
        if let cod = dictionary["codPostagem"] as? Int{
            self.cod = cod
        }
        if let dataHoraPostagem = dictionary["dataHoraPostagem"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
            if let date = formatter.date(from: dataHoraPostagem) {
                self.date = date
            }
        }
        if let codAuthor = dictionary["codAutor"] as? Int {
            self.codAuthor = codAuthor
        }
        
        if let codDestinatedObject = dictionary["codObjetoDestino"] as? NSNumber{
            self.codDestinatedObject = codDestinatedObject.int64Value
        }
        
        if let codDestinatedObjectType = dictionary["codTipoObjetoDestino"] as? Int{
            self.codDestinatedObjectType = codDestinatedObjectType
        }
        
        if let codTipoPostagem = dictionary["codTipoPostagem"] as? Int{
            self.codPostageType = codTipoPostagem
        }
        
        if(self.contents == nil) {
            self.contents = [APCPostageContent]()
        }
        
        if let contents = dictionary["conteudos"] as? [[String : AnyObject]]{
            for content in contents {
                if let codContent = content["codConteudoPostagem"] as? Int{
                    self.contentsCodes.append(codContent)
                }
                
                if (content["codConteudoPost"] as? Int) != nil{
                    let apcPostageContent = JsonObjectCreator.createObject(dictionary: content, objectClass: APCPostageContent.self) as! APCPostageContent
                    self.contents?.append(apcPostageContent)
                }
            }
        }
    }
    
    open func asDictionary() -> [String : AnyObject] {
        var data : [String : AnyObject] = [:]
        var author : [String : AnyObject] = [:]
        author.updateValue(self.codAuthor as AnyObject, forKey: "codPessoa")
        data.updateValue(author as AnyObject, forKey: "autor")
        if self.codDestinatedObject != 0 {
            data.updateValue(String(self.codDestinatedObject) as AnyObject, forKey: "codObjetoDestino")
        }
        if self.codDestinatedObjectType != 0{
            data.updateValue(self.codDestinatedObjectType as AnyObject, forKey: "codTipoObjetoDestino")
        }
        var tipo : [String : AnyObject] = [:]
        tipo.updateValue(self.codPostageType as AnyObject, forKey: "codTipoPostagem")
        data.updateValue(tipo as AnyObject, forKey: "tipo")
        
        return data
    }
    
    
    override open var description: String {
        return "[cod = \(self.cod), codAuthor = \(self.codAuthor), codObjetoDestino = \(self.codDestinatedObject), codTipoObjetoDestino = \(self.codDestinatedObjectType), codTipoPostagem = \(self.codPostageType), date = \(self.date), contentsCodes = \(self.contentsCodes)]\n, contents = \(String(describing: self.contents))"
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
