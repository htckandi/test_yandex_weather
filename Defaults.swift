//
//  Defaults.swift
//  test_yandex_weather
//
//  Created by Test on 9/26/15.
//  Copyright © 2015 Test. All rights reserved.
//

import Foundation

// Константы заданные пользователем

struct Defaults {
    
    // В задании требуется установить интервал в 1 час, в приложении установлено 5 минут для наглядности происходящего процесса
    
    static let duration = NSTimeInterval(300)
    
    struct ImagesAddress {
        static let cold = "https://hikingartist.files.wordpress.com/2012/05/1-christmas-tree.jpg"
        static let hot = "http://www.rewalls.com/images/201201/reWalls.com_59293.jpg"
    }
    
    struct Notifications {
        static let dataManagerDataNotAccessible = "dataManagerDataNotAccessible"
        static let dataManagerInterfaceNeedsUpdate = "dataManagerInterfaceNeedsUpdate"
    }
}