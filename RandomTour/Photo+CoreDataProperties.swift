//
//  Photo+CoreDataProperties.swift
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

extension Photo {

    @NSManaged var imageURL: String?            // The photo URL link in Flickr
    @NSManaged var imageName: String?           // The photo name
    @NSManaged var didFetchImageData: Bool      // The image has been downloaded or not
    @NSManaged var pin: Pin?                    // The photo belongs to which pin ?

}
