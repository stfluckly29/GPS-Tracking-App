//
//  PeriodSharingViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/30/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import RxSwift

public class PeriodSharingViewModel: CompanyListViewModel {
    
    var periodId: String!
    var from: NSDate!
    var to: NSDate!
    
    public override var navigationTitle: String {
        return  "Set Privacy"
    }
    
    public override var topLabel: String? {
        return "Select which companies can see your position history for this period"
    }
    
    init(periodId: String, from: NSDate, to: NSDate) {
        super.init()
        self.periodId = periodId
        self.from = from
        self.to = to
    }
    
    public override func listObservable() -> Observable<[UserContextItem]> {
        return API.getList(.PeriodContexts(id: periodId))
    }
    
    public override func enableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        let shareModel = PeriodShareModel(globalIndexId: item.globalIndexId ?? "", periodId: periodId, from: from, to: to)
        return API.postObject(.EnablePeriodSharing(sharingModel: shareModel))
    }
    
    public override func disableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        let shareModel = PeriodShareModel(globalIndexId: item.globalIndexId ?? "", periodId: periodId, from: from, to: to)
        return API.postObject(.DisablePeriodSharing(sharingModel: shareModel))
    }    
}