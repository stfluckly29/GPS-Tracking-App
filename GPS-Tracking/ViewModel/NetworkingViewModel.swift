//
//  LoadingViewModel.swift
//  LoadSetGPS
//
//  Created by Stefan on 12/23/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import RxSwift

public class NetworkingViewModel: ViewModel {
    
    private let loadingSubject = PublishSubject<Bool>()
    
    var activeLoadings: Int = 0 {
        didSet{
            self.loadingSubject.onNext(activeLoadings > 0)
        }
    }

    let errorSubject = PublishSubject<String>()

    public var errorObservable: Observable<String> { return errorSubject.asObservable().takeUntil(didBecomeInactive).observeOn(MainScheduler.instance) }
    public var loadingObservable: Observable<Bool> { return loadingSubject.asObservable().distinctUntilChanged().takeUntil(didBecomeInactive).observeOn(MainScheduler.instance) }
}