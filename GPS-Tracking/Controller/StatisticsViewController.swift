 //
//  StatisticsViewController.swift
//  LoadSetGPS
//
//  Created by Alexander Povkolas on 11/2/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import SwiftDate
import LoginSignUpiOS

/* 
 * Date seletor legend
 *
 * T - tap
 * C - change date
 * S - selected field
 
 * F - from
 * T - to
 * N - nothing
 * A - all
 * Nx - next
 * F - filled
 */

// Date selector states
enum DS: Int {
    case NSNF // Notign selected nothing filled
    case NSFF // Notign selected from filled
    case NSTF // Notign selected to filled
    case NSAF // Notign selected all filled
    
    case FSFF // From selected from filled
    case FSAF // From selected all filled
    
    case TSTF // To selected to filled
    case TSAF // To selected all filled
    case DONE
}
 
// Date selector actions
enum DA: Int {
    case TapFrom
    case TapTo
    case TapNext
    case ChangeDate
}
 
// Statistic List states
enum SS: Int {
    case FullSize
    case HalfSize
    case Footer
}

// Statistic List actions
enum SA: Int {
    case HeaderSwipeUp
    case HeaderSwipeDown
    case HeaderTap
    case FooterSwipeUp
}

enum Period: Int {
    case Day
    case ThreeDays
    case Week
    case Custom
    
    var period: (NSDate, NSDate)!{
        let today = NSDate()
        switch self{
        case .Day:
            return (today-1.day, today)
        case .ThreeDays:
            return (today-3.day, today)
        case .Week:
            return (today-1.week, today)
        default:
            return (today, today)
        }
    }
}

private let defaultMapPadding: CGFloat = 50
private let sliderMaxValue: Float = 1000
 
class StatisticsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var trackerSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var drivingLabel: UILabel!
    @IBOutlet weak var idleLabel: UILabel!
    @IBOutlet weak var statisticTableView: UITableView!
    @IBOutlet weak var dateCaptionLabel: UILabel!
    @IBOutlet weak var milesCaptionLabel: UILabel!
    @IBOutlet weak var drivingCaptionLabel: UILabel!
    @IBOutlet weak var idleCaptionLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerPosition: NSLayoutConstraint!
    @IBOutlet var headerTap: UITapGestureRecognizer!
    @IBOutlet var headerSwipeUp: UISwipeGestureRecognizer!
    @IBOutlet var headerSwipeDown: UISwipeGestureRecognizer!
    @IBOutlet var footerSwipeUp: UISwipeGestureRecognizer!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var fromCaptionLabel: UILabel!
    @IBOutlet weak var toCaptionLabel: UILabel!
    @IBOutlet weak var fromDateLabel: UILabel!
    @IBOutlet weak var toDateLabel: UILabel!
    @IBOutlet weak var datesView: UIView!
    @IBOutlet weak var datesViewTopSpace: NSLayoutConstraint!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var textFieldForPicker: UITextField!
    @IBOutlet weak var deselectAllButton: UIButton!
    @IBOutlet weak var makeButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var locateButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var sliderLabel: UILabel!    
    @IBOutlet weak var sliderLabelOffset: NSLayoutConstraint!
    
    var nextButton: UIBarButtonItem!
    var slider: UISlider!

    var picker : UIDatePicker!
    
    private let viewModel = MapViewModel()
    
    private let offset: CGFloat = 14
    
    private var currentPositionAnnotation: CurrentPosition?
    
    private var mapEdgePadding = UIEdgeInsetsMake(defaultMapPadding, defaultMapPadding, defaultMapPadding, defaultMapPadding)
    
    private var animating = false
    private var currentStatState = SS.HalfSize;
    private var currentDateState = DS.NSNF;
    
    
    private var uiDisposeBag: DisposeBag!
    
    private let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight)) as UIVisualEffectView

    private let statStateTransitions: [[SS]] =
        [[.FullSize, .HalfSize, .FullSize, .FullSize],
        [.FullSize, .Footer, .HalfSize, .HalfSize],
        [.HalfSize, .Footer, .HalfSize, .HalfSize]];

    
    private let dateStateTransitions: [[DS]] =
        [[.FSFF, .TSTF, .FSFF, .NSNF],
        [.FSFF, .TSAF, .FSFF, .NSFF],
        [.FSAF, .TSTF, .FSAF, .NSTF],
        [.FSAF, .TSAF, .DONE, .NSAF],
        [.FSFF, .TSAF, .TSAF, .FSFF],
        [.FSAF, .TSAF, .TSAF, .FSAF],
        [.TSAF, .TSTF, .FSAF, .TSTF],
        [.FSAF, .TSAF, .DONE, .TSAF]];

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAppearance()
        setupTableView()
        calculateMapEdgePadding()
        
        visualEffectView.frame = self.datesView.frame
        visualEffectView.frame.origin.y += visualEffectView.frame.size.height
        visualEffectView.frame.size.height = 0
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewBecomeActive()
        self.showButtons(false)
        self.viewModel.clearPeriods()
        calculateMapEdgePadding()
    }
    
    func viewBecomeActive(){
        viewModel.active = true
        uiDisposeBag = DisposeBag()
        trackerSwitch.on = viewModel.trackerEnabled
        milesCaptionLabel.text = viewModel.distanceDescription
        RLLoginSignUpManager.sharedManager().sideMenuPanGestureDelegate = self
        _ = viewModel.errorObservable.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in
            self?.showAlert($0)
        }
        _ = viewModel.loadingObservable.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in
            if $0  {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
                self?.deselectAllButtons()
            }
        }

        setupTableViewSubscriptions()
        setupMap()
        
        _ = NSNotificationCenter.defaultCenter()
            .rx_notification(UIApplicationDidEnterBackgroundNotification, object: nil)
            .takeUntil(viewModel.didBecomeInactive).subscribeNext{ [weak self] _ in self?.viewBecomeInactive() }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewBecomeInactive()
    }
    
    func viewBecomeInactive(){
        viewModel.active = false
        mapView.showsUserLocation = false
        uiDisposeBag = nil
        _ = NSNotificationCenter.defaultCenter()
            .rx_notification(UIApplicationWillEnterForegroundNotification, object: nil)
            .takeUntil(self.viewModel.didBecomeActive).subscribeNext{ [weak self] _ in self?.viewBecomeActive() }
    }
    
    func setupAppearance(){
        titleLabel.textColor = Theme.service.navigationBarTitleTextColor
        totalLabel.textColor = Theme.service.textColorDark
        milesLabel.textColor = Theme.service.textColorDark
        drivingLabel.textColor = Theme.service.textColorDark
        idleLabel.textColor = Theme.service.textColorDark
        
        dateCaptionLabel.textColor = Theme.service.textColorLightGrey
        milesCaptionLabel.textColor = Theme.service.textColorLightGrey
        drivingCaptionLabel.textColor = Theme.service.textColorLightGrey
        idleCaptionLabel.textColor = Theme.service.textColorLightGrey
        fromCaptionLabel.textColor = Theme.service.textColorLightGrey
        toCaptionLabel.textColor = Theme.service.textColorLightGrey
        fromDateLabel.textColor = Theme.service.textColorLightGrey
        toDateLabel.textColor = Theme.service.textColorLightGrey
        infoLabel.textColor = Theme.service.textColorBlue
        
        trackerSwitch.onTintColor = nil
    }
    
    @IBAction func openMenu(sender: AnyObject) {
        textFieldForPicker.resignFirstResponder()
        RLLoginSignUpManager.sharedManager().toggleSideMenu()
    }
}

extension StatisticsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        switch otherGestureRecognizer{
        case headerTap, headerSwipeDown, headerSwipeUp, footerSwipeUp:
            return true
        default:
            return false
            
        }
    }
}

// MARK: - Statistics Table View routines

