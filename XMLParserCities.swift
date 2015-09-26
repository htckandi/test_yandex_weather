//
//  XMLParserCities.swift
//  test_yandex_weather
//
//  Created by Test on 9/25/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import Foundation

protocol XMLParserCsDelegate: NSObjectProtocol {
    func XMLParserCs(didFinish dict: [String: [String: String]])
}

class XMLParserCities: NSObject, NSXMLParserDelegate {
    
    weak var delegate: XMLParserCsDelegate?
    
    var tempCities: [String:[String: String]]?
    var tempCurrentCityAttributes: [String: String]?
    var tempCurrentCityName: String?
    
    func startParse () {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            if let parser = NSXMLParser(contentsOfURL: NSURL(string: "https://pogoda.yandex.ru/static/cities.xml")!) {
                parser.delegate = self
                parser.parse()
            }
        })
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
        print("Parser did end document.")
        if let cities = tempCities {
            self.delegate?.XMLParserCs(didFinish: cities)
        }
    }
    
}
