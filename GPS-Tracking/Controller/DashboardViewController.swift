//
//  DashboardViewController.swift
//  LoadSetGPS
//
//  Created by Stefan on 11/14/15.
//  Copyright © 2015 Stefan. All rights reserved.
//

import UIKit
import RxSwift
import SwiftDate
import KYCircularProgress

class DashboardViewController: UIViewController {
    @IBOutlet weak var trackerSwitch: UISwitch!
    @IBOutlet weak var statisticTableView: UITableView!
    @IBOutlet weak var dateCaptionLabel: UILabel!
    @IBOutlet weak var milesCaptionLabel: UILabel!
    @IBOutlet weak var drivingCaptionLabel: UILabel!
    @IBOutlet weak var idleCaptionLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dashboardView: UIView!
    @IBOutlet weak var hoursFramedView: UIView!
    @IBOutlet weak var milesFramedView: UIView!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var drivingStatisticsCaption: UILabel!
    var refreshControl:UIRefreshControl!
    
    @IBOutlet weak var travelledCaption: UILabel!
    var hoursProgress : KYCircularProgress!
    var milesCircle : KYCircularProgress!
    
    private var uiDisposeBag: DisposeBag!
    
    private let viewModel = DashboardViewModel()
    
    override func viewDidLoad() {
        setupAppearance()
        setupTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        viewModel.active = true
        uiDisposeBag = DisposeBag()
        trackerSwitch.on = viewModel.trackerEnabled
        milesCaptionLabel.text = viewModel.distanceDescription
        travelledCaption.text = "\(viewModel.distanceDescription) travelled"
        _ = viewModel.errorObservable.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in
            self?.showAlert($0)
        }
        _ = viewModel.loadingObservable.observeOn(MainScheduler.instance).subscribeNext{ [weak self] in
            if $0  {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
                self?.refreshControl.endRefreshing()
            }
        }

        setupTableViewSubscriptions()
        fetchData()
        addCircles()
        
        
        trackerSwitch.rx_value.subscribeNext{
            self.viewModel.trackerEnabled = $0
            if $0 && !self.viewModel.locationServicesDisabled {
                self.viewModel.trackerEnabled = true
            } else {
                self.viewModel.trackerEnabled = false
                if self.viewModel.locationServicesDisabled {
                    self.showLocationDisabledAlert()
                    self.trackerSwitch.on = false
                }
            }
        }.addDisposableTo(uiDisposeBag)
        _ = viewModel.hoursObservable.observeOn(MainScheduler.instance).subscribeNext { [weak self] in
            self?.hoursLabel.text = $0
            self?.hoursProgress.progress = $1
        }
        _ = viewModel.milesObservable.observeOn(MainScheduler.instance).bindTo(milesLabel.rx_text)
    }
    
    override func viewDidDisappear(animated: Bool) {
        viewModel.active = false
        uiDisposeBag = nil
    }
    
    func setupAppearance(){
        self.dateCaptionLabel.hidden = true
        self.milesCaptionLabel.hidden = true
        self.drivingCaptionLabel.hidden = true
        self.idleCaptionLabel.hidden = true
        self.statisticTableView.hidden = true
        
        dateCaptionLabel.textColor = Theme.service.textColorGrey
        milesCaptionLabel.textColor = Theme.service.textColorGrey
        drivingCaptionLabel.textColor = Theme.service.textColorGrey
        idleCaptionLabel.textColor = Theme.service.textColorGrey
        drivingStatisticsCaption.textColor = Theme.service.textColorDark
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.statisticTableView.addSubview(self.refreshControl)
        
        self.dashboardView.layer.insertSublayer(Theme.service.gradientBackgroundLayer(self.dashboardView.bounds), atIndex:0)
    }
    
    func circle(frame: CGRect, lineWidth: Double) -> KYCircularProgress {
        let view = KYCircularProgress(frame: frame)
        view.progress = 0
        view.startAngle = -3.14/2
        view.endAngle = -3.14/2
        view.showProgressGuide = true
        view.progressGuideColor = UIColor(netHex: 0x155abb)
        view.guideLineWidth = lineWidth
        view.lineWidth = lineWidth
        view.colors = [UIColor.whiteColor()]
        return view
    }
    
    func addCircles(){
        hoursProgress = circle(self.hoursFramedView.frame, lineWidth: 6.0)
        self.dashboardView.addSubview(hoursProgress)
        var frame = self.milesFramedView.frame
        frame.origin.x += self.view.frame.size.width/2
        milesCircle = circle(frame, lineWidth: 2.0)
        milesCircle.progress = 1
        self.dashboardView.addSubview(milesCircle)
    }
}

extension DashboardViewController: UITableViewDataSource {
    
    func setupTableView() {
        self.statisticTableView.registerNib(UINib.init(nibName:CellTypes.Statistic.rawValue, bundle: nil), forCellReuseIdentifier: CellTypes.Statistic.rawValue)
        self.statisticTableView.registerNib(UINib.init(nibName:CellTypes.AverageStatistic.rawValue, bundle: nil), forCellReuseIdentifier: CellTypes.AverageStatistic.rawValue)
    }
    
    func fetchData() {
        self.viewModel.loadStatistic(from: NSDate() - 1.day, to: NSDate())
    }
    
    func setupTableViewSubscriptions() {
        self.refreshControl.rx_controlEvent(UIControlEvents.ValueChanged)
            .subscribeNext{ self.viewModel.loadStatistic(from: NSDate() - 1.day, to: NSDate()) }
            .addDisposableTo(uiDisposeBag)
        
        _ = viewModel.statsUpdateObservable
            .observeOn(MainScheduler.instance)
            .subscribeNext { [weak self] footerData in
                if (self?.viewModel.noStatistics ?? false){
                    self?.drivingStatisticsCaption.textColor = Theme.service.textColorLightGrey
                    self?.drivingStatisticsCaption.text = "No driving statistics yet"
                    
                    self?.dateCaptionLabel.hidden = true
                    self?.milesCaptionLabel.hidden = true
                    self?.drivingCaptionLabel.hidden = true
                    self?.idleCaptionLabel.hidden = true
                    self?.statisticTableView.hidden = true
                } else {
                    self?.drivingStatisticsCaption.textColor = Theme.service.textColorDark
                    self?.drivingStatisticsCaption.text = "Driving statistics"
                    
                    self?.dateCaptionLabel.hidden = false
                    self?.milesCaptionLabel.hidden = false
                    self?.drivingCaptionLabel.hidden = false
                    self?.idleCaptionLabel.hidden = false
                    self?.statisticTableView.hidden = false
                }
                self?.statisticTableView.reloadData()
        }
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
    
}