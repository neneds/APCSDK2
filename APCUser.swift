//
//  APCUser.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 4/2/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation
import CoreLocation
public class APCUser: NSObject, NSCoding, JsonConvertable {
    
    //MARK:- Properties
    public var CEP: String?
    public var biography: String?
    public var cod: Int = 0
    public var birthdate: Date?
    public var email: String!
    public var isEmailVerified: Bool = false
    
    public var userLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    public var fullName: String?
    public var username: String!
    public var password: String?
    public var gender: Gender = .none
    public var tokenFacebook: String?
    public var tokenGoogle: String?
    public var tokenInstagram: String?
    public var tokenTwitter: String?
    
    //MARK:- Computed Properties
    public var userAccountType: AccountType? {
        if self.tokenFacebook != nil {
           return AccountType.facebookAccount
        }else if self.tokenTwitter != nil {
            return AccountType.twitterAccount
        }else if self.tokenGoogle != nil{
            return AccountType.googleAccount
        }else if self.tokenInstagram != nil {
            return AccountType.instagramAcount
        }else {
            return AccountType.apcAccount
        }
    }
    
    //MARK:- Initializers
    override public init() {
        super.init()
        self.password = ""
    }
    
    
    /**
        Inicializa um usuário com nome e email.
        - parameter username Nome do usuário.
        - parameter email E-mail do usuário.
    */
    convenience public init(username: String, email: String) {
        self.init()
        self.username = username
        self.email = email
    }
    
    /**
        Inicializa um usuário com nome e email e senha.
        - parameter username Nome do usuário.
        - parameter email E-mail do usuário.
        - parameter password Senha do usuário
    */
    convenience public init(username: String, email: String, password: String) {
        self.init(username: username, email: email)
        self.password = password
    }
    
