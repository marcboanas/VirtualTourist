//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(url: String, imageData: Data? = nil, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.imageData = imageData
            self.creationDate = Date()
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
