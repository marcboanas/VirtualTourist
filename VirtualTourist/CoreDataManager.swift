//
//  CoreDataManager.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 30/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import MapKit
import CoreData

class CoreDataManager: NSObject {
    
    // MARK: Properties
    
    let stack = CoreDataStack(modelName: "Model")!
    var allPins = [Pin]()
    
    override init() {
        super.init()
        
        // All pins are retreived from core data
        getAllPins()
        
        // If the app is closed and interupts the download of photos.
        resumeInteruptedDownloads()
    }
    
    func addPin(coordinate: CLLocationCoordinate2D, annotation: CustomAnnotation, pages: String? = nil, completionHandlerForAddPin: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        let pin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, pages: pages, context: stack.context)
        
        allPins.append(pin)
        
        annotation.pin = pin
        
        loadPhotosFromFlickr(pin: pin)
        
        saveModel()
        
        return completionHandlerForAddPin(true, nil)
    }
    
    func loadPhotosFromFlickr(pin: Pin) {
        
        FlickrClient.sharedInstace().getPhotosByLatAndLong(latitude: pin.latitude, longitude: pin.longitude, pages: pin.pages) { (photoDictionary, errorString) in
            
            guard errorString == nil else {
                print(errorString!)
                return
            }
            
            guard let photoDictionary = photoDictionary else {
                print("No photo dictionary returned from Flickr")
                return
            }
            
            // 1: Add photos to core data before downloading images
            self.addPhotosForPin(photosDictionary: photoDictionary, pin: pin)
            
            // 2: Download photo data and add to core data
            self.downloadPhotosForPin(pin: pin)
        }
    }
    
    private func addPhotosForPin(photosDictionary: [String: AnyObject], pin: Pin) {

        stack.context.perform({
            if let pages = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Pages] {
                pin.pages = "\(pages)"
                self.saveModel()
            }
        })
        
        let photoArray = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as! [[String: AnyObject]]
        
        for photo in photoArray {
            let url = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL]
            stack.context.performAndWait{() -> Void in
                let photo = Photo(url: url as! String, context: self.stack.context)
                photo.pin = pin
                self.saveModel()
            }
        }
    }
    
    private func downloadPhotosForPin(pin: Pin) {
        
        
        // Fetch and order the pin photos by creation date
        // This allows the photos to load in order when displayed on the photo album controller
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
        fr.predicate = pred
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch {
            print("Error fetching photos")
        }
        
        for photo in fc.fetchedObjects! {
            let p = photo as! Photo
            
            stack.context.performAndWait({
                if p.imageData == nil {
                    
                    let url = URL(string: p.url)
                    if let photoData = try? Data(contentsOf: url!) {
                        p.imageData = photoData
                    }
                    
                }
                
                self.saveModel()
            })
            
        }
        
        stack.context.performAndWait {
            pin.isDownloading = false
            self.saveModel()
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: "photosDidFinishDownloadingNotification"), object: nil, userInfo: ["pin": pin])
    }
    
    private func getAllPins() {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            allPins = try stack.context.fetch(request) as! [Pin]
        } catch {
            print("Error fetching core data")
        }
    }
    
    private func resumeInteruptedDownloads() {
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let pred = NSPredicate(format: "ANY photos.imageData = nil")
        fr.predicate = pred
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()

            for pin in fc.fetchedObjects! {
                downloadPhotosForPin(pin: pin as! Pin)
            }
        } catch {
            print("Error fetching core data")
        }
        
    }
    
    func downloadCompleteForPin(pin: Pin) -> Bool {
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let pred = NSPredicate(format: "imageData = nil && pin = %@", argumentArray: [pin])
        fr.predicate = pred
        do {
           let photoCount = try stack.context.count(for: fr)
            if photoCount > 0 {
                return false
            } else {
                return true
            }
        } catch {
            print("Error fetching data")
        }
        
        return false
    }
    
    func newCollectionOfPhotos(pin: Pin) {
        
        pin.isDownloading = true
        
        for photo in pin.photos! {
            stack.context.delete(photo as! NSManagedObject)
        }
        
        saveModel()
        
        loadPhotosFromFlickr(pin: pin)
    }
    
    func deletePhotos(_ photos: [Photo]) {
        for photo in photos {
            stack.context.delete(photo)
        }
        
        saveModel()
    }
    
    // MARK: Shared Instance
    
    class func sharedInstace() -> CoreDataManager {
        struct Singleton {
            static var sharedInstance = CoreDataManager()
        }
        return Singleton.sharedInstance
    }
    
    private func saveModel() {
        do {
            try stack.saveContext()
        } catch {
            print("Error while saving")
        }
    }
}
