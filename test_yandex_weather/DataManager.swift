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
    
    var timer: CancelableTimer!
    
    var timeStamp: TimeStamp? {
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "TimeStamp")), let object = fetchedObjects.first as? TimeStamp {
            return object
        }
        return nil
    }
    
    var isDataValid: Bool {
        if let object = timeStamp where isTimeValid(object.time!) {
            return true
        }
        return false
    }
    
    var isTimeValid: (NSDate) -> (Bool) = {
        return Int(NSDate().timeIntervalSinceDate($0)) < 30
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
        timer = CancelableTimer(once: false, handler: { self.loadCities() })
        timer.startWithInterval(3600)
    }
    
    deinit {
        timer.cancel()
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
        let predicateToUpdate = NSPredicate(format: "SELF.name IN %@", [String](dict.keys))
        let predicateToInsert = NSPredicate(format: "NOT SELF IN %@", existedCsNames)
        
        
        let arraytoDelete = existedCs.filter({predicateToDelete.evaluateWithObject($0)})
        let arrayToUpdate = existedCs.filter({predicateToUpdate.evaluateWithObject($0)})
        let arrayToInsert = [String](dict.keys).filter({predicateToInsert.evaluateWithObject($0)})
        
        print("\nto Delete: \(arraytoDelete.count)\nto Update: \(arrayToUpdate.count)\nto Insert: \(arrayToInsert.count)\n")
        
        dispatch_async(dispatch_get_main_queue(), {
            
            // Delete
            
            if !arraytoDelete.isEmpty {
                for object in arraytoDelete {
                    self.managedObjectContext.deleteObject(object)
                }
            }
            
            // Update
            
            if !arrayToUpdate.isEmpty {
                for object in arrayToUpdate {
                    if object.id != dict[object.name!]!["id"] {
                        object.id = dict[object.name!]!["id"]
                    }
                }
            }
            
            // Insert
            
            if !arrayToInsert.isEmpty {
                
                for name in arrayToInsert {
                    let entity = NSEntityDescription.insertNewObjectForEntityForName("City", inManagedObjectContext: self.managedObjectContext) as! City
                    entity.name = name
                    entity.country = dict[name]!["country"]
                    entity.id = dict[name]!["id"]
                }
            }
            
            // Update time stamp
            
            let stamp = self.timeStamp ?? NSEntityDescription.insertNewObjectForEntityForName("TimeStamp", inManagedObjectContext: self.managedObjectContext) as! TimeStamp
            stamp.time = NSDate()
            
            print("XML is successfully loaded.")
            
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
    
    
    
    func loadCity (city: City) {
        
        if city.weather == nil {
            
            print("Will load weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            
            let parser = XMLParserCity(city: city)
            parser.delegate = self
            parser.startParse()
        } else if !isTimeValid(city.weather!.timeStamp!) {
            
            print("Will update weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            
            let parser = XMLParserCity(city: city)
            parser.delegate = self
            parser.startParse()
        } else {
            print("The weather is actuale for city: \(city.name!)")
        }
    }
    
    func XMLParserC(didFinish dict: [String : String], city: City) {
        dispatch_async(dispatch_get_main_queue(), {
            
            let weather = city.weather ?? NSEntityDescription.insertNewObjectForEntityForName("CityWeather", inManagedObjectContext: self.managedObjectContext) as! CityWeather
            weather.temperature = dict["temperature"]
            weather.weatherType = dict["weather_type"]
            weather.timeStamp = NSDate()
            
            if weather.city == nil {
                weather.city = city
            }
            
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
}
