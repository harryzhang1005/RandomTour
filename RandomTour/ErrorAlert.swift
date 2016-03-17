//
//  ErrorAlert.swift
//
//  Created by Harvey Zhang on 4/1/15.
//  Copyright (c) 2015 HappyGuy. All rights reserved.
//

import UIKit

class ErrorAlert {
    // Here should use class func instead of static func
    class func create(errorTitle: String, errorMessage: String, viewController: UIViewController)
    {
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        let image = UIImage(named: "error")
        let imageView = UIImageView(image: image)
        imageView.frame.origin.x += 11
        imageView.frame.origin.y += 11
        imageView.frame.size.width -= 7
        imageView.frame.size.height -= 7
        
        alert.view.addSubview(imageView)
        
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        
        // presentedViewController, The view controller that is presented by this view controller (viewController), or one of its ancestors in the view controller hierarchy. (read-only)
        if viewController.presentedViewController == nil {
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
