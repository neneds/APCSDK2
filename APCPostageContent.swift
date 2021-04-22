//
//  APCPostageContent.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/1/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation

public class APCPostageContent: NSObject, JsonConvertable {
    public var cod: Int = 0
    public var postageCod: Int = 0
    public fileprivate(set) var values: [String: AnyObject] = [:]
    public var text: String?
    public var numericValue: Double?

    public var hasBinaryData: Bool = false

    override init() {

    }

    public convenience init(text: String, numericValue: Double, values: [String: AnyObject]) {
        self.init(values: values)
        self.text = text
        self.numericValue = numericValue
    }

    public convenience init(values: [String: AnyObject]) {
        self.init()
        self.values.union(values)
    }

    public convenience init(cod: Int, values: [String: AnyObject]) {
        self.init(values: values)
        self.cod = cod
    }

    public func setValue(_ value: AnyObject, toField field: String) {
       self.values[field] = value
    }

    public subscript(field: String) -> AnyObject? {
        get {
           return self.values[field]
        }

        set(value) {
            self.values[field] = value
         }
    }

    // MARK: - Json Convertable
    public required init(dictionary: [String: AnyObject]) {
        if let postage = dictionary["postagem"] as? [String: AnyObject], let codPostage = postage["codPostagem"] as? Int {
            self.postageCod = codPostage
        }

        if let json = dictionary["JSON"] as? String {
            if let data = json.data(using: String.Encoding.utf8) {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers), let dicJson = jsonObject as? [String: AnyObject] {
                    self.values = dicJson
                }
            }
        }
        if let text = dictionary["texto"] as? String {
            self.text = text
        }

        if let value = dictionary["valor"] as? Double {
            self.numericValue = value
        }
    }

    public func asDictionary() -> [String: AnyObject] {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self.values, options: JSONSerialization.WritingOptions.prettyPrinted) {
            var data: [String: AnyObject] = [:]
            if let string = String(data: jsonData, encoding: String.Encoding.utf8) {
                data.updateValue(string as AnyObject, forKey: "JSON")
            }
            if let unwrappedText = self.text {
                data.updateValue(unwrappedText as AnyObject, forKey: "texto")
            }
            if let unwrappedValue = self.numericValue {
                data.updateValue(unwrappedValue as AnyObject, forKey: "valor")

            }
            return data
        }
        return [:]
    }

    // MARK: - Overrides
    public override var description: String {
        return  "APCPostageContent [additionalFields = \(self.values), text = \(String(describing: self.text)), numericValue = \(String(describing: self.numericValue))]"
    }

}
