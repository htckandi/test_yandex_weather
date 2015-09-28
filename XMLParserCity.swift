//
//  XMLParserCity.swift
//  test_yandex_weather
//
//  Created by Test on 9/26/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

// Парсер для получения погоды

class XMLParserCity: NSObject, NSXMLParserDelegate {

    var handler: ([String:String], City) -> ()
    
    var isFact = false
    var tempCity: City!
    var tempDict: [String:String]?
    var tempCurrentType: String?
    
    init(city: City, handler: ([String:String], City) -> ()) {
        self.tempCity = city
        self.handler = handler
    }
    
    deinit {
        print("XMLParserCity is deallocated.")
    }
    
    func startParse () {
        
        // Работа парсера осуществляется в глобальном потоке с высоким приоритетом
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { 
            if let parser = NSXMLParser(contentsOfURL: NSURL(string: "https://export.yandex.ru/weather-ng/forecasts/\(self.tempCity.id!).xml")!) {
                parser.delegate = self
                if !parser.parse() {
                    parser.abortParsing()
                    
                    // Если парсинг завершился неудачно, это говорит о недоступности информации за пределами устройства. Оповещаем об этом датаменеджер
                    
                    NSNotificationCenter.defaultCenter().postNotificationName(Defaults.Notifications.dataManagerDataNotAccessible, object: "City")
                }
            }
        })
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(parser: NSXMLParser) {
        print("Parser did start document.")
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
            
            // Если данные по погоде успешно получены, передаем их в датаменеджер
            
            handler(dict,tempCity)
        }
    }
    
}
