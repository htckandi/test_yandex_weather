//
//  XMLParserCity.swift
//  test_yandex_weather
//
//  Created by Test on 9/26/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

protocol XMLParserCDelegate: NSObjectProtocol {
    func XMLParserC(didFinish dict: [String: String], city: City)
}

class XMLParserCity: NSObject, NSXMLParserDelegate {

    weak var delegate: XMLParserCDelegate?
    
    var isFact = false
    var tempCity: City!
    var tempDict: [String:String]?
    var tempCurrentType: String?
    
    func startParse () {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            if let parser = NSXMLParser(contentsOfURL: NSURL(string: "https://export.yandex.ru/weather-ng/forecasts/\(self.tempCity.id!).xml")!) {
                parser.delegate = self
                parser.parse()
            }
        })
    }
    
    init(city: City) {
        super.init()
        tempCity = city
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        tempDict = [String:String]()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {

        if elementName == "fact" {
            isFact = true
        }
        
        if isFact && (elementName == "temperature" || elementName == "weather_type") {
            tempCurrentType = elementName
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if let key = tempCurrentType {
            print(string)
            tempDict![key] = string
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "fact" {
            isFact = false
        }
        if tempCurrentType != nil {
            tempCurrentType = nil
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        print("Parser did end document.")
        if let dict = tempDict {
            self.delegate?.XMLParserC(didFinish: dict, city: tempCity)
        }
    }
    
}
