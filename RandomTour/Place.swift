//
//  Place.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import Foundation
import CoreData

class Place: NSManagedObject
{
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(placeName: String?, vicinity: String?, pin: Pin?, insertIntoManagedObjectContext context: NSManagedObjectContext)
    {
        let aEntity = NSEntityDescription.entityForName("Place", inManagedObjectContext: context)
        super.init(entity: aEntity!, insertIntoManagedObjectContext: context)
        
        self.name = placeName
        self.vicinity = vicinity
        self.pin = pin
    }

}
