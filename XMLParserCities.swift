//
//  XMLParserCities.swift
//  test_yandex_weather
//
//  Created by Test on 9/25/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

class XMLParserCities: NSObject, NSXMLParserDelegate {
    
    var handler: ([String:[String: String]]) -> ()
    
    var tempCities: [String:[String: String]]?
    var tempCurrentCityAttributes: [String: String]?
    var tempCurrentCityName: String?
    
    init(handler: [String:[String: String]] -> ()) {
        self.handler = handler
    }
    
    deinit {
        print("XMLParserCities is deallocated.")
    }
    
    func startParse () {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            if let parser = NSXMLParser(contentsOfURL: NSURL(string: "https://pogoda.yandex.ru/static/cities.xml")!) {
                parser.delegate = self
                if !parser.parse() {
                    parser.abortParsing()
                    NSNotificationCenter.defaultCenter().postNotificationName(Defaults.dataManagerDataNotAccessible, object: "Cities")
                }
            }
        })
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        print("Parser did start document.")
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
        print("Parser did end document.")
        if let cities = tempCities {
            handler(cities)
        }
    }
    
}