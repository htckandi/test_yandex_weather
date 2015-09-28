//
//  DataManager.swift
//  test_yandex_weather
//
//  Created by Test on 9/25/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import CoreData

class DataManager: NSObject  {
    
    static let sharedManager = DataManager()
    
    // Полаем синглтон экзепляра приложения
    
    var currentApplication: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    // Получаем контекст для работы с базой данных
    
    var managedObjectContext: NSManagedObjectContext {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }
    
    // Переменная XML парсера для списка городов. Нужна для того, чтобы не создавать несколько одновременных запросов к Яндексу по списку городов
    
    var parserCities: XMLParserCities?
    
    // Переменная таймера обновления информации
    
    var timer: Timer!
    
    // Проверка на предмет наличия отметки о времени получения последнего списка городов
    
    var timeStamp: TimeStamp? {
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "TimeStamp")) {
            return fetchedObjects.first as? TimeStamp
        }
        return nil
    }
    
    // Проверка на предмет актуальности информации списка городов в соответствии с заданным интервалом времени
    
    var isDataValid: Bool {
        if let object = timeStamp where isTimeValid(object.time!) {
            return true
        }
        return false
    }
    
    // Получаем массив городов, существующих в базе данных
    
    var existedCities: [City] {
        var existed = [City]()
        if let fetchedObjects = try? managedObjectContext.executeFetchRequest(NSFetchRequest(entityName: "City")) as! [City] {
            existed.appendContentsOf(fetchedObjects)
        }
        return existed
    }
    
    // Переменная, хранящая информацию о доступности данных  Интернете
    
    var isDataAccessible = true
    
    override init() {
        super.init()
        
        // Добавляем обзор уведомления о недоступности данных в Интернете. Данное уведомлени может приходить из параллельного потока
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataNotAccessible:", name: Defaults.Notifications.dataManagerDataNotAccessible, object: nil)
        
        // Создаем таймер обновления информации в соответствии с заданным интервалом времени
        
        timer = Timer(duration: Defaults.duration, handler: { [unowned self] in self.loadCities() })
        timer.start()
    }

    deinit {
        
        // Удаляем все, добавленные ранее, обозы уведомлений
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        // Останавливаем таймер для того, чтобы датаменеджер мог быть деинициализирован ARC
        
        timer.stop()
        print("DataManager is deallocated.")
    }
    
    
    // MARK: - Data access
    
    // Необходимые действия приложения в случае недоступности данных в Интернете
    
    func dataNotAccessible (notification: NSNotification) {
        
        // Действия осуществляем в главном потоке, поскольку данная функция может быть вызвана из параллельного потока
        
        dispatch_async(dispatch_get_main_queue(), {
            print("\nData not accessible.\n")
            
            // Обнуляем парсер городов
            self.parserCities = nil
            
            // Останавливаем круговой прогресс
            
            self.currentApplication.networkActivityIndicatorVisible = false
            
            // Записываем в соответствующую переменную информацию о доступности данных в Интернете
            
            self.isDataAccessible = false
            
            // Уведомляем все объекты о необходимости обновления интерфейса
            
            if let object = notification.object as? String {
                NSNotificationCenter.defaultCenter().postNotificationName(Defaults.Notifications.dataManagerInterfaceNeedsUpdate, object: object)
            }
        })
    }
    
    // Дествия, осуществялемы в случае успешной загрузки данных из Интернета
    
    func dataAccessible (type: String) {
        self.currentApplication.networkActivityIndicatorVisible = false
        self.isDataAccessible = true
        NSNotificationCenter.defaultCenter().postNotificationName(Defaults.Notifications.dataManagerInterfaceNeedsUpdate, object: type)
    }
    
    
    // MARK: - Convenience
    
    // Проверяем соответствие прошедшего временного интервала заданному
    
    func isTimeValid (date: NSDate) -> Bool {
        return NSDate().timeIntervalSinceDate(date) < (Defaults.duration - 1)
    }
    
    // Получаем список имён существующих городов
    
    func existedCitiesNames (cities: [City]) -> [String] {
        var names = [String]()
        for object in cities {
            names.append(object.name!)
        }
        return names
    }
    
    
    // MARK: - Load Cities
    
    // Загружаем список городов
    
    func loadCities () {
        print("\nIs data valid: \(isDataValid)")
        
        // Процесс загрузки начинается в случае, если существующая информация не актуальна и нет уже действующего процесса загрузки списка городов
        
        if !isDataValid && parserCities == nil {
            
            // Запускаем круговой прогресс
            
            currentApplication.networkActivityIndicatorVisible = true
            
            // Создаем парсер городов
            
            parserCities = XMLParserCities(handler: loadCitiesHandler)
            
            // Запускаем парсер городов
            
            parserCities!.startParse()
        }
    }
    
    // Обрабатываем полученные данные по списку городов. Эта функция вызывается из параллельного потока. Это ОЧЕНЬ важно.
    
    func loadCitiesHandler (dict: [String:[String:String]]) {
        
        // Создаем предикаты и фильтруем информацию на предмет того, что удалить, что добавить, а что обновить
        
        let existedCs = existedCities
        let existedCsNames = existedCitiesNames(existedCs)
        
        let predicateToDelete = NSPredicate(format: "NOT SELF.name IN %@", [String](dict.keys))
        let predicateToUpdate = NSPredicate(format: "SELF.name IN %@", [String](dict.keys))
        let predicateToInsert = NSPredicate(format: "NOT SELF IN %@", existedCsNames)
        
        let arraytoDelete = existedCs.filter({predicateToDelete.evaluateWithObject($0)})
        let arrayToUpdate = existedCs.filter({predicateToUpdate.evaluateWithObject($0)})
        let arrayToInsert = [String](dict.keys).filter({predicateToInsert.evaluateWithObject($0)})
        
        print("\nto Delete: \(arraytoDelete.count)\nto Update: \(arrayToUpdate.count)\nto Insert: \(arrayToInsert.count)\n")
        
        // Все действия в базе данных осуществляем в основном потоке, что корректно работал контроллер на экране отображения списка городов
        
        dispatch_async(dispatch_get_main_queue(), {
            
            // Delete
            
            if !arraytoDelete.isEmpty {
                for object in arraytoDelete {
                    self.managedObjectContext.deleteObject(object)
                }
            }
            
            // Update
            
            if !arrayToUpdate.isEmpty {
                for object in arrayToUpdate {
                    if object.id != dict[object.name!]!["id"] {
                        object.id = dict[object.name!]!["id"]
                    }
                }
            }
            
            // Insert
            
            if !arrayToInsert.isEmpty {
                for name in arrayToInsert {
                    let entity = NSEntityDescription.insertNewObjectForEntityForName("City", inManagedObjectContext: self.managedObjectContext) as! City
                    entity.name = name
                    entity.country = dict[name]!["country"]
                    entity.id = dict[name]!["id"]
                }
            }
            
            // Update time stamp
            
            let stamp = self.timeStamp ?? NSEntityDescription.insertNewObjectForEntityForName("TimeStamp", inManagedObjectContext: self.managedObjectContext) as! TimeStamp
            stamp.time = NSDate()
            
            print("XML is successfully loaded.")
            
            self.parserCities = nil
            
            // Сообщаем о том, что объекты городов успешно получены
            
            self.dataAccessible("Cities")
        });
    }
    
    
    // MARK: - Load City
    
    // Загружаем погоду по конкретному городу
    
    func loadCity (city: City) {
        
        if city.weather == nil {
            print("Will load weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            XMLParserCity(city: city, handler: loadCityHandler).startParse()

        } else if !isTimeValid(city.weather!.timeStamp!) {
            print("Will update weather for city: \(city.name!)")
            
            currentApplication.networkActivityIndicatorVisible = true
            XMLParserCity(city: city, handler: loadCityHandler).startParse()
            
        } else {
            print("The weather is actuale for city: \(city.name!)")
        }
    }
    
    // Обрабатываем полученную информацию о погоде. Эта функция вызывается из параллельного потока
    
    func loadCityHandler (dict: [String:String], city: City) {
        
        // Все действия осуществляем в основном потоке
        
        dispatch_async(dispatch_get_main_queue(), {
            
            // Получаем существующий объект погоды или создаем его, в случае отсутствия в базе данных
    
            let weather = city.weather ?? NSEntityDescription.insertNewObjectForEntityForName("CityWeather", inManagedObjectContext: self.managedObjectContext) as! CityWeather
            
            // Записываем актуальную информацию о погоде
            
            weather.temperature = dict["temperature"]
            weather.weatherType = dict["weather_type"]
            weather.timeStamp = NSDate()
            
            // Указываем, какому городу соответствует погода
            
            if weather.city == nil {
                weather.city = city
            }
            
            // Сообщаем о том, что объект погоды успешно получен
            
            self.dataAccessible("City")
        });
    }
    
    
    // MARK: - Load images
    
    // Загружаем изображение погоды, в случае, если оно отсутствует в базе данных
    
    func weatherImageForType (type: Bool) -> WeatherImage? {
        if let object = weatherImageObjectForType(type) {
            print("Image exists.")
            return object
        } else {
            loadImages(type)
            return nil
        }
    }
    
    // Проверка наличия изображения в базе данных
    
    func weatherImageObjectForType (type: Bool) -> WeatherImage? {
        let fetchRequest = NSFetchRequest(entityName: "WeatherImage")
        fetchRequest.predicate = NSPredicate(format: "type == %@", type)
        if let object = try? managedObjectContext.executeFetchRequest(fetchRequest).first {
            return object as? WeatherImage
        }
        return nil
    }
    
    // Функция загрузки изображения
    
    func loadImages (type: Bool) {
        print("Will load image.")
        currentApplication.networkActivityIndicatorVisible = true
        
        // Основной процесс загрузки осуществдяем в параллеьном потоке, чтобы не вызвать задержку интерфейса пользователя
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            
            let path = type ? Defaults.ImagesAddress.hot : Defaults.ImagesAddress.cold
            
            if let URL = NSURL(string: path), let data = NSData(contentsOfURL: URL) {
                if let loadedImage = UIImage(data: data) {
                    
                    // В случае, если изображение получено, изменяем его размер до 900х900 с уменьшением коэффициента сжатия JPG (в целях уменьшения размера файла)
                    
                    let resizedImage = loadedImage.imageByBestFitForSize(CGSize(width: 900, height: 900))
                    
                    if let resizedData = UIImageJPEGRepresentation(resizedImage, 0.75) {
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            // Создаем объект изображения в базе данных
                            
                            let entity = NSEntityDescription.insertNewObjectForEntityForName("WeatherImage", inManagedObjectContext: self.managedObjectContext) as! WeatherImage
                            entity.data = resizedData
                            entity.type = type
                            
                            print("Image is created. Data length is \(data.length). Resized data length is \(resizedData.length)")
                            self.dataAccessible("Image")
                        });
                    }
                }
            } else {
                
                // Если файл из Интернета не получен, сообщаем об этом датаменеджеру
                
                NSNotificationCenter.defaultCenter().postNotificationName(Defaults.Notifications.dataManagerDataNotAccessible, object: "Image")
            }
        })
    }

}
