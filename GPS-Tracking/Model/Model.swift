//
//  Model.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/10/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class Model: Mappable {
    
    // MARK: - Mappable
    
    public init(){}
    
    public required init?(_ map: Map) {
        mapping(map)
    }
    
    public func mapping(map: Map) {
        
    }
}