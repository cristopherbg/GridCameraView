//
//  ImagePickerCell.swift
//  AVCam Swift
//
//  Created by Cristopher A. Bautista Gómez on 11/13/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import UIKit

class ImagePickerCell: UICollectionViewCell {
    
    @IBOutlet weak fileprivate var imageView: UIImageView!
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
}

