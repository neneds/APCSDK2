//
//  APCMedicineRetriver.swift
//  APCAccessSDK
//
//  Created by Luciano Almeida on 6/28/16.
//  Copyright © 2016 Luciano Almeida. All rights reserved.
//

import Foundation
import Alamofire

/**
 Not Objective C support.
 */
public class APCMedicineRetriver: NSObject {

    /**
     Busca remédios por parte do nome, apresentação, retornando os campos passados como parâmetros.
     - parameter product Parte do nome para busca.
     - parameter presentation Valor para filtro no campo apresentação.
     - parameter campos Campos do remédio que se deseja retornar. Se passado nil retorna todos os campos.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre os remédios no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func medicines(product product: String?, presentation: String?, fields:[String]?, result: (operationResponse: APCOperationResponse)-> Void){
        var parameters: [String : AnyObject] = [:]
        parameters.updateOptionalValue(product, forKey: "produto")
        parameters.updateOptionalValue(presentation, forKey: "apresentacao")
        if let unwrappedFields = fields, let concatedFiels = String.concatStringsWithSeparator(strings: unwrappedFields, separator: ","){
            parameters.updateValue(concatedFiels, forKey: "campos")
        }
        Alamofire.request(.GET, APCURLProvider.medicinesURL(), parameters: parameters, encoding: .URLEncodedInURL, headers: nil).responseJSON { (responseObject) in
            self.medicinesResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Busca remédios por parte do nome, apresentação, retornando os campos passados como parâmetros com um limite definido pelo parâmetro numberOfMedicines.
     - parameter product Parte do nome para busca.
     - parameter presentation Valor para filtro no campo apresentação.
     - parameter campos Campos do remédio que se deseja retornar. Se passado nil retorna todos os campos.
     - parameter numberOfMedicines Máximo de remédios a ser retornado.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre os remédios no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func medicines(product product:String?, presentation: String?, fields:[String]?, numberOfMedicines: Int, result: (operationResponse: APCOperationResponse)-> Void){
        var parameters: [String : AnyObject] = [:]
        parameters.updateOptionalValue(product, forKey: "produto")
        parameters.updateOptionalValue(presentation, forKey: "apresentacao")
        parameters.updateValue(numberOfMedicines, forKey: "quantidade")
        if let unwrappedFields = fields, let concatedFiels = String.concatStringsWithSeparator(strings: unwrappedFields, separator: ","){
            parameters.updateValue(concatedFiels, forKey: "campos")
        }
        Alamofire.request(.GET, APCURLProvider.medicinesURL(), parameters: parameters, encoding: .URLEncodedInURL, headers: nil).responseJSON { (responseObject) in
            self.medicinesResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Busca um remédio por código de barras.
     - parameter barCodeEAN Busca um remédio por código de barras.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    public func medicine(barCodeEAN barCodeEAN: UInt64, result: (operationResponse: APCOperationResponse)-> Void){
        var parameters: [String : AnyObject] = [:]
        parameters.updateOptionalValue(String(barCodeEAN), forKey: "codBarraEan")
        Alamofire.request(.GET, APCURLProvider.medicinesURL(), parameters: parameters, encoding: .URLEncodedInURL, headers: nil).responseJSON { (responseObject) in
            self.singleMedicineResponseHandler(response: responseObject, result: result)
        }
    }
    
    
    private func singleMedicineResponseHandler(response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let unwrappedValue = responseValue as? [[String : AnyObject]]{
                if let medicines = JsonObjectCreator.create(dictionaryArray: unwrappedValue, objectClass: APCMedicine.self) as? [APCMedicine] {
                    return medicines.first
                }
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    private func medicinesResponseHandler(response responseObject: Response<AnyObject, NSError>, result: ((operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let unwrappedValue = responseValue as? [[String : AnyObject]]{
                return JsonObjectCreator.create(dictionaryArray: unwrappedValue, objectClass: APCMedicine.self) as? [APCMedicine]
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
}
