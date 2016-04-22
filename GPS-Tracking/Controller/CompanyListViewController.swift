//
//  CompanyListViewController.swift
//  LoadSetGPS
//
//  Created by Stefan on 1/30/16.
//  Copyright © 2016 Realine. All rights reserved.
//

import UIKit
import RxSwift

let topLabelHeight: CGFloat = 68

public class CompanyListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var viewModel: CompanyListViewModel!
    var activityIndicator: UIActivityIndicatorView!
    
    init(_ viewModel: CompanyListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        super.loadView()
        let viewFrame = self.view.frame
        var tableViewFrame = self.view.frame
        if let topLabel = viewModel.topLabel {
            let labelFrame = CGRect(x: viewFrame.origin.x, y: viewFrame.origin.y, width: viewFrame.size.width, height: topLabelHeight)
            tableViewFrame.size.height -= topLabelHeight
            tableViewFrame.origin.y += topLabelHeight
            
            let label = PaddingLabel(frame: labelFrame)
            self.view.addSubview(label)
            label.textAlignment = .Left
            label.backgroundColor = UIColor.whiteColor()
            label.lineBreakMode = .ByWordWrapping
            label.numberOfLines = 2
            label.insets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            label.font = UIFont.systemFontOfSize(11)
            label.textColor = Theme.service.textColorGrey
            label.text = topLabel
        }
        
        tableView = UITableView(frame: tableViewFrame)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.view.addSubview(tableView)
        self.navigationItem.title = viewModel.navigationTitle
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.active = true
        
        _ = viewModel.errorObservable.observeOn(MainScheduler.instance).subscribeNext{
            self.showAlert($0)
            self.activityIndicator.stopAnimating()
        }
        _ = viewModel.loadingObservable.observeOn(MainScheduler.instance).subscribeNext{
            if $0  {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
        
        viewModel.loadList{
            self.tableView.reloadData()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = self.addActivityIndicator()
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.active = false
    }
}

extension CompanyListViewController {
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numbersOfSections
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return viewModel.configureCell(forIndexPath: indexPath, tableView: tableView)
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        viewModel.enableSharing(indexPath){ _ in self.tableView.reloadData() }
    }    
}

