//
//  TrackedViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/15/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import CoreLocation

public class TrackedViewModel: NetworkingViewModel {
    var trackerEnabled: Bool {
        get { return Tracker.service.active }
        set {
            if newValue {
                Tracker.service.start()
            } else {
                Tracker.service.stop()
            }
        }
    }
    
    var locationServicesDisabled: Bool {
        let status = CLLocationManager.authorizationStatus()
        return (status == .Restricted || status == .Denied)
    }

}
