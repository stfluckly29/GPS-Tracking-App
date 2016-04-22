//
//  BlackoutZoneMapController.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/16/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import LoginSignUpiOS

public class BlackOutZoneMapController: UIViewController, MVVMControllerProtocol {
    private var viewModel: BlackoutZoneViewModel!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var zoneCircle: UIImageView!
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editTextField: UITextField!    
    @IBOutlet weak var deleteBottomEdge: NSLayoutConstraint!
    @IBOutlet weak var editTopEdge: NSLayoutConstraint!
    let defaultLocation = CLLocationCoordinate2D(latitude: 37.7, longitude: -122.4)
    var activityIndicator: UIActivityIndicatorView!
    
    let closeButton = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.Done, target: nil, action: nil)
    let regionChange = PublishSubject<Void>()
    
    private var uiDisposeBag: DisposeBag!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = self.addActivityIndicator()
        RLLoginSignUpManager.sharedManager().sideMenuPanGestureDelegate = self
        mapView.showsUserLocation = true
        setState(viewModel.state)
        if (viewModel.state == .View){
            mapView.setCenterCoordinate(viewModel.center, animated: false)
            mapView.setRegion(region(self.mapView, center: viewModel.center, radius: viewModel.radius), animated: false)
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.active = true
        uiDisposeBag = DisposeBag()
        _ = viewModel.errorObservable.observeOn(MainScheduler.instance).subscribeNext{ self.showAlert($0) }
        _ = viewModel.loadingObservable.observeOn(MainScheduler.instance).subscribeNext{
            if $0  {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }

        
        if (viewModel.state == .New){
            viewModel.updateLocation {
                if let location = $0 {
                    self.mapView.setRegion(self.region(self.mapView, center: location.coordinate, radius: Config.service.units.defZoneRadius), animated: true)
                } else {
                    self.showLocationDisabledAlert()
                    self.mapView.setRegion(self.region(self.mapView, center: self.defaultLocation, radius: Config.service.units.defZoneRadius), animated: true)
                }
            }
        }
        
        self.rightBarButton.rx_tap.subscribeNext {
            if self.viewModel.state == .View {
                self.setState(.Edit)
                UIView.animateWithDuration(0.5){ self.view.layoutIfNeeded() }
            } else {
                if !(self.editTextField.text?.isEmpty ?? true) {
                    self.viewModel.save{ self.navigationController?.popViewControllerAnimated(true) }
                } else {
                    self.viewModel.name = self.editTextField.placeholder!
                    self.viewModel.save{ self.navigationController?.popViewControllerAnimated(true) }
                }
                
            }            
        }.addDisposableTo(uiDisposeBag)
        
        self.closeButton.rx_tap.subscribeNext {
            switch self.viewModel.state!{
            case .New:
                self.navigationController?.popViewControllerAnimated(true)
            case .Edit:
                self.setState(.View)
                UIView.animateWithDuration(0.5){ self.view.layoutIfNeeded() }
            case .View:
                return
            }
        }.addDisposableTo(uiDisposeBag)
        
        self.deleteButton.rx_tap.subscribeNext{
            self.viewModel.delete{ self.navigationController?.popViewControllerAnimated(true) }
        }.addDisposableTo(uiDisposeBag)
        
        _ = viewModel.errorObservable.subscribeNext {
            self.showAlert($0)
        }
        
        regionChange.map{ self.mapView.centerCoordinate }.bindTo(viewModel.rx_center).addDisposableTo(uiDisposeBag)
        let radius = regionChange.map{ self.currentRadius() }
        radius.bindTo(viewModel.rx_radius).addDisposableTo(uiDisposeBag)
        radius.map{ "\($0.normalize().format(".1")) \(self.viewModel.distanceAbbr)" }.bindTo(radiusLabel.rx_text).addDisposableTo(uiDisposeBag)

        regionChange.onNext() // force first update
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.active = false
        uiDisposeBag = nil
        mapView.removeFromSuperview()
    }
    
    public func setViewModel(viewModel: ViewModel) {
        self.viewModel = viewModel as! BlackoutZoneViewModel
    }
    
    private func setState(state: ViewState){
        switch state {
        case .View:
            self.navigationItem.leftBarButtonItem = nil
            self.editTopEdge.constant = -self.editView.bounds.size.height
            self.deleteBottomEdge.constant = 0
            self.navigationItem.title = viewModel.name
            self.mapView.zoomEnabled = false
            self.mapView.scrollEnabled = false
            self.mapView.userInteractionEnabled = false
            self.viewModel.state = .View
            self.rightBarButton.title = "Edit"
            self.view.endEditing(true)
            self.mapView.userInteractionEnabled = false
        case .Edit:
            setEditState()
            self.viewModel.state = .Edit
            self.deleteBottomEdge.constant = 0
        case .New:
            setEditState()
            self.viewModel.state = .New
            self.deleteBottomEdge.constant = -self.deleteButton.bounds.height
        }
    }
    
    private func setEditState(){
        self.mapView.userInteractionEnabled = true
        self.navigationItem.leftBarButtonItem = closeButton
        self.editTopEdge.constant = 0
        self.navigationItem.title = ""
        self.mapView.zoomEnabled = true
        self.mapView.scrollEnabled = true
        self.mapView.userInteractionEnabled = true
        self.rightBarButton.title = "Done"
        self.editTextField.text = viewModel.name
        _ = self.editTextField.rx_text.bindTo(viewModel.rx_name)
    }
    
    private func currentRadius() -> Double {
        var point = zoneCircle.center
        let center = mapView.convertPoint(point, toCoordinateFromView: self.view)
        point.x += zoneCircle.bounds.size.width/2
        let edge = mapView.convertPoint(point, toCoordinateFromView: self.view)
        return MKMetersBetweenMapPoints(MKMapPointForCoordinate(center), MKMapPointForCoordinate(edge))/1000
    }

    
    private func region(mapView: MKMapView, center: CLLocationCoordinate2D, radius: Double) -> MKCoordinateRegion {
        let yC = Double(mapView.bounds.size.height / zoneCircle.bounds.height * 2.0)
        let xC = Double(mapView.bounds.size.width / zoneCircle.bounds.width * 2.0)
        
        let viewRegion = MKCoordinateRegionMakeWithDistance(center, yC * radius * 1000, xC * radius * 1000);
        return mapView.regionThatFits(viewRegion)
    }
}

extension BlackOutZoneMapController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return false
    }
}

extension BlackOutZoneMapController: UITextFieldDelegate {
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension BlackOutZoneMapController: MKMapViewDelegate {
    public func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionChange.onNext()
    }
}











