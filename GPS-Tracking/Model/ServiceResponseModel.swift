//
//  ServiceResponseModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/22/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class ServiceResponseModel: Model {
    public private(set) var status: Bool?
    public private(set) var errors: [ErrorInfo] = []
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        status <- map["Status"]
        errors <- map["Errors"]
    }
}