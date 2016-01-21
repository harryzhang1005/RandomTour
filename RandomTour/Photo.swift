//
//  Photo.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String?, imageName: String?, pin: Pin?)
    {
        let context = CoreDataStackManager.sharedInstance.managedObjectContext
        let entityDesc = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entityDesc!, insertIntoManagedObjectContext: context)
        
        self.imageURL = imageURL
        self.imageName = imageName
        self.pin = pin
        self.didFetchImageData = false
    }
    
}
