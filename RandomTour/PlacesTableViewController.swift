//
//  PlacesTableViewController.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

class PlacesTableViewController: UIViewController
{
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private let context = CoreDataStackManager.sharedInstance.managedObjectContext
    private var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.title = "Places"
        placesTableView.dataSource = self
        placesTableView.delegate = self
        spinner.hidesWhenStopped = true
        
        if let pin = (tabBarController as? TourTabBarViewController)?.pin {
            self.pin = pin
        }
        
        setupMiniMapView()
        getGooglePlaces()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Privates

    private func setupMiniMapView()
    {
        miniMapView.userInteractionEnabled = false
        
        if let pin = self.pin {
            let mapRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)    // distance by meters
            miniMapView.setRegion(mapRegion, animated: false)
            miniMapView.addAnnotation(pin)
        }
    }
    
    private func getGooglePlaces()
    {
        if let pin = pin { // Get places data by pin
            if let _ = pin.places where pin.places?.count > 0 {
                self.placesTableView.reloadData()
            }
            else {
                spinner.startAnimating()
                GooglePlacesClient.sharedInstance.getGooglePlacesByPin(withPin: pin) { (result, error) -> Void in
                    
                    dispatch_async(GCDQueues.GlobalMainQueue) { self.spinner.stopAnimating() }
                    
                    if let error = error {
                        print("Get Google Places with error: \(error.localizedDescription)")
                        dispatch_async(GCDQueues.GlobalMainQueue) {
                            self.spinner.stopAnimating()
                            self.alertMessage("Oops! Something wrong. Please try it again.")
                        }
                    }
                    else {
                        if let dictArray = result where dictArray.count > 0 {
                            for placeProps in dictArray {
                                let _ = Place(placeName: placeProps["name"], vicinity: placeProps["vicinity"], pin: pin,
                                              insertIntoManagedObjectContext: self.context)
                            }
                            dispatch_async(dispatch_get_main_queue()) { // save and update UI
                                CoreDataStackManager.sharedInstance.saveContext()
                                self.placesTableView.reloadData()
                                self.spinner.stopAnimating()
                            }
                        } else {
                            dispatch_async(GCDQueues.GlobalMainQueue) {
                                self.spinner.stopAnimating()
                                self.alertMessage("Oops! Something wrong. Please try a different location.")
                            }
                        }
                    }
                }//GooglePlace
            }
        }//pin
    }
    
    private func alertMessage(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(cancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private struct Storyboards {
        static let PlaceCell = "PlaceCell"              // Table view cell
    }

}//EndClass

// MARK: - Table view data source

extension PlacesTableViewController: UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (pin != nil && pin!.places?.count > 0) ? pin!.places!.count : 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboards.PlaceCell, forIndexPath: indexPath)
        
        // Configure the cell...
        let place = pin!.places![indexPath.row]
        cell.textLabel?.text = place.name
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true // Return false if you do not want the specified item to be editable.
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete {
            // Delete the row from the data source
            deletePlace(atIndexPath: indexPath)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    private func deletePlace(atIndexPath indexPath: NSIndexPath) {
        let place = pin!.places![indexPath.row]
        context.deleteObject(place)     // correct way
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
}

extension PlacesTableViewController: UITableViewDelegate {
    //...
}
