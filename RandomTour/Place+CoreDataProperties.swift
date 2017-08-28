//
//  Place+CoreDataProperties.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Place {

    @NSManaged var name: String?        // The place name
    @NSManaged var vicinity: String?    // The neighbours of place
    @NSManaged var pin: Pin?            // Which pin does the place belong to?

}
