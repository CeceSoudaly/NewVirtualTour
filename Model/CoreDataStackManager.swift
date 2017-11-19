//
//  CoreDataStackManager.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 9/3/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//

import Foundation
import CoreData
import UIKit

private let SQLITE_FILE_NAME = "VirtualTourist.sqlite"

class CoreDataStackManager {
  
    // MARK: Properties
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: URL
    internal let dbURL: URL
    let context: NSManagedObjectContext
    
    //MARK:- SharedInstance
    class func sharedInstance()-> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager(modelName: "Model")
        }
        return Static.instance!
    }

   
    //MARK:- The Core Data Stack
    // Documents Directory URL - the path the sqlite file
    lazy var applicationDocumentsDirectory:NSURL? = {
        let urls = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        
        if urls.count > 0 {
            if let url = urls[urls.count-1] as? NSURL {
                return url
            }
        }
        return nil
        
        //return urls[urls.count-1] as! NSURL
    }()
    
    // The managed object property for the application
    lazy var managedObjectModel: NSManagedObjectModel? = {
        
        if  let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd") {
            if let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) {
                return managedObjectModel
            }
        }
        return nil
    }()
    
    lazy var pesistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        
        var coordinator: NSPersistentStoreCoordinator? = nil
        
        if let objectModel = self.managedObjectModel {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel )
            
            if let appURL = self.applicationDocumentsDirectory {
                
                let url = appURL.appendingPathComponent(SQLITE_FILE_NAME)
                
                var error:NSError? = nil
              
            }
        }
       
        return coordinator
    }()
   
    
    // MARK: Initializers
    
    init?(modelName: String) {
        
        // Assumes the model is in the main bundle
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // create a context and add connect it to the coordinator
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        
        // Add a SQLite store located in the documents folder
        let fm = FileManager.default
        
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to reach the documents folder")
            return nil
        }
        
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        
        // Options for migration
        let options = [NSInferMappingModelAutomaticallyOption: true,NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options as [NSObject : AnyObject]?)
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
    
    // MARK: Utils
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
 
    class func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    class func getContext() -> NSManagedObjectContext {
        return CoreDataStackManager.persistentContainer.viewContext
    }
    
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
}