    //MARK:- JSONConvertable Implementation
    required public init(dictionary: [String : AnyObject]) {
        self.CEP = dictionary["CEP"] as? String
        self.biography = dictionary["biografia"] as? String
        if let cod = dictionary["cod"] as? Int{
            self.cod = cod
        }
        if let dateStr = dictionary["dataNascimento"] as? String{
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.birthdate =  formatter.date(from: dateStr)
        }
        self.email = dictionary["email"] as? String
        if let emailVerificado = dictionary["emailVerificado"] as? Bool{
            self.isEmailVerified = emailVerificado
        }
        if let lat = dictionary["latitude"] as? Double,let long = dictionary["longitude"] as? Double {
            self.userLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        self.fullName = dictionary["nomeCompleto"] as? String
        self.username = dictionary["nomeUsuario"] as? String
        
        if let rawGender = dictionary["sexo"] as? String {
            let intergerRepresentation = rawGender.uppercased() == "M" ? 0 : 1
            if let gender = Gender(rawValue: intergerRepresentation){
                self.gender = gender
            }
        }
        
        self.tokenFacebook = dictionary["tokenFacebook"] as? String
        self.tokenGoogle = dictionary["tokenGoogle"] as? String
        self.tokenInstagram = dictionary["tokenInstagram"] as? String
        self.tokenTwitter = dictionary["tokenTwitter"] as? String
    }
    
    public func asDictionary() -> [String : AnyObject] {
        var dictionary : [String : AnyObject] = [:]
        dictionary.updateOptionalValue(self.CEP as AnyObject?, forKey: "CEP")
        dictionary.updateOptionalValue(self.biography as AnyObject?, forKey: "biografia")
        dictionary.updateOptionalValue(self.cod as AnyObject?, forKey: "cod")
        if let unwrappedBirthdate = self.birthdate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dictionary.updateOptionalValue(formatter.string(from: unwrappedBirthdate) as AnyObject?, forKey: "dataNascimento")
        }
        dictionary.updateOptionalValue(self.email as AnyObject?, forKey: "email")
        dictionary.updateOptionalValue(self.password as AnyObject?, forKey: "senha")
        dictionary.updateOptionalValue(self.isEmailVerified as AnyObject?, forKey: "emailVerificado")
        
        if CLLocationCoordinate2DIsValid(self.userLocation) {
            dictionary.updateOptionalValue(self.userLocation.latitude as AnyObject?, forKey: "latitude")
            dictionary.updateOptionalValue(self.userLocation.longitude as AnyObject?, forKey: "longitude")
        }
        dictionary.updateOptionalValue(self.fullName as AnyObject?, forKey: "nomeCompleto")
        dictionary.updateOptionalValue(self.username as AnyObject?, forKey: "nomeUsuario")
        
        if self.gender != .none {
            let gender  = self.gender.rawValue == 0 ? "M" : "F"
            dictionary.updateOptionalValue(gender as AnyObject?, forKey: "sexo")
        }
        
        dictionary.updateOptionalValue(self.tokenFacebook as AnyObject?, forKey: "tokenFacebook")
        dictionary.updateOptionalValue(self.tokenGoogle as AnyObject?, forKey: "tokenGoogle")
        dictionary.updateOptionalValue(self.tokenInstagram as AnyObject?, forKey: "tokenInstagram")
        dictionary.updateOptionalValue(self.tokenTwitter as AnyObject?, forKey: "tokenTwitter")
    
        
        return dictionary
    }
    
    
    //MARK:- NSCoding implementation
    required public init(coder aDecoder: NSCoder) {
        self.CEP = aDecoder.decodeObject(forKey: "CEP") as? String
        self.biography = aDecoder.decodeObject(forKey: "biografia") as? String
        self.cod = aDecoder.decodeInteger(forKey: "cod")
        self.birthdate = aDecoder.decodeObject(forKey: "dataNascimento") as? Date
        self.email = aDecoder.decodeObject(forKey: "email") as? String
        self.isEmailVerified = aDecoder.decodeBool(forKey: "emailVerificado")
        let lat = aDecoder.decodeDouble(forKey: "latitude")
        let long = aDecoder.decodeDouble(forKey: "longitude")
        if lat != 0 && long != 0 {
            self.userLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        self.fullName = aDecoder.decodeObject(forKey: "nomeCompleto") as? String
        self.username = aDecoder.decodeObject(forKey: "nomeUsuario") as? String
        if let genderRaw = aDecoder.decodeObject(forKey: "sexo") as? Int, let gender = Gender(rawValue: genderRaw){
            self.gender = gender
        }
        
        self.tokenFacebook = aDecoder.decodeObject(forKey: "tokenFacebook") as? String
        self.tokenGoogle = aDecoder.decodeObject(forKey: "tokenGoogle") as? String
        self.tokenInstagram = aDecoder.decodeObject(forKey: "tokenInstagram") as? String
        self.tokenTwitter = aDecoder.decodeObject(forKey: "tokenTwitter") as? String

    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.CEP, forKey: "CEP")
        aCoder.encode(self.biography, forKey: "biografia")
        aCoder.encode(self.cod, forKey: "cod")
        aCoder.encode(self.birthdate, forKey: "dataNascimento")
        aCoder.encode(self.email, forKey: "email")
        aCoder.encode(self.isEmailVerified, forKey: "emailVerificado")
        
        if CLLocationCoordinate2DIsValid(self.userLocation) {
            aCoder.encode(self.userLocation.latitude, forKey: "latitude")
            aCoder.encode(self.userLocation.longitude, forKey: "longitude")
        }
        
        aCoder.encode(self.fullName, forKey: "nomeCompleto")
        aCoder.encode(self.username, forKey: "nomeUsuario")
        aCoder.encode(self.gender.rawValue, forKey: "sexo")
        
        aCoder.encode(self.tokenFacebook, forKey: "tokenFacebook")
        aCoder.encode(self.tokenGoogle, forKey: "tokenGoogle")
        aCoder.encode(self.tokenTwitter, forKey: "tokenTwitter")
        aCoder.encode(self.tokenInstagram, forKey: "tokenInstagram")
    }
    
    //MARK: Overrides
    public override var description: String  {
    
        return  "CEP = \(String(describing: self.CEP))\n" +
                "biografia = \(String(describing: self.biography))\n" +
                "cod = \(self.cod)\n" +
                "dataNascimento = \(String(describing: self.birthdate))\n" +
                "email = \(self.email)\n" +
                "emailVerificado = \(self.isEmailVerified)\n" +
                "location = (\(self.userLocation.latitude),\(self.userLocation.longitude))\n" +
                "nomeCompleto = \(String(describing: self.fullName))\n" +
                "nomeUsuario = \(self.username)\n" +
                "genero = \(self.gender)\n" +
                "tokenFacebook = \(String(describing: self.tokenFacebook))\n" +
                "tokenGoogle = \(String(describing: self.tokenGoogle))\n" +
                "tokenTwitter = \(String(describing: self.tokenTwitter))\n" +
                "tokenInstagram  = \(String(describing: self.tokenInstagram))\n" 
    }
}

@objc public enum Gender: Int {
    case male = 0
    case female = 1
    case none = 2
}

@objc public enum AccountType : Int {
    case apcAccount
    case twitterAccount
    case facebookAccount
    case instagramAcount
    case googleAccount
}
