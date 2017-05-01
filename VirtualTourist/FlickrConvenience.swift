//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import UIKit

extension FlickrClient {
    
    func getPhotosByLatAndLong(latitude: Double, longitude: Double, pages: String?, completionHandlerForGetPhotosByLatAndLong: @escaping (_ photosDictionary: [String: AnyObject]?, _ errorString: String?) -> Void) {
        
        let parameters = [
            Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PhotosPerPage,
            Constants.FlickrParameterKeys.Page: randomPageNumber(pages)
        ] as [String: AnyObject]
        
        let method = Constants.FlickrParameterValues.SearchMethod
        
        let _ = taskForGetMethod(method, parameters: parameters) { (parsedData, errorString) in
            
            guard errorString == nil else {
                return completionHandlerForGetPhotosByLatAndLong(nil, errorString!)
            }
            
            guard let photosDictionary = parsedData?[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                return completionHandlerForGetPhotosByLatAndLong(nil, "The parsed data did not include a 'photos' key")
            }
            
            return completionHandlerForGetPhotosByLatAndLong(photosDictionary, nil)
        }
    }
    
    private func randomPageNumber(_ pages: String?) -> String {
        
        var pageNumber = "1"
        
        if let pages = (pages as AnyObject?) {
            let numberOfPages = min(pages.integerValue, 400)
            pageNumber = "\(Int(arc4random_uniform(UInt32(numberOfPages)) + 1))"
        }
        
        return pageNumber
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        let minLatitude = min(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let minLongitude = min(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLongRange.0)
        let maxLatitude = max(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        let maxLongitude = max(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLongRange.1)
        return "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
    }
}
