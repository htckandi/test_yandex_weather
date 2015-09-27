//
//  DataManager.swift
//  test_yandex_weather
//
//  Created by Test on 9/25/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject  {
    
    static let sharedManager = DataManager()
    
    var currentApplication: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    var parserCities: XMLParserCities?
    
    var timer: Timer!
    
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
    
    var existedCities: [City] {
        var existed = [City]()
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")) as! [City] {
            existed.appendContentsOf(fetchedObjects)
        }
        return existed
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataUnavailable", name: Defaults.dataManagerDataUnavailable, object: nil)
        timer = Timer(duration: Defaults.duration, handler: { [unowned self] in self.loadCities() })
        timer.start()
    }
    
    func dataUnavailable () {
        print("\nData unavailable.\n")
        parserCities = nil
        currentApplication.networkActivityIndicatorVisible = false
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer.stop()
        print("DataManager is deallocated.")
    }
    
    func isTimeValid (date: NSDate) -> Bool {
        return NSDate().timeIntervalSinceDate(date) < (Defaults.duration - 1)
    }
    
    func existedCitiesNames (cities: [City]) -> [String] {
        var names = [String]()
        for object in cities {
            names.append(object.name!)
        }
        return names
    }
    
    func loadCities () {
        
        print("\nIs data valid: \(isDataValid)")
        
        if !isDataValid && parserCities == nil {
            currentApplication.networkActivityIndicatorVisible = true
            parserCities = XMLParserCities(handler: loadCitiesHandler)
            parserCities!.startParse()
        }
    }
    
    func loadCitiesHandler (dict: [String:[String:String]]) {
        
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
            
            self.parserCities = nil
            NSNotificationCenter.defaultCenter().postNotificationName(Defaults.dataManagerDiDUpdateDataNotification, object: nil)
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
    func loadCity (city: City) {
        
        if city.weather == nil {
            
            print("Will load weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            XMLParserCity(city: city, handler: loadCityHandler).startParse()

        } else if !isTimeValid(city.weather!.timeStamp!) {
            
            print("Will update weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            XMLParserCity(city: city, handler: loadCityHandler).startParse()
            
        } else {
            print("The weather is actuale for city: \(city.name!)")
        }
    }
    
    func loadCityHandler (dict: [String:String], city: City) {
        dispatch_async(dispatch_get_main_queue(), {
            
            let weather = city.weather ?? NSEntityDescription.insertNewObjectForEntityForName("CityWeather", inManagedObjectContext: self.managedObjectContext) as! CityWeather
            weather.temperature = dict["temperature"]
            weather.weatherType = dict["weather_type"]
            weather.timeStamp = NSDate()
            
            if weather.city == nil {
                weather.city = city
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(Defaults.dataManagerDiDUpdateDataNotification, object: nil)
            self.currentApplication.networkActivityIndicatorVisible = false
        });
    }
    
    // MARK: - Load images
    
    
    func weatherImageForType (type: Bool) -> WeatherImage? {
        if let object = weatherImageObjectForType(type) {
            
            print("Image exists.")
            
            return object
        } else {
            loadImages(type)
            return nil
        }
    }
    
    func weatherImageObjectForType (type: Bool) -> WeatherImage? {
        let fetchRequest = NSFetchRequest(entityName: "WeatherImage")
        fetchRequest.predicate = NSPredicate(format: "type == %@", type)
        if let object = try? managedObjectContext.executeFetchRequest(fetchRequest).first {
            return object as? WeatherImage
        }
        return nil
    }
    
    func loadImages (type: Bool) {
        
        print("Will load image.")
        
        currentApplication.networkActivityIndicatorVisible = true
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            let path = type ? Defaults.ImagesAddress.hot : Defaults.ImagesAddress.cold
            if let URL = NSURL(string: path), let data = NSData(contentsOfURL: URL) {
                if let loadedImage = UIImage(data: data) {
                    let resizedImage = loadedImage.imageByBestFitForSize(CGSize(width: 900, height: 900))
                    if let resizedData = UIImageJPEGRepresentation(resizedImage, 0.75) {
                        dispatch_async(dispatch_get_main_queue(), {
                            let entity = NSEntityDescription.insertNewObjectForEntityForName("WeatherImage", inManagedObjectContext: self.managedObjectContext) as! WeatherImage
                            entity.data = resizedData
                            entity.type = type
                            self.currentApplication.networkActivityIndicatorVisible = false
                            print("Images is created. Data length is \(data.length). Resized data length is \(resizedData.length)")
                            NSNotificationCenter.defaultCenter().postNotificationName(Defaults.dataManagerDiDUpdateDataNotification, object: nil)
                        });
                    }
                }
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(Defaults.dataManagerDataUnavailable, object: "Image")
            }
        })
    }
    
}
