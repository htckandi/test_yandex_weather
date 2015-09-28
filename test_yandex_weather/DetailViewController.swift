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
    
    // Получаем синглтон датаменеджера
    
    var dataManager = DataManager.sharedManager
    
    var city: City? {
        didSet {
            
            // Поскольку город для данного экрана будет получен раньше, чем отобразится сам экран, осуществляем загрузку погоды и изображения как можно раньше
            
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
        
        // Добавляем обзор уведомления от датаменеджера о необходимости обновления интерфейса пользователя
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "configureView", name: Defaults.Notifications.dataManagerInterfaceNeedsUpdate, object: nil)
        
        // Создаем таймер для обновления информации в соответствии с заданным интервалом времени. Вот этот элемент кода: [unowned self] имеет первостепенное значение для работы ARC с таймером
        
        timer = Timer(duration: Defaults.duration, handler: { [unowned self] in self.loadCity()})
        timer.start()
        
        // Первичное формирование информации на экране
        
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        
        // Удаляем все, добавленные ранее, обозы уведомлений
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        // Останавливаем таймер для того, чтобы этот экран мог быть деинициализирован ARC
        
        timer.stop()
        print("\nDetailViewController is deallocated.\n")
    }

    
    // MARK: - Convenience
    
    // Загружаем погоду в том случае, если поступила информация о городе
    
    func loadCity () {
        if let object = city {
            dataManager.loadCity(object)
        }
    }
    
    // Формируем экран отображения погоды. Отображается либо информация о погоде, либо информация об отсутствии данных
    
    func configureView () {
        if let object = city?.weather {
            
            imageView.hidden = false
            
            let isHot = Int(object.temperature!) > 0
            let temperature = isHot ? "+" : ""
    
            labelTemperature.text = temperature + object.temperature!
            labelWeather.text = object.weatherType
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            if let object = dataManager.weatherImageForType (isHot) {
                imageView.image = UIImage(data: object.data!)
            }
        } else {
            imageView.hidden = true
        }
    }
    
}
