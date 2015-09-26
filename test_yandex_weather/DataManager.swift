//
//  DataManager.swift
//  test_yandex_weather
//
//  Created by Test on 9/25/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class DataManager: NSObject, NSXMLParserDelegate, XMLParserCsDelegate, XMLParserCDelegate {
    
    static let sharedManager = DataManager()
    
    var currentApplication: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    var timer: NSTimer!
    
    var isDataValid: Bool {
        var tempVar = false
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")), let randomObject = fetchedObjects.first as? City where isTimeValid(randomObject.timeStamp!) {
            tempVar = true
        }
        return tempVar
    }
    
    var isTimeValid: (NSDate) -> (Bool) = {
        return Int(NSDate().timeIntervalSinceDate($0)) < 60
    }
    
    var existedCities: [City] {
        var existed = [City]()
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")) as! [City] {
            existed.appendContentsOf(fetchedObjects)
        }
        return existed
    }

    var existedCitiesNames: ([City]) -> ([String]) = {
        var names = [String]()
        for object in $0 {
            names.append(object.name!)
        }
        return names
    }
    
    override init() {
        super.init()
        timer = NSTimer.scheduledTimerWithTimeInterval(61, target: self, selector: "loadCities", userInfo: nil, repeats: true)
    }
    
    deinit {
        timer.invalidate()
    }
    
    func loadCities () {
        
        print("\nIs data valid: \(isDataValid)")
        
        if !isDataValid {
            
            currentApplication.networkActivityIndicatorVisible = true
            
            let parser = XMLParserCities()
            parser.delegate = self
            parser.startParse()
        }
    }
    
    func XMLParserCs(didFinish dict:[String:[String : String]]) {
        
        let existedCs = existedCities
        let existedCsNames = existedCitiesNames(existedCs)
    
        let predicateToDelete = NSPredicate(format: "NOT SELF.name IN %@", [String](dict.keys))
        let predicateToInsert = NSPredicate(format: "NOT SELF IN %@", existedCsNames)
        
        let arraytoDelete = existedCs.filter({predicateToDelete.evaluateWithObject($0)})
        let arrayToInsert = [String](dict.keys).filter({predicateToInsert.evaluateWithObject($0)})
        
        print("\nto Delete: \(arraytoDelete.count)\nto Insert: \(arrayToInsert.count)\n")
        
        dispatch_async(dispatch_get_main_queue(), {
            
            // Delete
            
            if !arraytoDelete.isEmpty {
                for object in arraytoDelete {
                    self.managedObjectContext.deleteObject(object)
                }
            }
            
            // Insert
            
            if !arrayToInsert.isEmpty {
                let timeStamp = NSDate()
                for name in arrayToInsert {
                    let entity = NSEntityDescription.insertNewObjectForEntityForName("City", inManagedObjectContext: self.managedObjectContext) as! City
                    entity.timeStamp = timeStamp
                    entity.name = name
                    entity.country = dict[name]!["country"]
                    entity.id = dict[name]!["id"]
                }
            }
            
            print("XML is successfully loaded.")
            
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
    func loadCity (name: String) {
        
        currentApplication.networkActivityIndicatorVisible = true
        
        let parser = XMLParserCity(cityID: name)
        parser.delegate = self
        parser.startParse()
        
    }
    
    func XMLParserC(didFinish dict: [String : String]) {
        dispatch_async(dispatch_get_main_queue(), {
            
            print(dict)
            
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
}
