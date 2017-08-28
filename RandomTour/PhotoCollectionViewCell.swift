//
//  PhotoCollectionViewCell.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell
{
    var photo: Photo? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        spinner.color = UIColor.black
        spinner.hidesWhenStopped = true
    }
    
    fileprivate func updateUI() {
        // First, clean up
        self.backgroundView = nil
        self.selectedBackgroundView = nil
        
        // Then, set new value
        if let photo = photo {
            configCell(photo)
        }
    }
    
    func configCell(_ photo: Photo)
    {
        self.backgroundView = UIImageView(image: photo.image)
        self.backgroundView?.contentMode = UIViewContentMode.scaleAspectFill
		
        if let photoRecord = photo.photoRecord {
            photoRecord.state == .new ? self.spinner.startAnimating() : self.spinner.stopAnimating()
        } else {
            self.spinner.startAnimating()
        }
        
        // for selected state
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.backgroundColor = UIColor(white: 0.5, alpha: 0.5) //UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.25)
        
        let checkmark = UIImageView(image: UIImage(named: "Checkmark")) // Note: image name is case sensitive
        checkmark.contentMode = UIViewContentMode.bottomRight
        checkmark.frame = self.bounds   // !!!: works, real cell item size
        //checkmark.frame = self.contentView.bounds // not work, contentView in IB size (0, 0, 120, 120), not real item size
        
        selectedBgView.addSubview(checkmark)
        self.selectedBackgroundView = selectedBgView
    }
    
}//EndClass
