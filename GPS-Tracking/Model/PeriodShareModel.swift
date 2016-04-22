//
//  PeriodShareModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/29/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import ObjectMapper

public class PeriodShareModel: Model {
    public private(set) var globalIndexId: String?
    public private(set) var periodId: String?
    public private(set) var from: NSDate?
    public private(set) var to: NSDate?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        globalIndexId <- map["GlobalIndexId"]
        periodId <- map["PeriodId"]
        from <- (map["From"], ServerDateTransform())
        to <- (map["To"], ServerDateTransform())
    }
    
    public init(globalIndexId: String, periodId: String, from: NSDate, to: NSDate) {
        super.init()
        self.globalIndexId = globalIndexId
        self.periodId = periodId
        self.from = from
        self.to = to        
    }

    public required init?(_ map: Map) {
        super.init(map)
    }
}
