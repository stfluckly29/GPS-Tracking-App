//
//  API.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/9/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import ObjectMapper
import AlamofireObjectMapper
import LoginSignUpiOS


let apiGPSBaseUrl = ""
let apiNotificationsBaseUrl = ""
let apiPushNotificationsBaseUrl = ""
let apiGeoServiceBaseUrl = ""


public enum API {
    case GetPeriods(from: NSDate, to: NSDate)
    case GetTrack(from: NSDate, to: NSDate)
    case EventFeeds(userGlobalMasterId: String, companyGlobalMasterId: String)
    case SavePoints(pointsPack: GpsPackModel)
    case ZonesList
    case SaveZone(zone: BlackoutZoneModel)
    case DeleteZone(zoneId: String)
    case MakePeriodPublic(period: DtRangeModel)
    case MakePeriodPrivate(period: DtRangeModel)
    case MakePeriodPublicBulk(periods: [DtRangeModel])
    case MakePeriodPrivateBulk(periods: [DtRangeModel])
    case NotificationList(skip: Int, take: Int)
    case Subscribe(subscription: PushSubscriptionModel)
    case PeriodContexts(id: String)
    case EnablePeriodSharing(sharingModel: PeriodShareModel)
    case DisablePeriodSharing(sharingModel: PeriodShareModel)
    case ContextList
    case EnableSharing(globalIndexId: String)
    case DisableSharing(globalIndexId: String)
}


extension API {
    private var urlAndMethod: (String, Alamofire.Method) {
        switch self {
        case .EventFeeds:
            return (apiGPSBaseUrl, .GET)
        case .NotificationList:
            return (apiNotificationsBaseUrl, .POST)
        case .Subscribe:
            return (apiPushNotificationsBaseUrl, .POST)
        case .PeriodContexts:
            return (apiGeoServiceBaseUrl, .GET)
        case .EnablePeriodSharing, .DisablePeriodSharing, .ContextList, .EnableSharing, .DisableSharing, GetPeriods:
            return (apiGeoServiceBaseUrl, .POST)
        default:
            return (apiGPSBaseUrl, .POST)
        }
    }
    
    var keyPath: String? {
        switch self {
        case .EventFeeds, .GetPeriods, .GetTrack:
            return "Model"
        case .ZonesList, .NotificationList, .ContextList, PeriodContexts:
            return "Model.List"
        default:
            return nil
        }
    }
    
    var apiVersion: String {
        switch self {
        default:
            return "1.0.0.0"
        }
    }
}


private let JSONArrayKey = "JSONArray"
private var formater: NSDateFormatter! = {
    let _formater = NSDateFormatter()
    _formater.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    _formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ"
    return _formater
}()

