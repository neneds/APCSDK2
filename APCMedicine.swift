//
//  APCMedicine.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/28/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation
/**
 Not Objective C support.
 */

public class APCMedicine: NSObject, JsonConvertable {
    
    public var cod : UInt64!
    public var barCodeEAN : String!
    public var activeIngredient: String!
    public var CNPJ: String!
    public var laboratory: String!
    public var codeGGREM: String!
    public var registerCode: String!
    public var product: String!
    public var presentation: String!
    public var therapeuticClass: String!
    public var releasedPrice: Bool!
    public var pf : Float?
    public var pf12 : Float?
    public var pf17 : Float?
    public var pf175 : Float?
    public var pf175Alc : Float?
    public var pf17Alc : Float?
    public var pf18 : Float?
    public var pf18Alc : Float?
    public var pf20 : Float?
    public var pmc : Float?
    public var pmc12 : Float?
    public var pmc17 : Float?
    public var pmc175 : Float?
    public var pmc175Alc : Float?
    public var pmc17Alc : Float?
    public var pmc18 : Float?
    public var pmc18Alc : Float?
    public var pmc20 : Float?
    public var restriction: Bool!
    public var CAP: Bool!
    public var confaz87: Bool!
    public var lastUpdate: Date!

    
    public required init(dictionary: [String : AnyObject]) {
        print(dictionary)
        if let cod = dictionary["cod"] as? NSNumber{
            self.cod = cod.uint64Value
        }
        self.barCodeEAN = dictionary["codBarraEan"] as? String
        self.activeIngredient = dictionary["principioAtivo"] as? String
        self.CNPJ = dictionary["cnpj"] as? String
        self.laboratory = dictionary["laboratorio"] as? String
        self.codeGGREM = dictionary["codGgrem"] as? String
        self.registerCode = dictionary["registro"] as? String
        self.product = dictionary["produto"] as? String
        self.presentation = dictionary["apresentacao"] as? String
        self.therapeuticClass = dictionary["classeTerapeutica"] as? String
        if let rp = dictionary["precoLiberado"] as? String {
            self.releasedPrice = rp == "Sim"
        }
        self.pf = dictionary["pf0"] as? Float
        self.pf12 = dictionary["pf12"] as? Float
        self.pf17 = dictionary["pf17"] as? Float
        self.pf17Alc = dictionary["pf17Alc"] as? Float
        self.pf175 = dictionary["pf175"] as? Float
        self.pf175Alc = dictionary["pf175Alc"] as? Float
        self.pf18 = dictionary["pf18"] as? Float
        self.pf18Alc = dictionary["pf18Alc"] as? Float
        self.pf20 = dictionary["pf20"] as? Float
        self.pmc = dictionary["pmc0"] as? Float
        self.pmc12 = dictionary["pmc12"] as? Float
        self.pmc17 = dictionary["pmc17"] as? Float
        self.pmc17Alc = dictionary["pmc17Alc"] as? Float
        self.pmc175 = dictionary["pmc175"] as? Float
        self.pmc175Alc = dictionary["pmc175Alc"] as? Float
        self.pmc18 = dictionary["pmc18"] as? Float
        self.pmc18Alc = dictionary["pmc18Alc"] as? Float
        self.pmc20 = dictionary["pmc20"] as? Float
        if let rt = dictionary["restricao"] as? String {
            self.restriction = rt == "Sim"
        }
        if let cap = dictionary["restricao"] as? String {
            self.CAP = cap == "Sim"
        }
        if let confaz87 = dictionary["confaz87"] as? String {
            self.confaz87 = confaz87 == "Sim"
        }
        if let date = dictionary["ultimaAlteracao"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            self.lastUpdate = formatter.date(from: date)
        }
    }
    
    //MARK:- Override description
    
    public override var description: String{
        return "APCMedicine{apresentacao = [\(self.presentation), cap = \(self.CAP), classeTerapeutica = \(self.therapeuticClass),cnpj = \(self.CNPJ), cod = \(self.cod), codBarraEan = \(self.barCodeEAN), codGgrem = \(self.codeGGREM) confaz87 = \(self.confaz87), laboratorio = \(self.laboratory), pf0 = \(String(describing: self.pf)), pf12 = \(String(describing: self.pf12)), pf17 = \(String(describing: self.pf17)), pf175 = \(String(describing: self.pf175)), pf175Alc = \(String(describing: self.pf175Alc)), pf17Alc = \(String(describing: self.pf17Alc)),pf18 = \(String(describing: self.pf18)), pf18Alc = \(String(describing: self.pf18Alc)), pf20 = \(String(describing: self.pf20)), pmc = \(String(describing: self.pmc)), pmc12 = \(String(describing: self.pmc12)),pmc17 = \(String(describing: self.pmc17)), pmc175 = \(String(describing: self.pmc175)), pmc175Alc = \(String(describing: self.pmc175Alc)), pmc17Alc = \(String(describing: self.pmc17Alc)), pmc18 = \(String(describing: self.pmc18)), pmc18Alc = \(String(describing: self.pmc18Alc)), pmc20 = \(String(describing: self.pmc20)), precoLiberado = \(self.releasedPrice), principioAtivo = \(self.activeIngredient), produto = \(self.product), registro = \(self.registerCode), restricao = \(self.restriction), ultimaAlteracao = \(self.lastUpdate)]"

    }
}
