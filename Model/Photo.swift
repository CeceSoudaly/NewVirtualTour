//
//  Photo+CoreDataClass.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 10/28/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    // Core data object attributes
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var downloadStatus: Bool
    @NSManaged public var location: Location?
    @NSManaged public var pageNumber: NSNumber?
    @NSManaged public var imageData: NSData?
    
    // Keys to convert dictionary into object
    struct Keys {
        static let Id = "id"
        static let Name = "title"
        static let ImageUrl = "url_m"
        static let DownloadStatus = "downloadStatus"
        static let PageNumber = "pageNumber"
    }
    
    // Init method to insert object in core data
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    
    convenience init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            
            if(dictionary[Keys.Id] != nil ){
                self.id = dictionary[Keys.Id] as! String
            }
            
            if(dictionary[Keys.Name]  != nil ){
                self.title = dictionary[Keys.Name] as! String
            }
            
            if(dictionary[Keys.ImageUrl]  != nil ){
                self.imageUrl = dictionary[Keys.ImageUrl] as! String
            }
            
            if(dictionary[Keys.PageNumber]  != nil ){
                self.pageNumber = dictionary[Keys.PageNumber] as! NSNumber
            }
            
            self.downloadStatus = false
            
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
}

