//
//  SettingsViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation


class SettingsViewModel: ViewModel {
    
    var appNotifications: Bool {
        get { return Config.service.appNotificationsEnabled }
        set { Config.service.appNotificationsEnabled = newValue }
    }
    
    var gpsZoneEntryNotification: Bool {
        get { return Config.service.gpsBlackoutZoneNotificationsEnabled }
        set { Config.service.gpsBlackoutZoneNotificationsEnabled = newValue }
    }
    
    var unit: UnitsOfMeasure {
        get { return Config.service.units }
        set { Config.service.units = newValue }
    }
    
    var sharingViewModel: CompanyListViewModel {
        return CompanySharingViewModel()
    }

}