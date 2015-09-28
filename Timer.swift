//
//  Timer.swift
//  test_yandex_weather
//
//  Created by Test on 9/26/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit

// Отдельный класс таймера. Создан для того, чтобы ARC мог деинициализировать его и объект, которому он принадлежит

class Timer: NSObject {
    
    var timer = NSTimer()
    var duration: NSTimeInterval
    var handler: () -> ()
    
    init(duration: NSTimeInterval, handler: () -> ()) {
        self.duration = duration
        self.handler = handler
    }
    
    func start () {
        timer = NSTimer.scheduledTimerWithTimeInterval(duration, target: self, selector: "performHandler", userInfo: nil, repeats: true)
    }
    
    func performHandler () {
        handler()
    }
    
    func stop () {
        timer.invalidate()
    }
    
    deinit {
        timer.invalidate()
        print("\nTimer is deallocated.\n")
    }
    
}