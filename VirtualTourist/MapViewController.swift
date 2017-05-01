//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: Properties
    
    let stack = CoreDataManager.sharedInstace().stack
    var annotations = [CustomAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAddAnnotation))
        
        longPressRecognizer.minimumPressDuration = 1.2
        
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    func setupMap() {
        if let mapLocation = UserDefaults.standard.dictionary(forKey: "mapLocation") {
            let coordinates = CLLocationCoordinate2D(latitude: mapLocation["latitude"] as! CLLocationDegrees, longitude: mapLocation["longitude"] as! CLLocationDegrees)
            let span = MKCoordinateSpanMake(mapLocation["deltaLatitude"] as! CLLocationDegrees, mapLocation["deltaLongitude"] as! CLLocationDegrees)
            let region = MKCoordinateRegion(center: coordinates, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        let pins = CoreDataManager.sharedInstace().allPins
        
        for pin in pins {
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = CustomAnnotation()
            annotation.pin = pin
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }

    func longPressAddAnnotation(gestureRecognizer: UIGestureRecognizer) {
        
        guard gestureRecognizer.state == .began else {
            return
        }
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = CustomAnnotation()
        annotation.coordinate = newCoordinates
        
        mapView.addAnnotation(annotation)
        
        // GUARD: Is an internet connection available?
        guard Reachability.isConnectedToNetwork() == true else {
            let alert = Helper.createAlert(errorMessage: "No internet connection available!", errorTitle: "Connection Error")
            present(alert, animated: true, completion: {
                self.mapView.removeAnnotation(annotation)
            })
            return
        }
        
        CoreDataManager.sharedInstace().addPin(coordinate: newCoordinates, annotation: annotation) { (success, errorString) in
            if let error = errorString {
                let alert = Helper.createAlert(errorMessage: "\(error)")
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = false
            pinView?.animatesDrop = true
            pinView?.isDraggable = false
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let pin = (view.annotation as! CustomAnnotation).pin {
            
            let nextController = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                        let pred = NSPredicate(format: "pin = %@", argumentArray: [pin])
            fr.predicate = pred
            fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            
            nextController.pin = pin
            nextController.fetchedResultsController = fc
            
            // Change the back button text as 'Virtual tourist' was too long
            let newBackButton = UIBarButtonItem(title: "Map", style: .plain, target: nil, action: nil)
            navigationItem.backBarButtonItem = newBackButton
            
            self.navigationController?.pushViewController(nextController, animated: true)
            
        } else {
            print("Error: No pin could be found!")
        }
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        let locationData = ["latitude": center.latitude, "longitude": center.longitude, "deltaLatitude": span.latitudeDelta, "deltaLongitude": span.longitudeDelta]
        UserDefaults.standard.set(locationData, forKey: "mapLocation")
        UserDefaults.standard.synchronize()
    }
}
