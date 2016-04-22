//
//  CompanySharingViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/30/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import Foundation
import RxSwift

public class CompanySharingViewModel: CompanyListViewModel {
    
    public override var navigationTitle: String {
        return  "Share Position History With"
    }
        
    public override func listObservable() -> Observable<[UserContextItem]> {
        return API.getList(.ContextList)
    }
    
    public override func enableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        return API.postObject(.EnableSharing(globalIndexId: item.globalIndexId ?? ""))
    }
    
    public override func disableSharingObservable(item: UserContextItem) -> Observable<ServiceResponseModel> {
        return API.postObject(.DisableSharing(globalIndexId: item.globalIndexId ?? ""))
    }
}