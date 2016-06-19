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
    public var birthdate: NSDate?
    public var email: String!
    public var isEmailVerified: Bool = false
    
    public var userLocation: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
    
    public var fullName: String?
    public var username: String!
    public var password: String?
    public var gender: Gender = .None
    public var tokenFacebook: String?
    public var tokenGoogle: String?
    public var tokenInstagram: String?
    public var tokenTwitter: String?
    
    //MARK:- Computed Properties
    public var userAccountType: AccountType? {
        if self.tokenFacebook != nil {
           return AccountType.FacebookAccount
        }else if self.tokenTwitter != nil {
            return AccountType.TwitterAccount
        }else if self.tokenGoogle != nil{
            return AccountType.GoogleAccount
        }else if self.tokenInstagram != nil {
            return AccountType.InstagramAcount
        }else {
            return AccountType.APCAccount
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
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self.birthdate =  formatter.dateFromString(dateStr)
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
            let intergerRepresentation = rawGender.uppercaseString == "M" ? 0 : 1
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
        dictionary.updateOptionalValue(self.CEP, forKey: "CEP")
        dictionary.updateOptionalValue(self.biography, forKey: "biografia")
        dictionary.updateOptionalValue(self.cod, forKey: "cod")
        if let unwrappedBirthdate = self.birthdate {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            dictionary.updateOptionalValue(formatter.stringFromDate(unwrappedBirthdate), forKey: "dataNascimento")
        }
        dictionary.updateOptionalValue(self.email, forKey: "email")
        dictionary.updateOptionalValue(self.password, forKey: "senha")
        dictionary.updateOptionalValue(self.isEmailVerified, forKey: "emailVerificado")
        
        if CLLocationCoordinate2DIsValid(self.userLocation) {
            dictionary.updateOptionalValue(self.userLocation.latitude, forKey: "latitude")
            dictionary.updateOptionalValue(self.userLocation.longitude, forKey: "longitude")
        }
        dictionary.updateOptionalValue(self.fullName, forKey: "nomeCompleto")
        dictionary.updateOptionalValue(self.username, forKey: "nomeUsuario")
        
        if self.gender != .None {
            let gender  = self.gender.rawValue == 0 ? "M" : "F"
            dictionary.updateOptionalValue(gender, forKey: "sexo")
        }
        
        dictionary.updateOptionalValue(self.tokenFacebook, forKey: "tokenFacebook")
        dictionary.updateOptionalValue(self.tokenGoogle, forKey: "tokenGoogle")
        dictionary.updateOptionalValue(self.tokenInstagram, forKey: "tokenInstagram")
        dictionary.updateOptionalValue(self.tokenTwitter, forKey: "tokenTwitter")
    
        
        return dictionary
    }
    
    
    //MARK:- NSCoding implementation
    required public init(coder aDecoder: NSCoder) {
        self.CEP = aDecoder.decodeObjectForKey("CEP") as? String
        self.biography = aDecoder.decodeObjectForKey("biografia") as? String
        self.cod = aDecoder.decodeIntegerForKey("cod")
        self.birthdate = aDecoder.decodeObjectForKey("dataNascimento") as? NSDate
        self.email = aDecoder.decodeObjectForKey("email") as? String
        self.isEmailVerified = aDecoder.decodeBoolForKey("emailVerificado")
        let lat = aDecoder.decodeDoubleForKey("latitude")
        let long = aDecoder.decodeDoubleForKey("longitude")
        if lat != 0 && long != 0 {
            self.userLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        self.fullName = aDecoder.decodeObjectForKey("nomeCompleto") as? String
        self.username = aDecoder.decodeObjectForKey("nomeUsuario") as? String
        if let genderRaw = aDecoder.decodeObjectForKey("sexo") as? Int, let gender = Gender(rawValue: genderRaw){
            self.gender = gender
        }
        
        self.tokenFacebook = aDecoder.decodeObjectForKey("tokenFacebook") as? String
        self.tokenGoogle = aDecoder.decodeObjectForKey("tokenGoogle") as? String
        self.tokenInstagram = aDecoder.decodeObjectForKey("tokenInstagram") as? String
        self.tokenTwitter = aDecoder.decodeObjectForKey("tokenTwitter") as? String

    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.CEP, forKey: "CEP")
        aCoder.encodeObject(self.biography, forKey: "biografia")
        aCoder.encodeInteger(self.cod, forKey: "cod")
        aCoder.encodeObject(self.birthdate, forKey: "dataNascimento")
        aCoder.encodeObject(self.email, forKey: "email")
        aCoder.encodeBool(self.isEmailVerified, forKey: "emailVerificado")
        
        if CLLocationCoordinate2DIsValid(self.userLocation) {
            aCoder.encodeDouble(self.userLocation.latitude, forKey: "latitude")
            aCoder.encodeDouble(self.userLocation.longitude, forKey: "longitude")
        }
        
        aCoder.encodeObject(self.fullName, forKey: "nomeCompleto")
        aCoder.encodeObject(self.username, forKey: "nomeUsuario")
        aCoder.encodeObject(self.gender.rawValue, forKey: "sexo")
        
        aCoder.encodeObject(self.tokenFacebook, forKey: "tokenFacebook")
        aCoder.encodeObject(self.tokenGoogle, forKey: "tokenGoogle")
        aCoder.encodeObject(self.tokenTwitter, forKey: "tokenTwitter")
        aCoder.encodeObject(self.tokenInstagram, forKey: "tokenInstagram")
    }
    
    //MARK: Overrides
    public override var description: String  {
    
        return  "CEP = \(self.CEP)\n" +
                "biografia = \(self.biography)\n" +
                "cod = \(self.cod)\n" +
                "dataNascimento = \(self.birthdate)\n" +
                "email = \(self.email)\n" +
                "emailVerificado = \(self.isEmailVerified)\n" +
                "location = (\(self.userLocation.latitude),\(self.userLocation.longitude))\n" +
                "nomeCompleto = \(self.fullName)\n" +
                "nomeUsuario = \(self.username)\n" +
                "genero = \(self.gender)\n" +
                "tokenFacebook = \(self.tokenFacebook)\n" +
                "tokenGoogle = \(self.tokenGoogle)\n" +
                "tokenTwitter = \(self.tokenTwitter)\n" +
                "tokenInstagram  = \(self.tokenInstagram)\n" 
    }
}

@objc public enum Gender: Int {
    case Male = 0
    case Female = 1
    case None = 2
}

@objc public enum AccountType : Int {
    case APCAccount
    case TwitterAccount
    case FacebookAccount
    case InstagramAcount
    case GoogleAccount
}