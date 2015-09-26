//
//  CityWeather.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import Foundation
import CoreData

class CityWeather: NSManagedObject {
    
    @NSManaged var temperature: String?
    @NSManaged var timeStamp: NSDate?
    @NSManaged var weatherType: String?
    @NSManaged var city: City?

// Insert code here to add functionality to your managed object subclass

}
