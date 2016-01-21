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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        placesTableView.dataSource = self
        placesTableView.delegate = self
        
        spinner.hidesWhenStopped = true
        
        if let pin = (tabBarController as? TourTabBarViewController)?.pin { self.pin = pin }
        
        setupMiniMapView()
        getGooglePlaces()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.title = "Places"
        
        if let pin = pin {
            let mapRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)    // distance by xxx meter
            miniMapView.setRegion(mapRegion, animated: false)
            miniMapView.addAnnotation(pin)
            //miniMapView.showAnnotations([pin], animated: true)
        }
    }

    private func setupMiniMapView()
    {
        //miniMapView.delegate = self
        //miniMapView.mapType = MKMapType.Standard
        miniMapView.userInteractionEnabled = false
    }
    
    private func getGooglePlaces()
    {
        if let pin = pin { // Get places data by pin
            if let _ = pin.places where pin.places?.count > 0 {
                print("places in pin")
                self.placesTableView.reloadData()
            } else {
                spinner.startAnimating()
                GooglePlacesClient.sharedInstance.getGooglePlacesByPin(withPin: pin) { (result, error) -> Void in
                    dispatch_async(dispatch_get_main_queue()) { self.spinner.stopAnimating() }//mainQ
                    if error != nil {
                        print(error)
                    } else {
                        if let dictArray = result {
                            for placeProps in dictArray {
                                let _ = Place(placeName: placeProps["name"], vicinity: placeProps["vicinity"], pin: pin)
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                CoreDataStackManager.sharedInstance.saveContext()    // Save Photos to Core Data
                                self.placesTableView.reloadData()
                            }//mainQ
                        }
                    }
                }//GooglePlace
            }
        }//pin
    }

}

extension PlacesTableViewController: UITableViewDataSource
{
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pin!.places!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.PlaceCell, forIndexPath: indexPath)
        
        // Configure the cell...
        let place = pin!.places![indexPath.row]
        cell.textLabel?.text = place.name
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == .Delete {
            // Delete the row from the data source
            
            let place = pin!.places![indexPath.row]
            context.deleteObject(place)     // correct way
            CoreDataStackManager.sharedInstance.saveContext()
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
        else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
}

extension PlacesTableViewController: UITableViewDelegate
{

}
