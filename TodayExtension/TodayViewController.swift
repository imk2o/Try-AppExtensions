//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by k2o on 2016/05/21.
//  Copyright © 2016年 Yuichi Kobayashi. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreMotion

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var stepsLabel: UILabel!
    
    private let pedometer: CMPedometer = {
        return CMPedometer()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func viewDidTap(sender: AnyObject) {
        // URLスキームでアプリを起動
        if let appURL = NSURL(string: "myapp://") {
            self.extensionContext?.openURL(appURL, completionHandler: nil)
        }
    }
    
    // MARK - NCWidgetProviding
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        guard CMPedometer.isStepCountingAvailable() else {
            completionHandler(.Failed)
            return
        }

        // 今日の00:00から現時刻までの歩数を求め、これを表示する
        let now = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: now)
        let startDate = calendar.dateFromComponents(dateComponents)

        self.pedometer.queryPedometerDataFromDate(startDate!, toDate: now) { (data, error) in
            if let _ = error {
                completionHandler(.Failed)
            } else if let steps = data?.numberOfSteps {
                self.stepsLabel.text = "\(steps) steps"
                completionHandler(.NewData)
            } else {
                completionHandler(.NoData)
            }
        }
    }

    // 通知センター内に確保されるマージンを調整したい場合に実装する
//    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
//        return UIEdgeInsetsZero
//    }
}
