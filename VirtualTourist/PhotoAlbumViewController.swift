//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

private let reuseIdentifier = "PhotoCell"

class PhotoAlbumViewController: CoreDataCollectionViewController {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var deleteSelectedPhotosButton: UIBarButtonItem!
    
    // MARK: Properties
    
    var pin: Pin!
    
    var newCollectionButton: UIButton!
    
    var mapView: MKMapView!
    
    var selectedPhotos: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.allowsMultipleSelection = true
        setupLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(photosDidFinishDownloading(_:)), name: Notification.Name(rawValue: "photosDidFinishDownloadingNotification"), object: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var numberOfItems = 0
        
        if let fc = fetchedResultsController {
            numberOfItems = fc.sections![section].numberOfObjects
        } else {
            numberOfItems = 0
        }
        
        setupBackgroundView()
        
        return numberOfItems
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomPhotoCell
        
        cell.backgroundColor = UIColor.black
        
        if let photoData = photo.imageData {
            let photoImage = UIImage(data: photoData as Data)
            cell.imageView.image = photoImage
            cell.imageView.contentMode = UIViewContentMode.scaleAspectFit
            Helper.removeActivityIndicator(uiView: cell)
        } else {
            cell.imageView.image = nil
            Helper.showActivityIndicator(uiView: cell)
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoAlbumHeader", for: indexPath) as! CustomPhotoAlbumHeader
            
            mapView = header.mapView
            
            setupMapView()
            
            return header
            
        case UICollectionElementKindSectionFooter:
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "PhotoAlbumFooter", for: indexPath) as! CustomPhotoAlbumFooter
            
            newCollectionButton = footer.newCollectionButton
            
            newCollectionButton.setTitle("Loading", for: .disabled)
            
            newCollectionButton.isEnabled = CoreDataManager.sharedInstace().downloadCompleteForPin(pin: pin)
            
            return footer
            
        default:
            
            assert(false, "Unexpected element kind")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let photo = fetchedResultsController?.object(at: indexPath) as? Photo {
            selectedPhotos.append(photo)
        }
        deleteSelectedPhotosButton.isEnabled = selectedPhotos.count > 0 ? true : false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let photo = fetchedResultsController?.object(at: indexPath) as? Photo {
            selectedPhotos.remove(at: selectedPhotos.index(of: photo)!)
        }
        deleteSelectedPhotosButton.isEnabled = selectedPhotos.count > 0 ? true : false
    }
    
    @IBAction func deleteSelectedPhotos(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        CoreDataManager.sharedInstace().deletePhotos(selectedPhotos)
        selectedPhotos.removeAll()
    }
    
    @IBAction func newCollectionButtonPressed(_ sender: UIButton) {
        
        // GUARD: Is an internet connection available?
        guard Reachability.isConnectedToNetwork() == true else {
            let alert = Helper.createAlert(errorMessage: "No internet connection available!", errorTitle: "Connection Error")
            present(alert, animated: true, completion: nil)
            return
        }
        
        sender.isEnabled = false
        CoreDataManager.sharedInstace().newCollectionOfPhotos(pin: pin)
    }
    
}

extension PhotoAlbumViewController {
    
    func setupLayout() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func photosDidFinishDownloading(_ notification: Notification) {
        
        guard (notification.userInfo?["pin"] as! Pin == pin) else {
            return
        }

        DispatchQueue.main.async {
            if let newCollectionButton = self.newCollectionButton {
                newCollectionButton.isEnabled = !self.pin.isDownloading
                self.setupBackgroundView()
            }
        }
    }
    
    func setupMapView() {
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude , longitude: pin.longitude )
        let span = MKCoordinateSpanMake(0.075, 0.075)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        let annotation = CustomAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    func setupBackgroundView() {
        if pin.photos?.count == 0 && !pin.isDownloading {
            let noPhotosLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height))
            noPhotosLabel.text = "No photos to display!"
            noPhotosLabel.textColor = UIColor.black
            noPhotosLabel.textAlignment = .center
            collectionView?.backgroundView = noPhotosLabel
        } else {
            collectionView?.backgroundView = nil
        }
    }
}
