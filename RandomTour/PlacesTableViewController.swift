//
//  PlacesTableViewController.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

// Present places from Google
class PlacesTableViewController: UIViewController
{
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    fileprivate let context = CoreDataStackManager.sharedInstance.managedObjectContext
    fileprivate var pin: Pin?
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let pin = self.pin {
            let mapRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)    // distance by meters
            miniMapView.setRegion(mapRegion, animated: false)
            miniMapView.addAnnotation(pin)
        }
    }
    
    // MARK: - Privates

    fileprivate func setupMiniMapView()
    {
        miniMapView.isUserInteractionEnabled = false
    }
    
    fileprivate func getGooglePlaces()
    {
        if let pin = pin { // Get places data by pin
            if let _ = pin.places, pin.places?.count > 0 {
                self.placesTableView.reloadData()
            }
            else {
                spinner.startAnimating()
                GooglePlacesClient.sharedInstance.getGooglePlacesByPin(withPin: pin) { (result, error) -> Void in
                    
                    GCDQueues.GlobalMainQueue.async { self.spinner.stopAnimating() }
                    
                    if let error = error {
                        print("Get Google Places with error: \(error.localizedDescription)")
                        GCDQueues.GlobalMainQueue.async {
                            self.spinner.stopAnimating()
                            self.alertMessage("Oops! Something wrong. Please try it again.")
                        }
                    }
                    else {
                        if let dictArray = result, dictArray.count > 0 {
                            for placeProps in dictArray {
                                let _ = Place(placeName: placeProps["name"], vicinity: placeProps["vicinity"], pin: pin,
                                              insertIntoManagedObjectContext: self.context)
                            }
                            DispatchQueue.main.async { // save and update UI
                                CoreDataStackManager.sharedInstance.saveContext()
                                self.placesTableView.reloadData()
                                self.spinner.stopAnimating()
                            }
                        } else {
                            GCDQueues.GlobalMainQueue.async {
                                self.spinner.stopAnimating()
                                self.alertMessage("Oops! Something wrong. Please try a different location.")
                            }
                        }
                    }
                }//GooglePlace
            }
        }//pin
    }
    
    fileprivate func alertMessage(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate struct Storyboards {
        static let PlaceCell = "PlaceCell"              // Table view cell
    }

}//EndClass

// MARK: - Table view data source

extension PlacesTableViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (pin != nil && pin!.places?.count > 0) ? pin!.places!.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboards.PlaceCell, for: indexPath)
        
        // Configure the cell...
        let place = pin!.places![indexPath.row]
        cell.textLabel?.text = place.name
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true // Return false if you do not want the specified item to be editable.
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete {
            // Delete the row from the data source
            deletePlace(atIndexPath: indexPath)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    fileprivate func deletePlace(atIndexPath indexPath: IndexPath) {
        let place = pin!.places![indexPath.row]
        context.delete(place)     // correct way
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
}

extension PlacesTableViewController: UITableViewDelegate {
    //...
}
