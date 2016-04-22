//
//  DtRangeModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 12/20/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import ObjectMapper

public class DtRangeModel: Model {

    public private(set) var from: NSDate?
    public private(set) var to: NSDate?
    
    override public func mapping(map: Map) {
        super.mapping(map)
        from <- (map["From"], ServerDateTransform())
        to <- (map["To"], ServerDateTransform())
    }
    
    public required init?(_ map: Map) {
        super.init(map)
    }
    
    public init(from: NSDate, to: NSDate) {
        super.init()
        self.from = from
        self.to = to
    }
}


