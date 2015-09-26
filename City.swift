//
//  City.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import Foundation
import CoreData

class City: NSManagedObject {
    
    @NSManaged var country: String?
    @NSManaged var id: String?
    @NSManaged var name: String?
    @NSManaged var weather: CityWeather?

// Insert code here to add functionality to your managed object subclass

}
