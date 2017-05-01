//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    // MARK: Initializer
    
    convenience init(longitude: Double, latitude: Double, pages: String? = nil, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.longitude = longitude
            self.latitude = latitude
            self.pages = pages
            self.isDownloading = true
            self.creationDate = Date()
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