extension API: URLRequestConvertible {
    public var URLRequest: NSMutableURLRequest {
        let endpoint: (path: String, params: [String: AnyObject]?) = {
            switch self {
            case .GetPeriods(let from, let to):
                return ("Statistics/GetPeriods", [
                    "From" : formater.stringFromDate(from),
                    "To" : formater.stringFromDate(to),
                    "DetalizationLevel" : "2"   ])
            case .GetTrack(let from, let to):
                return ("Point/GetTrack", [
                    "From" : formater.stringFromDate(from),
                    "To" : formater.stringFromDate(to),
                    "DetalizationLevel" : "2"])
            case .EventFeeds(let userId, let companyId):
                return ("EventFeed/List", [
                    "UserGlobalMasterId" : userId,
                    "CompanyGlobalMasterId" : companyId])
            case .SavePoints(let pointsPack):
                return ("Point/Save", Mapper().toJSON(pointsPack) )
            case .ZonesList:
                return ("BlackoutZones/List", ["Version": "1.0.0.0"])
            case .SaveZone(let zone):
                return ("BlackoutZones/Save", Mapper().toJSON(zone))
            case .DeleteZone(let zoneId):
                return ("BlackoutZones/Delete/\(zoneId)", nil)
            case .MakePeriodPublic(let rangeModel):
                return ("Point/MakePeriodPublic", Mapper().toJSON(rangeModel))
            case .MakePeriodPrivate(let rangeModel):
                return ("Point/MakePeriodPrivate", Mapper().toJSON(rangeModel))
            case .MakePeriodPublicBulk(let rangeModels):
                return ("Point/MakePeriodPublicBulk", [JSONArrayKey: Mapper().toJSONArray(rangeModels)])
            case .MakePeriodPrivateBulk(let rangeModels):
                return ("Point/MakePeriodPrivateBulk", [JSONArrayKey: Mapper().toJSONArray(rangeModels)])
            case .NotificationList(let skip, let take):
                return ("Notifications/List", [
                    "Skip" : "\(skip)",
                    "Take" : "\(take)"])
            case .Subscribe(let subscription):
                return ("PushNotification/Subscribe", Mapper().toJSON(subscription))
            case .PeriodContexts(let id):
                return ("Statistics/GetPeriodContexts/\(id)", nil)
            case .EnablePeriodSharing(let sharingModel):
                return ("Statistics/EnablePeriodSharing", Mapper().toJSON(sharingModel))
            case .DisablePeriodSharing(let sharingModel):
                return ("Statistics/DisablePeriodSharing", Mapper().toJSON(sharingModel))
            case .ContextList:
                return ("Context/List", nil)
            case .EnableSharing(let globalIndexId):
                return ("Context/EnableSharing", ["GlobalIndexId": globalIndexId])
            case .DisableSharing(let globalIndexId):
                return ("Context/DisableSharing", ["GlobalIndexId": globalIndexId])
            }
        }()
        
        
        
        let (baseUrl, httpMethod) = urlAndMethod
        
        let encoding: ParameterEncoding = {
            switch self {
            case .EventFeeds:
                return ParameterEncoding.URL
            case .MakePeriodPublicBulk, MakePeriodPrivateBulk:
                return ParameterEncoding.Custom{ (request, param) in
                    let mutableURLRequest = request.URLRequest
                    var encodingError: NSError? = nil
                    do {
                        let options = NSJSONWritingOptions()
                        let data = try NSJSONSerialization.dataWithJSONObject(param![JSONArrayKey]!, options: options)
                        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        mutableURLRequest.HTTPBody = data
                    } catch {
                        encodingError = error as NSError
                    }
                    return (mutableURLRequest, encodingError)
                }
            default:
                return ParameterEncoding.JSON
            }
        }()
        
        guard let url = NSURL(string: baseUrl + endpoint.path) else {
            fatalError("[API] Constructed API url invalid for \(self)")
        }
        
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = httpMethod.rawValue
        
        
        if let accessToken = RLUserObject.instance().userToken {
            request.addValue("\(accessToken)", forHTTPHeaderField: "X-PlatformAuth")
        }
        request.addValue(apiVersion, forHTTPHeaderField: "X-ApiVersion")
        
        let (encodedRequest, error) = encoding.encode(request, parameters: endpoint.params)
        
        if let error = error {
            print("[API] Error encoding request params: \(error)")
        }
        
        if let url = encodedRequest.URL {
            print("🚀\(url)")
            //print(endpoint.params)
            //print(request.allHTTPHeaderFields)
        }
        
        return encodedRequest
    }
}

extension API {
    
    public static func getList<T: Mappable>(r: API) -> Observable<[T]> {
        return Observable.create({ (observer: AnyObserver<[T]>) -> Disposable in
            let request = manager.request(r).responseArray(dispatch_get_global_queue(0, 0),
                keyPath: r.keyPath,
                completionHandler:{ (response: Response<[T], NSError>) -> Void in
                    if let error = response.result.error {
                        observer.onError(error)
                    } else if let value = response.result.value {
                        observer.onNext(value)
                        observer.onCompleted()
                    } else {
                        observer.onNext([])
                        observer.onCompleted()
                    }
            })
            
            return AnonymousDisposable{
                request.cancel()
            }
        })
    }
    
    public static func getObject<T: Mappable>(r: API) -> Observable<T> {
        return Observable.create({ (observer: AnyObserver<T>) -> Disposable in
            let request = manager.request(r).responseObject(dispatch_get_global_queue(0, 0),
                keyPath: r.keyPath,
                completionHandler:{ (response: Response<T, NSError>) -> Void in
                    if let error = response.result.error {
                        observer.onError(error)
                    } else if let value = response.result.value {
                        observer.onNext(value)
                        observer.onCompleted()
                    } else {
                        observer.onError(APIError.MissingDataError(reason: "Missing content"))
                    }
            })
            
            return AnonymousDisposable{ request.cancel() }
        })
    }
    
    public static func postObject<T: Mappable>(r: API) -> Observable<T> {
        return Observable.create({ (observer: AnyObserver<T>) -> Disposable in
            let request = manager.request(r).responseObject(dispatch_get_global_queue(0, 0),
                keyPath: r.keyPath,
                completionHandler:{ (response: Response<T, NSError>) -> Void in
                    if let error = response.result.error {
                        observer.onError(error)
                    } else if let value = response.result.value {
                        observer.onNext(value)
                        observer.onCompleted()
                    } else {
                        observer.onError(APIError.MissingDataError(reason: "Missing content"))
                    }
            })
            
            return AnonymousDisposable{ request.cancel()}
        })
    }
    
    static var manager: Manager = {
        var defaultHeaders = Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHeaders
        
        return Manager(configuration: configuration)
    }()

}

enum APIError: ErrorType{
    case ParseError(reason: String)
    case MissingDataError(reason: String)
}




