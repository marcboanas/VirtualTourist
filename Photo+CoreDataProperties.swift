//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var url: String
    @NSManaged public var imageData: Data?
    @NSManaged public var pin: Pin

}
