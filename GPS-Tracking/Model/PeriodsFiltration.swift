//
//  PeriodsFiltration.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/25/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper


public class PeriodsFiltration: Model {
    
    public private(set) var minSatelliteCount: Int?
    public private(set) var minMoveSpeedKmh: Double?
    public private(set) var maxSpeed: Double?
    public private(set) var minMoveMileageKm: Double?
    public private(set) var minStopTime: NSTimeInterval?
    public private(set) var minBreakTime: NSTimeInterval?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        minSatelliteCount <- map["MinSatelliteCount"]
        minMoveSpeedKmh <- map["MinMoveSpeedKmh"]
        maxSpeed <- map["MaxSpeed"]
        minMoveMileageKm <- map["MinMoveMileageKm"]
        minStopTime <- (map["MinStopTime"], TimeIntervalTransform())
        minBreakTime <- (map["MinBreakTime"], TimeIntervalTransform())
    }
    
    class func defaultFilter() -> PeriodsFiltration {
        let periodFiltration = PeriodsFiltration()
        periodFiltration.minSatelliteCount = 0
        periodFiltration.minMoveSpeedKmh = 1
        periodFiltration.maxSpeed = 200
        periodFiltration.minMoveMileageKm = 0.1
        periodFiltration.minStopTime = 1.minutes
        periodFiltration.minBreakTime = 2.minutes
        return periodFiltration
    }
}