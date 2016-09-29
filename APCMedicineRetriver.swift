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
open class APCMedicineRetriver: NSObject {

    /**
     Busca remédios por parte do nome, apresentação, retornando os campos passados como parâmetros.
     - parameter product Parte do nome para busca.
     - parameter presentation Valor para filtro no campo apresentação.
     - parameter campos Campos do remédio que se deseja retornar. Se passado nil retorna todos os campos.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre os remédios no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func medicines(product: String?, presentation: String?, fields:[String]?, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        var sendParameters: [String : Any] = [:]
        sendParameters.updateOptionalValue(product as AnyObject?, forKey: "produto")
        sendParameters.updateOptionalValue(presentation as AnyObject?, forKey: "apresentacao")
        if let unwrappedFields = fields, let concatedFiels = String.concatStringsWithSeparator(strings: unwrappedFields, separator: ","){
            sendParameters.updateValue(concatedFiels as AnyObject, forKey: "campos")
        }
        Alamofire.request(APCURLProvider.medicinesURL(), parameters: sendParameters , encoding: .urlEncodedInURL, headers: nil).responseJSON { (responseObject) in
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
    open func medicines(product:String?, presentation: String?, fields:[String]?, numberOfMedicines: Int, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        var parameters: [String : AnyObject] = [:]
        parameters.updateOptionalValue(product as AnyObject?, forKey: "produto")
        parameters.updateOptionalValue(presentation as AnyObject?, forKey: "apresentacao")
        parameters.updateValue(numberOfMedicines as AnyObject, forKey: "quantidade")
        if let unwrappedFields = fields, let concatedFiels = String.concatStringsWithSeparator(strings: unwrappedFields, separator: ","){
            parameters.updateValue(concatedFiels as AnyObject, forKey: "campos")
        }
        Alamofire.request(APCURLProvider.medicinesURL(), parameters: parameters, encoding: .urlEncodedInURL, headers: nil).responseJSON { (responseObject) in
            self.medicinesResponseHandler(response: responseObject, result: result)
        }
    }
    
    /**
     Busca um remédio por código de barras.
     - parameter barCodeEAN Busca um remédio por código de barras.
     - parameter result Bloco que será executado após a operação ser completada. Retornará um objeto de APCOperationResponse com o Status da operação e sempre nil no campo data.
     - see APCOperationResponse.swift e APCOperationResultStatus
     */
    open func medicine(barCodeEAN: UInt64, result: @escaping (_ operationResponse: APCOperationResponse)-> Void){
        var parameters: [String : Any] = [:]
        parameters.updateOptionalValue(String(barCodeEAN) as AnyObject?, forKey: "codBarraEan")
        Alamofire.request(APCURLProvider.medicinesURL(), parameters: parameters, encoding: .urlEncodedInURL, headers: nil).responseJSON { (responseObject) in
            self.singleMedicineResponseHandler(response: responseObject, result: result)
        }
    }
    
    
    fileprivate func singleMedicineResponseHandler(response responseObject: DataResponse<Any>, result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let unwrappedValue = responseValue as? [[String : AnyObject]]{
                if let medicines = JsonObjectCreator.create(dictionaryArray: unwrappedValue, objectClass: APCMedicine.self) as? [APCMedicine] {
                    return medicines.first
                }
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
    
    fileprivate func medicinesResponseHandler(response responseObject: DataResponse<Any>, result: ((_ operationResponse: APCOperationResponse)-> Void)?){
        APCManagerUtils.responseHandler(response: responseObject, onSuccess: { (responseValue, responseHeaders) -> AnyObject? in
            if let unwrappedValue = responseValue as? [[String : AnyObject]]{
                return JsonObjectCreator.create(dictionaryArray: unwrappedValue, objectClass: APCMedicine.self) as? [APCMedicine] as AnyObject?
            }
            return nil
            }, onNotFound: nil, onUnauthorized: nil, onInvalidParameters: nil, onConnectionError: nil, result: result)
    }
}
