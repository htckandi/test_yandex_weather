//
//  DetailViewController.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController {
    
    var detailItem: City? {
        didSet {
            configureView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = detailItem?.name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Convenience
    
    func configureView () {
        
    }

    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath) as! DetailCell
        return cell
    }

}
