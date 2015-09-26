//
//  DetailViewController.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var dataManager = DataManager.sharedManager
    
    var city: City? {
        didSet {
            configureView()
        }
    }
    
    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = city?.name
        timer = Timer(duration: Defaults.duration, handler: { [unowned self] in self.configureView()})
        timer.start()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        timer.stop()
        print("\nDetailViewController is deallocated.\n")
    }
    
    
    // MARK: - Convenience
    
    func configureView () {
        if let object = city {
            dataManager.loadCity(object)
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("detailCell", forIndexPath: indexPath) as! DetailCell
        return cell
    }

    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest(entityName: "CityWeather")
        fetchRequest.fetchBatchSize = 20
        fetchRequest.predicate = NSPredicate(format: "city == %@", [city!])
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataManager.managedObjectContext, sectionNameKeyPath:nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            print("Unresolved error \(error)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.reloadData()
    }
}
