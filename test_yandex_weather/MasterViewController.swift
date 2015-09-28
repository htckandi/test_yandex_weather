//
//  MasterViewController.swift
//  test_yandex_weather
//
//  Created by Test on 9/24/15.
//  Copyright © 2015 Test. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var headerView: UILabel!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    // Создаём синглтон датаменеджера
    
    var dataManager = DataManager.sharedManager

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Добавляем обзор уведомления от датаменеджера о необходимости обновления интерфейса пользователя
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "configureHeader", name: Defaults.Notifications.dataManagerInterfaceNeedsUpdate, object: nil)
        
        // Отправная точка всего приложения. Первичный запрос на загрузку списка городов
        
        dataManager.loadCities()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - IB Actions
    
    @IBAction func refreshCities(sender: AnyObject) {
        
        // Добавляем возможность принудительного обновления списка городов с помощью кнопки Refresh в случае, если информация более не актуальна и ранее отсутствовал доступ к данным
        
        dataManager.loadCities()
    }
    
    
    // MARK: - Update interface
    
    func configureHeader () {
        
        // Формируем информационное сообщение для пользователя, отображаемое вверху списка городов
        
        var stringValid: String
        
        if fetchedResultsController.fetchedObjects?.count > 0 {
            
            if dataManager.isDataValid {
                stringValid = "Data valid."
                refreshButton.enabled = false
            } else {
                stringValid = "Data not valid."
            }
            
        } else {
            stringValid = "No data"
        }
        
        var stringAccessible: String?
        
        if !dataManager.isDataAccessible {
            stringAccessible = "\nNo data access."
            refreshButton.enabled = true
        }
        
        var headerString = stringValid
        
        if let string = stringAccessible {
            headerString += string
        }
        
        headerView.text = headerString
    }
    
    
    // MARK: - Segues
    
    // Передача данных о выбранном городе на экран отображения погоды
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destinationViewController as! DetailViewController
                controller.city = fetchedResultsController.objectAtIndexPath(indexPath) as? City
            }
        }
    }

    
    // MARK: - Table view data source
    
    // Работа с основной таблицей

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        configureHeader()
        
        // Определяем количество стран
        
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        // Определяем название каждой страны
        
        return fetchedResultsController.sections?[section].name
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Определяем количество городов в каждой стране
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("masterCell", forIndexPath: indexPath)
        
        // Отображаем название города в соответствии с полученным индексом объекта в базе данных
        
        cell.textLabel?.text = (fetchedResultsController.objectAtIndexPath(indexPath) as! City).name
        return cell
    }
    
    
    // MARK: - Fetched results controller
    
    // Формирование контроллера для работы с SQLite и таблицей списка городов
    // Данный контроллер работает только с этим экраном
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // Контроллер работает только с объектами городов
        
        let fetchRequest = NSFetchRequest(entityName: "City")
        fetchRequest.fetchBatchSize = 20
        
        // Список городов сортируется в алфавитном порядке как по странам, так и по городам
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "country", ascending: true), NSSortDescriptor(key: "name", ascending: true) ]
        
        // Список городов группируется по названию стран
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataManager.managedObjectContext, sectionNameKeyPath:"country", cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            print("Unresolved error \(error)")
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    // Действия контроллера для синхронизации изменений в базе данных и таблице
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

}
