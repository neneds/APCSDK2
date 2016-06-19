//
//  APCProfile.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/3/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCProfile: NSObject, JsonConvertable{
    
    public private(set) var aditionalFields: [String : AnyObject]? = [:]
    public var profileTypeCod: Int = 0
    public var profileDescription: String?
    
    public override init() {
        
    }
    
    public convenience init(profileTypeCod: Int) {
        self.init()
        self.profileTypeCod = profileTypeCod
    }
    
    
    
    public subscript(field: String)-> AnyObject?{
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
            if let data = aditionalFieldsStr.dataUsingEncoding(NSUTF8StringEncoding), let aditionalFieldsDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String : AnyObject]{
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
        profileType.updateValue(self.profileTypeCod, forKey: "codTipoPerfil")
        dictionary.updateValue(profileType, forKey: "tipoPerfil")
        if let unwrappedFields = self.aditionalFields {
            if !unwrappedFields.isEmpty {
                if let jsonFields = try? NSJSONSerialization.dataWithJSONObject(unwrappedFields, options: NSJSONWritingOptions.PrettyPrinted){
                    if let string = String(data: jsonFields, encoding: NSUTF8StringEncoding){
                        dictionary.updateValue(string, forKey: "camposAdicionais")
                    }
                }
            }
        }
        return dictionary
    }
    
    public override var description: String{
        return "[aditionalFields = \(self.aditionalFields),\nprofileTypeCod = \(self.profileTypeCod),\nprofileDescription = \(self.profileDescription)]"
    }

}


