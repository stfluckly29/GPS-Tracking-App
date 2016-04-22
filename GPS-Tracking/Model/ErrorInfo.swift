//
//  ErrorInfo.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/23/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class ErrorInfo: Model {
    
    public private(set) var key: String?
    public private(set) var errorMessage: String?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        key <- map["Key"]
        errorMessage <- map["ErrorMessage"]
    }
}