extension StatisticsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        self.statisticTableView.registerNib(UINib.init(nibName:CellTypes.Statistic.rawValue, bundle: nil), forCellReuseIdentifier: CellTypes.Statistic.rawValue)
        self.statisticTableView.registerNib(UINib.init(nibName:CellTypes.AverageStatistic.rawValue, bundle: nil), forCellReuseIdentifier: CellTypes.AverageStatistic.rawValue)
    }
    
    func setupTableViewSubscriptions() {
        setupAnimation()
        
        // list & footer updates
        _ = viewModel.statsUpdateObservable
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] footerData in
                    let allowSelection = !(self?.viewModel.noStatistics ?? true )
                    self?.statisticTableView.allowsSelection = allowSelection
                    self?.statisticTableView.allowsMultipleSelection = allowSelection
                    self?.setFooterValues(footerData)
                    self?.statisticTableView.reloadData() },
                onError: { [weak self] _ in
                    let allowSelection = !(self?.viewModel.noStatistics ?? true )
                    self?.statisticTableView.allowsSelection = allowSelection
                    self?.statisticTableView.allowsMultipleSelection = allowSelection
                    self?.setFooterValues(("0", "0", "0")) })
        
        // segmentedControl actions
        self.segmentedControl.rx_value.subscribeNext{ [weak self] index in
            self?.segmentChanged(index)
        }.addDisposableTo(uiDisposeBag)
        
        // custom time interval
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        nextButton = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Done, target: nil, action: nil)
        self.picker = createPicker(cancelButton, nextButton: nextButton)
        self.picker.maximumDate = NSDate()
        
        
        // blur view when date picker appears
        var frame = mapView.frame
        frame.origin.y += CGRectGetHeight(datesView.frame)
        _ = viewModel.bluredFrame(frame)
            .subscribeNext { [weak self] in
                self?.visualEffectView.frame = $0
                if let visualEffectView = self?.visualEffectView {
                    self?.view.addSubview(visualEffectView)
                }
        }
        
        nextButton.rx_tap.subscribeNext { [weak self] _ in self?.changeDateState(.TapNext) }.addDisposableTo(uiDisposeBag)
        self.fromButton.rx_tap.subscribeNext { [weak self] _ in self?.changeDateState(.TapFrom) }.addDisposableTo(uiDisposeBag)
        self.toButton.rx_tap.subscribeNext { [weak self] _ in self?.changeDateState(.TapTo) }.addDisposableTo(uiDisposeBag)
        self.picker.rx_date.skip(1).subscribeNext {[weak self]  _ in self?.changeDateState(.ChangeDate) }.addDisposableTo(uiDisposeBag)

        
        cancelButton.rx_tap.subscribeNext{ [weak self] in self?.textFieldForPicker.resignFirstResponder() }.addDisposableTo(uiDisposeBag)
        _ = viewModel.keyboardHideObservable.subscribeNext{ [weak self] _ in self?.visualEffectView.removeFromSuperview() }
        
        self.footerPosition.constant = self.mapView.frame.size.height/2 - self.headerView.frame.size.height
        
        // Private/public periods
        deselectAllButton.rx_tap.subscribeNext { [weak self] in self?.deselectAllButtons() }.addDisposableTo(uiDisposeBag)
        
        makeButton.rx_tap.subscribeNext {
            self.navigationController?.pushViewController(CompanyListViewController(self.viewModel.sharingViewModel), animated: true)
        }.addDisposableTo(uiDisposeBag)
        self.visualEffectView.removeFromSuperview()
    }
    
    func segmentChanged(index: Int){
        if (index != Period.Custom.rawValue){
            self.viewModel.clearData()
            self.removeOverlays()
            let (from, to) = Period(rawValue: index)!.period
            self.viewModel.loadStatistic(from: from, to: to)
            self.viewModel.loadTrack(from: from, to: to)
            
            self.datesViewTopSpace.constant = -self.datesView.frame.size.height
        } else {
            self.datesViewTopSpace.constant = 0
            if self.viewModel.isIphone4s {
                self.changeStatState(.HeaderSwipeDown, animated:false)
            }
        }
        calculateMapEdgePadding()
        
        self.textFieldForPicker.resignFirstResponder()
        UIView.animateWithDuration(0.5){ self.view.layoutIfNeeded() }
    }
    
    func deselectAllButtons(){
        let range = 0...self.statisticTableView.numberOfSections - 1
        range.forEach{ self.setSectionSelected(self.statisticTableView, section: $0, selected: false) }
        self.showButtons(false)
        self.viewModel.clearPeriods()
    }
    
    func setFooterValues(values: (String, String, String)){
        self.milesLabel.text = values.0
        self.drivingLabel.text = values.1
        self.idleLabel.text = values.2
    }
    
    func setSectionSelected(tableView: UITableView, section: Int, selected: Bool) {
        let range = 0...tableView.numberOfRowsInSection(section) - 1
        if (selected) {
            range.forEach{
                let indexPath = NSIndexPath(forRow: $0, inSection: section)
                if $0 > 0 {
                    viewModel.addPeriod(indexPath)
                }
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
        } else {
            range.forEach{
                let indexPath = NSIndexPath(forRow: $0, inSection: section)
                if $0 > 0 {
                    viewModel.removePeriod(indexPath)
                }
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
        }
    }
    
    func showButtons(show: Bool){
        totalLabel.hidden = show
        milesLabel.hidden = show
        drivingLabel.hidden = show
        idleLabel.hidden = show
        deselectAllButton.hidden = !show
        makeButton.hidden = !show
        makeButton.setTitle("Set privacy", forState: .Normal)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.removeOverlays()
        if indexPath.row == 0 {
            viewModel.addDayPeriod(indexPath.section)
            setSectionSelected(tableView, section:indexPath.section, selected: true)
        } else {
            let selectSection = viewModel.addPeriod(indexPath)
            if selectSection { setSectionSelected(tableView, section:indexPath.section, selected: true) }
        }
        showButtons(viewModel.isSelected)
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.removeOverlays()
        if indexPath.row == 0 {
            viewModel.removeDayPeriod(indexPath.section)
            setSectionSelected(tableView, section:indexPath.section, selected: false)
        } else {
            viewModel.removePeriod(indexPath)
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: indexPath.section), animated: false)
        }
        showButtons(viewModel.isSelected)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numbersOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(section: section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return viewModel.configureCell(forIndexPath: indexPath, tableView: tableView)
    }
    
    private func calculateMapEdgePadding(){
        mapEdgePadding.top = self.datesViewTopSpace.constant == 0 ? self.datesView.frame.size.height + defaultMapPadding : defaultMapPadding
        mapEdgePadding.bottom = self.footerPosition.constant + self.headerView.frame.size.height + defaultMapPadding
    }
    
    private func createPicker(cancelButton: UIBarButtonItem, nextButton: UIBarButtonItem) -> UIDatePicker{
        let picker = UIDatePicker()
        picker.sizeToFit()
        picker.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        picker.backgroundColor = UIColor.whiteColor()
        textFieldForPicker.inputView = picker
        
        let toolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.Black
        toolbar.translucent = false
        toolbar.barTintColor = Theme.service.navigationBarBarTintColor
        toolbar.tintColor = Theme.service.navigationBarTintColor
        toolbar.sizeToFit()
        
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbar.setItems([cancelButton, space, nextButton], animated: false)
        textFieldForPicker.inputAccessoryView = toolbar
        
        return picker
    }
    
    private func createSlider(){
        slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = sliderMaxValue
        mapView.addSubview(slider)
        view.bringSubviewToFront(slider)
        slider.transform  = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
        slider.frame = sliderFrame()
    }
    
    private func sliderFrame() -> CGRect {
        return CGRectMake(mapView.frame.size.width - 60, 10, 50, mapView.frame.size.height - footerPosition.constant - 60 - locateButton.frame.size.height)
    }
    
    // MARK: - Statistics Table View sliding
    private func setupAnimation(){
        self.headerTap.rx_event.subscribeNext { [weak self] _ in self?.changeStatState(.HeaderTap) }.addDisposableTo(uiDisposeBag)
        self.headerSwipeDown.rx_event.subscribeNext { [weak self] _ in self?.changeStatState(.HeaderSwipeDown) }.addDisposableTo(uiDisposeBag)
        self.headerSwipeUp.rx_event.subscribeNext { [weak self] _ in self?.changeStatState(.HeaderSwipeUp) }.addDisposableTo(uiDisposeBag)
        self.footerSwipeUp.rx_event.subscribeNext { [weak self] _ in self?.changeStatState(.FooterSwipeUp) }.addDisposableTo(uiDisposeBag)
    }
    
    private func removeOverlays(){
        mapView.removeOverlays(mapView.overlays.filter{ $0.title! != RouteType.Expected.description })
    }
    
    private func changeDateState(action: DA){

        switch (action, currentDateState) {
        case (.ChangeDate, .FSFF), (.ChangeDate, .FSAF):
            viewModel.fromDate = picker.date
            viewModel.toDate = viewModel.fromDate > viewModel.toDate ?
                min(viewModel.fromDate + 7.days, NSDate()) : min(viewModel.toDate, viewModel.fromDate + 7.days)
        case (.ChangeDate, .TSTF), (.ChangeDate, .TSAF):
            viewModel.toDate = picker.date
        case (.TapFrom, _), (.TapNext, .TSTF):
            picker.date = viewModel.fromDate
            picker.minimumDate = nil
            picker.maximumDate = NSDate()
        case (.TapTo, _), (.TapNext, .FSFF), (.TapNext, .FSAF) :
            picker.date = viewModel.toDate
            picker.minimumDate = viewModel.fromDate
            picker.maximumDate = min(NSDate(), viewModel.fromDate + 7.days)
        default: break
        }
        
        currentDateState = dateStateTransitions[currentDateState.rawValue][action.rawValue]
        
        switch currentDateState {
        case .NSNF:
            fromDateLabel.textColor = Theme.service.textColorLightGrey
            toDateLabel.textColor = Theme.service.textColorLightGrey
        case .NSFF, .NSTF, .NSAF:
            fromDateLabel.textColor = Theme.service.textColorLightGrey
            toDateLabel.textColor = Theme.service.textColorLightGrey
        case .FSFF:
            nextButton.title = "Next"
            self.textFieldForPicker.becomeFirstResponder()
            fromDateLabel.text =  viewModel.fromDateString
            fromDateLabel.textColor = Theme.service.textColorBlue
            toDateLabel.textColor = Theme.service.textColorLightGrey
        case .FSAF:
            nextButton.title = "Next"
            textFieldForPicker.becomeFirstResponder()
            fromDateLabel.text =  viewModel.fromDateString
            fromDateLabel.textColor = Theme.service.textColorBlue
            toDateLabel.textColor = Theme.service.textColorLightGrey
        case .TSTF:
            nextButton.title = "Next"
            textFieldForPicker.becomeFirstResponder()
            toDateLabel.text =  viewModel.toDateString
            fromDateLabel.textColor = Theme.service.textColorLightGrey
            toDateLabel.textColor = Theme.service.textColorBlue
        case .TSAF:
            nextButton.title = "Done"
            textFieldForPicker.becomeFirstResponder()
            toDateLabel.text =  viewModel.toDateString
            toDateLabel.textColor = Theme.service.textColorBlue
            fromDateLabel.textColor = Theme.service.textColorLightGrey
        case .DONE:
            currentDateState = .NSAF
            nextButton.title = "Next"
            textFieldForPicker.resignFirstResponder()
            fromDateLabel.textColor = Theme.service.textColorLightGrey
            toDateLabel.textColor = Theme.service.textColorLightGrey
            updateData()
        }
    }
    
    private func updateData(){
        viewModel.clearData()
        removeOverlays()
        viewModel.loadStatistic(from: self.viewModel.fromDate, to: self.viewModel.toDate)
        viewModel.loadTrack(from: self.viewModel.fromDate, to: self.viewModel.toDate)
    }
    
    private func changeStatState(action: SA){
        changeStatState(action, animated: true)
    }
    
    private func changeStatState(action: SA, animated: Bool){
        let newState = statStateTransitions[currentStatState.rawValue][action.rawValue]
        
        guard !animating && newState != currentStatState else {
            return
        }
        
        currentStatState = newState
        switch currentStatState {
        case .FullSize:
            footerPosition.constant = mapView.frame.size.height - headerView.frame.size.height
            statisticTableView.allowsMultipleSelection = true
        case .HalfSize:
            footerPosition.constant = mapView.frame.size.height/2 - headerView.frame.size.height
            statisticTableView.allowsMultipleSelection = true
        case .Footer:
            footerPosition.constant = offset - headerView.frame.size.height
            statisticTableView.allowsSelection = false
        }
        
        calculateMapEdgePadding()
        if !slider.hidden {
            self.sliderLabelOffset.constant = -self.yPositionFromSliderValue(self.slider, sliderFrame: self.sliderFrame(), value: self.slider.value)
        }
        
        if animated {
            animating = true
            UIView.animateWithDuration(0.5,
                animations: {
                    self.slider.frame = self.sliderFrame()
                    self.view.layoutIfNeeded() },
                completion: {_ in self.animating = false})
        }
    }
}

