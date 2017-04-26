//
//  APCProfile.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

open class APCProfile: NSObject, JsonConvertable{
    
    open fileprivate(set) var aditionalFields: [String : AnyObject]? = [:]
    open var profileTypeCod: Int = 0
    open var profileDescription: String?
    
    public override init() {
        
    }
    
    public convenience init(profileTypeCod: Int) {
        self.init()
        self.profileTypeCod = profileTypeCod
    }
    
    
    
    open subscript(field: String)-> AnyObject?{
        get{
            return self.aditionalFields?[field]
        }
        
        set(value){
            self.aditionalFields?[field] = value
        }
    }
    
    //MARK:- JsonConvertable
    public required init(dictionary: [String : AnyObject]) {
        if let aditionalFieldsStr = dictionary["camposAdicionais"] as? String {
            if let data = aditionalFieldsStr.data(using: String.Encoding.utf8), let aditionalFieldsDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : AnyObject]{
                self.aditionalFields = aditionalFieldsDic
            }
        }
        if let profileType = dictionary["tipoPerfil"] as? [String : AnyObject], let profileCod = profileType["codTipoPerfil"] as? Int {
            self.profileTypeCod = profileCod
            self.profileDescription = profileType["descricao"] as? String
        }
        
    }

    
    func asDictionary() -> [String : AnyObject] {
        var dictionary : [String : AnyObject] = [:]
        var profileType: [String : AnyObject] = [:]
        profileType.updateValue(self.profileTypeCod as AnyObject, forKey: "codTipoPerfil")
        dictionary.updateValue(profileType as AnyObject, forKey: "tipoPerfil")
        if let unwrappedFields = self.aditionalFields {
            if !unwrappedFields.isEmpty {
                if let jsonFields = try? JSONSerialization.data(withJSONObject: unwrappedFields, options: JSONSerialization.WritingOptions.prettyPrinted){
                    if let string = String(data: jsonFields, encoding: String.Encoding.utf8){
                        dictionary.updateValue(string as AnyObject, forKey: "camposAdicionais")
                    }
                }
            }
        }
        return dictionary
    }
    
    open override var description: String{
        return "[aditionalFields = \(String(describing: self.aditionalFields)),\nprofileTypeCod = \(self.profileTypeCod),\nprofileDescription = \(String(describing: self.profileDescription))]"
    }

}


