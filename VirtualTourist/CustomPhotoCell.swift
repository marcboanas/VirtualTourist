//
//  CustomPhotoCell.swift
//  VirtualTourist
//
//  Created by Marc Boanas on 29/04/2017.
//  Copyright © 2017 Marc Boanas. All rights reserved.
//

import UIKit

class CustomPhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            self.layer.cornerRadius = self.isSelected ? 20.0 : 0.0
        }
    }
    
}