// MARK: - MapView routines

extension StatisticsViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if let title = overlay.title {
            if (title == RouteType.Expected.description || title == RouteType.Tracked.description){
                let lineView = MKPolylineRenderer(overlay: overlay)
                lineView.strokeColor = UIColor.blueColor()
                return lineView
            } else if (title == RouteType.Selected.description){
                let lineView = MKPolylineRenderer(overlay: overlay)
                lineView.strokeColor = Theme.service.cellSelectedColor
                return lineView
            } else if (title == RouteType.Private.description){
                let lineView = MKPolylineRenderer(overlay: overlay)
                lineView.strokeColor = Theme.service.textColorLightGrey
                return lineView
            } else {
                let lineView = MKPolylineRenderer(overlay: overlay)
                lineView.strokeColor = UIColor.redColor()
                return lineView
            }
        }        
        return MKPolylineRenderer();
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }
        
        var view: MKAnnotationView?
        if let direction = annotation as? TrackPin {
            let reuseId = "selected"
            view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            if view == nil {
                view = MKPinAnnotationView(annotation: direction, reuseIdentifier: reuseId)
                (view! as! MKPinAnnotationView).pinColor = .Red
                view?.canShowCallout = true
            }
            
            view!.annotation = direction
        }

        if let direction = annotation as? CurrentPosition {
            let reuseId = "current"
            view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
            if view == nil {
                view = MKAnnotationView(annotation: direction, reuseIdentifier: reuseId)
                view?.canShowCallout = true
                view!.image = direction.icon
                view?.centerOffset = CGPoint(x:0.0, y:-15.0)
            }
            
            view!.annotation = direction
            
            currentPositionAnnotation = direction
        }
        
        return view
    }


    func setupMap(){
        if slider == nil {
            createSlider()
            slider.hidden = true
            sliderLabel.hidden = true
        }

        mapView.showsUserLocation = true
        mapView.removeOverlays(mapView.overlays)
        
        _ = viewModel.annotationsObservable.observeOn(MainScheduler.instance)
            .subscribeNext{ [weak self] annotations in
                self?.mapView.removeAnnotations(self?.mapView.annotations ?? [])
                self?.mapView.addAnnotations(annotations)
        }
        
        _ = viewModel.currentAnnotationsObservable.observeOn(MainScheduler.instance).subscribeNext{
            self.mapView.addAnnotation($0)
        }
        
        trackerSwitch.rx_value.subscribeNext{ [weak self] in
            self?.viewModel.trackerEnabled = $0
            if $0 && !(self?.viewModel.locationServicesDisabled ?? true) {
                self?.viewModel.trackerEnabled = true
            } else {
                self?.viewModel.trackerEnabled = false
                if (self?.viewModel.locationServicesDisabled ?? true) {
                    self?.showLocationDisabledAlert()
                    self?.trackerSwitch.on = false
                }
            }
        }.addDisposableTo(uiDisposeBag)
        
        _ = viewModel.nextSegment.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in self?.mapView.addOverlay($0) }
        _ = viewModel.savedRoute().observeOn(MainScheduler.instance).subscribeNext { [weak self] in self?.mapView.addOverlay($0) }
        _ = viewModel.unsavedRoute().observeOn(MainScheduler.instance).subscribeNext{ [weak self] in self?.mapView.addOverlay($0) }
        _ = viewModel.visibleRegion.observeOn(MainScheduler.instance).subscribeNext{ [weak self] rect in
            if let padding = self?.mapEdgePadding {
                self?.mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
            }
        }
        
        _ = viewModel.showSlider.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in
            self?.slider.maximumValue = Float(self?.viewModel.selectedPoints.count ?? 0)
            self?.slider.hidden = !$0
            self?.sliderLabel.hidden = !$0
        }
        
        refreshButton.rx_tap.subscribeNext{ [weak self] in
            if self?.segmentedControl.selectedSegmentIndex != Period.Custom.rawValue {
                self?.segmentChanged(self?.segmentedControl.selectedSegmentIndex ?? 0)
            } else if self?.currentDateState == .NSAF {
                self?.updateData()
            }
        }.addDisposableTo(uiDisposeBag)
        
        _ = viewModel.locateObservable.observeOn(MainScheduler.instance).subscribeNext { [weak self] in
            if $0 {
               self?.updateLocation()
            }
        }
        
        locateButton.rx_tap.subscribeNext{ [weak self] in
            self?.updateLocation()
        }.addDisposableTo(uiDisposeBag)
        
        slider.rx_value.subscribeNext{ [weak self] value in
            if let _ = self {
                let c = Int(value)
                if self!.viewModel.selectedPoints.count > c {
                    guard let point = self?.viewModel.selectedPoints[c] else {
                        return
                    }
                    
                    if let annotation = self!.currentPositionAnnotation {
                        self!.mapView.addAnnotation(CurrentPosition(location: point))
                        self!.mapView.removeAnnotation(annotation)
                    }
                    
                    self!.sliderLabelOffset.constant = -self!.yPositionFromSliderValue(self!.slider, sliderFrame: self!.slider.frame, value: value)
                    self!.sliderLabel.text = self!.viewModel.sliderTimeFormater.stringFromDate(point.timestamp!)
                    
                }
            }
        }.addDisposableTo(uiDisposeBag)
    }
    
    private func updateLocation(){
        self.viewModel.updateLocation { [weak self] in
            if let location = $0 where self != nil {
                let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(0.01, 0.01))
                self!.mapView.setVisibleMapRect(self!.MKMapRectForCoordinateRegion(region), edgePadding: self!.mapEdgePadding, animated: true)
            }
        }
    }
    
    private func yPositionFromSliderValue(slider: UISlider, sliderFrame: CGRect, value: Float) -> CGFloat {
        let imageHeight: CGFloat = 30.0
        let sliderRange = sliderFrame.size.height - imageHeight;
        let sliderOrigin = sliderFrame.origin.y + (imageHeight / 2.0);
        let sliderValueToPixels = (((value - slider.minimumValue)/(slider.maximumValue - slider.minimumValue)) * Float(sliderRange)) + Float(sliderOrigin);
        
        return CGFloat(sliderValueToPixels);
    }
    
    private func MKMapRectForCoordinateRegion(region: MKCoordinateRegion) -> MKMapRect {
        let a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
            region.center.latitude + region.span.latitudeDelta / 2,
            region.center.longitude - region.span.longitudeDelta / 2));
        let b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
            region.center.latitude - region.span.latitudeDelta / 2,
            region.center.longitude + region.span.longitudeDelta / 2));
        return MKMapRectMake(min(a.x,b.x), min(a.y,b.y), abs(a.x-b.x), abs(a.y-b.y));
    }
    
}


