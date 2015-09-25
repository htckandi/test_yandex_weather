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

class DataManager: NSObject, NSXMLParserDelegate {
    
    static let sharedManager = DataManager()
    
    var appDelegate: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    var myQueue: dispatch_queue_t?
    
    var XMLParserCities: NSXMLParser?
    var XMLParserCity: NSXMLParser?

    var URLCities: NSURL? {
        return NSURL(string: "https://pogoda.yandex.ru/static/cities.xml")
    }
    
    var URLCity: (String) -> (NSURL?) = {
        return NSURL(string: "https://export.yandex.ru/weather-ng/forecasts/\($0).xml)")
    }
    
    var isDataValid: Bool {
        var tempVar = false
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")), let randomObject = fetchedObjects.first as? City where isTimeValid(randomObject.timeStamp!) {
            tempVar = true
        }
        return tempVar
    }
    
    var isTimeValid: (NSDate) -> (Bool) = {
        return Int($0.timeIntervalSinceDate(NSDate())/3600) < 1
    }
    
    var timer: NSTimer!
    
    var tempCities: [String:[String: String]]?
    var tempCurrentCityAttributes: [String: String]?
    var tempCurrentCityName: String?
    
    override init() {
        super.init()
        timer = NSTimer.scheduledTimerWithTimeInterval(3600, target: self, selector: "loadCities", userInfo: nil, repeats: true)
    }
    
    deinit {
        timer.invalidate()
    }
    
    func loadCities () {
        
        print(isDataValid)
        
        if !isDataValid {
            if XMLParserCities == nil {
                if let XMLurl = URLCities, let XMLParser = NSXMLParser(contentsOfURL: XMLurl) {
                    myQueue = dispatch_queue_create("myQueue", nil)
                    dispatch_async(myQueue!, {
                        self.XMLParserCities = XMLParser
                        self.XMLParserCities!.delegate = self
                        self.XMLParserCities!.parse()
                    })
                }
            }
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        tempCities = [String:[String: String]]()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "city" {
            tempCurrentCityAttributes = attributeDict
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if tempCurrentCityAttributes != nil {
            tempCurrentCityName = string
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "city", let cityName = tempCurrentCityName, let cityAttributes = tempCurrentCityAttributes {
            tempCities![cityName] = cityAttributes
        }
        tempCurrentCityName = nil
        tempCurrentCityAttributes = nil
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        
        if let cities = tempCities {
            dispatch_async(dispatch_get_main_queue(), {
                self.deleteAllCities()
                self.createNewCities(cities)
            });
        }
        
        tempCities = nil
        XMLParserCities = nil
        XMLParserCity = nil
        myQueue = nil
    }
    
    // MARK: - Convenience
    
    func deleteAllCities () {
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")) {
            for object in fetchedObjects as! [City] {
                managedObjectContext.deleteObject(object)
            }
        }
    }

    func createNewCities (cities: [String : [String : String]]) {
        
        let timeStamp = NSDate()
        
        for (cityName, cityAttributes) in cities {
            let entity = NSEntityDescription.insertNewObjectForEntityForName("City", inManagedObjectContext: managedObjectContext) as! City
            entity.timeStamp = timeStamp
            entity.name = cityName
            entity.country = cityAttributes["country"]
            entity.id = cityAttributes["id"]
        }
    }
}
