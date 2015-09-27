//
//  DetailViewController.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelTemperature: UILabel!
    @IBOutlet weak var labelWeather: UILabel!
    
    var dataManager = DataManager.sharedManager
    
    var city: City? {
        didSet {
            
            if let objectCity = city, let objectWeather = objectCity.weather {
                dataManager.weatherImageForType(Int(objectWeather.temperature!) > 0)
            }
            
            loadCity()
        }
    }
    
    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = city?.name
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "configureView", name: Defaults.dataManagerDiDUpdateDataNotification, object: nil)
        
        timer = Timer(duration: Defaults.duration, handler: { [unowned self] in self.loadCity()})
        timer.start()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        timer.stop()
        print("\nDetailViewController is deallocated.\n")
    }

    
    // MARK: - Convenience
    
    func loadCity () {
        if let object = city {
            dataManager.loadCity(object)
        }
    }
    
    func configureView () {
        if let object = city?.weather {
            
            let isHot = Int(object.temperature!) > 0
            let temperature = isHot ? "+" : ""
    
            labelTemperature.text = temperature + object.temperature!
            labelWeather.text = object.weatherType
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            if let object = dataManager.weatherImageForType (isHot) {
                imageView.image = UIImage(data: object.data!)
            }
        }
    }
    
}
