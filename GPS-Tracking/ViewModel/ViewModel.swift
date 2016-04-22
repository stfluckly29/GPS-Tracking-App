//
//  ViewModel.swift
//  LoadSetGPS
//
//  Created by Alexander Povkolas on 11/2/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import RxSwift


public class ViewModel {

    private let _active = BehaviorSubject(value: false)
    
    public var active: Bool {
        get {
            do {
                return try _active.value()
            } catch _ {
                return false
            }
        }
        set { _active.onNext(newValue) }
    }
    
    public var didBecomeActive: Observable<Bool>{
        return _active.asObservable().filter{ $0 }.distinctUntilChanged()
    }

    public var didBecomeInactive: Observable<Bool>{
        return _active.asObservable().filter{ !$0 }.distinctUntilChanged()
    }
    
    public func viewModel(forSeagueId id:String) -> ViewModel {
        fatalError("Must Override")
    }
    
}
