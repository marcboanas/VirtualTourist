//
//  Helper.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 30/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import Foundation
import UIKit

public class Helper {
    
    class func createAlert(errorMessage: String?, errorTitle: String? = "Error Message") -> UIAlertController {
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(defaultAction)
        return alert
    }
    
    class func removeActivityIndicator(uiView: UIView) {
        if let container = uiView.viewWithTag(99) {
            container.removeFromSuperview()
        }
    }
    
    class func showActivityIndicator(uiView: UIView) {
        
        // Activity Indicator
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        
        // Add Activity Indicator to Loading View
        uiView.addSubview(activityIndicator)
        
        // Constraints: Activity Indicator
        activityIndicator.centerYAnchor.constraint(equalTo: uiView.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: uiView.centerXAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        activityIndicator.startAnimating()
        
        // Bring Activity View to front
        uiView.bringSubview(toFront: activityIndicator)
    }
    
}
