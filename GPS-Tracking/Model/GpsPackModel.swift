//
//  GpsPackModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/22/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class GpsPackModel: Model {
    public private(set) var deviceId: String?
    public private(set) var points: [GpsPointSimpleModel] = []
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        deviceId <- map["DeviceId"]
        points <- map["Points"]
    }
    
    public init(locations: [Location]) {
        super.init()
        deviceId = "iOS_Device"
        points = locations.map{ GpsPointSimpleModel(location: $0) }
    }

    public required init?(_ map: Map) {
        super.init(map)
    }
    
}