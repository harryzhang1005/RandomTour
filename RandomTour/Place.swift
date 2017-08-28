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
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(placeName: String?, vicinity: String?, pin: Pin?, insertIntoManagedObjectContext context: NSManagedObjectContext)
    {
        let aEntity = NSEntityDescription.entity(forEntityName: "Place", in: context)
        super.init(entity: aEntity!, insertInto: context)
        
        self.name = placeName
        self.vicinity = vicinity
        self.pin = pin
    }

}
