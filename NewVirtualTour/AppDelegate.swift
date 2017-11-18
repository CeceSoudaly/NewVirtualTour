//
//  AppDelegate.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 8/27/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
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
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("saved sucessfully")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        else
        {
            print("no change is present")
        }
    }
    
    //MARK:- Core Data Error
    
    // Core data error is displayed here in Alert - This error is posted from CoreDataStackManager.swift
    
    // Notification to post and listen from AppDelegate
    
    let coreDataOperationDidFailNotification = "coreDataOperationDidFailNotification"
    
    //Call this function from CoreDataStackManager when error is there
    func fatalCoreDataError(error: NSError?) {
        
        if let fatalError = error {
            print("Fatal Core Data error: \(fatalError), \(fatalError.userInfo)")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: coreDataOperationDidFailNotification), object: error)
    }
    
    // Show alert by listening to Notification
    func showFatalCoreDataNotifications() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: coreDataOperationDidFailNotification), object: nil, queue: OperationQueue.main, using: {
            notification in
            
            let alert = UIAlertController(title: "Application Error",
                                          message: "There was a fatal error in the app. \n\n"
                                            + "Press OK to terminate the app. App cannot continue. We are sorry for this inconvenience.",
                                          preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default) { _ in
                
                // Terminate the app after message is displayed.
                abort()
            }
            
            alert.addAction(action)
            
            self.viewControllerForShowingAlert().present(alert, animated: true, completion: nil)
        })
    }
    
    // Show Alert view controller on any of the view controller which is currently displayed to the user.
    func viewControllerForShowingAlert() -> UIViewController {
        
        let rootViewController = self.window!.rootViewController!
        
        if let displayedViewController = rootViewController.presentedViewController {
            return displayedViewController
        } else {
            return rootViewController
        }
    }
    
}

