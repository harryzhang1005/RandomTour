//
//  RandomTourViewController.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit
import CoreData

struct Notifications {
    static let FetchPhotosDone = "FetchPhotosDoneNotification"
}

class RandomTourViewController: UIViewController
{
    @IBOutlet weak var randomTourMapView: MKMapView!        // The world map view
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!  // Edit to delete pins on the map
    @IBOutlet weak var toolbar: UIToolbar!                  // Give hint to delete pins
    
    private let center = NSNotificationCenter.defaultCenter()
    private let context = CoreDataStackManager.sharedInstance.managedObjectContext   // core data context in main thread
    private var editingMode = false         // You can delete a pin ONLY in editing mode
    private var draggingPinEnded = false    // The pin is draggable, this flag means drag is ended or not
    private var currentMapRegion: CoordinateRegion? // Store map region when user want to change it
    private var selectedPin: Pin?                   // The pin is currently selected
    
    // MARK: - VC Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        toolbar.hidden = true
        
        // when app enter bg state or will be terminated, save the current map region if it has been changed by user
        center.addObserver(self, selector: #selector(RandomTourViewController.archiveCurrentMapRegion),
                           name: UIApplicationDidEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(RandomTourViewController.archiveCurrentMapRegion),
                           name: UIApplicationWillTerminateNotification, object: nil)
        
        setupMapView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadPins()
        selectedPin = nil
        setEditBarButtonItemState()
    }
    
    deinit {
        center.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        center.removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    private func setupMapView()
    {
        randomTourMapView.delegate = self
        //randomTourMapView.mapType = MKMapType.Standard
        randomTourMapView.userInteractionEnabled = true
        
        unarchiveCurrentMapRegion() // restore map region
    }
    
    @IBAction func editPins(sender: UIBarButtonItem) {
        editingMode = !editingMode
        toolbar.hidden = !editingMode
        editBarButtonItem.title = editingMode ? "Done" : "Edit" // Here need set editBarButtonItem style to custom
        
        setEditBarButtonItemState()
    }
    
    private func setEditBarButtonItemState() {
        if !editingMode {
            editBarButtonItem.enabled = randomTourMapView.annotations.count > 0 ? true : false
        }
    }
    
    // MARK: - Map Region Handlers
    
    lazy var currentRegionFilePath: String = { // Here need specify the variable type
        // An array of NSURL objects identifying the requested directories. The directories are ordered according to the order of the domain mask constants, with items in the user domain first and items in the system domain last.
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("CurrentMapRegion").path!
    }()
    
    // The callback can't be private func
    func archiveCurrentMapRegion()
    {
        if let region = currentMapRegion {
            // Archives an object graph rooted at a given object by encoding it into a data object then atomically writes the resulting data object to a file at a given path, and returns a Boolean value that indicates whether the operation was successful.
            // Here will create a file located by the path
            NSKeyedArchiver.archiveRootObject(region, toFile: currentRegionFilePath)
        }
    }
    
    private func unarchiveCurrentMapRegion()
    {
        if NSFileManager.defaultManager().fileExistsAtPath(currentRegionFilePath) { // The file is not exist at first
            currentMapRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(currentRegionFilePath) as? CoordinateRegion
            if let region = currentMapRegion {
                randomTourMapView.setRegion(region.mapRegion, animated: false)
            }
        }
    }
    
    // MARK: - Pin CRUD Handlers
    
    // Read
    private func loadPins()
    {
        // Step-1: Read pins from Core Data
        let fetchPinRequest = NSFetchRequest()
        fetchPinRequest.entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        
        var pins = [Pin]()
        
        do {
            pins = try context.executeFetchRequest(fetchPinRequest) as! [Pin]
        } catch let error as NSError {
            print("Fetch Pins Error: \(error)"); return
        }
        
        // Step-2: Load pins to map view
        if pins.count > 0 {
            randomTourMapView.addAnnotations(pins)
        }
    }
    
    // Delete
    private func deletePin(pin: Pin) {
        pin.cleanImages()                       // First, clean image files if any
        
        randomTourMapView.removeAnnotation(pin) // Then, remove pin from map view
        
        context.deleteObject(pin)               // Third, delete the pin from Core Data database
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    // Update
    private func updatePin(pin: Pin) {
        pin.cleanImages()   // First, clean image files if any
        
        pin.photos = nil    // Then, clean photos and places infos
        pin.places = nil
        CoreDataStackManager.sharedInstance.saveContext()
        
        fetchFlickrPhotosInfosWithPin(pin)    // Third, fetch new photos infos
    }

    // Create - Long press to drop a pin
    @IBAction func addPin(sender: UILongPressGestureRecognizer)
    {
        // Only allow pin to be dropped on state .Began, otherwise we will end up with a series of pins
        if sender.state != .Began { return }
        
        let pressingPoint = sender.locationInView(randomTourMapView)
        
        // Converts a point in the specified view’s coordinate system to a map coordinate.
        let pointOnMap = randomTourMapView.convertPoint(pressingPoint, toCoordinateFromView: randomTourMapView)
        
        // Create a pin and save it to Core Data database
        let annoPin = Pin(latitude: pointOnMap.latitude, longitude: pointOnMap.longitude,
                          insertIntoManagedObjectContext: self.context)
        CoreDataStackManager.sharedInstance.saveContext()
        
        fetchFlickrPhotosInfosWithPin(annoPin)
        
        randomTourMapView.addAnnotation(annoPin)
        
        setEditBarButtonItemState()
    }
    
    // Pre-fetch Flickr photos infos, but not really image files
    private func fetchFlickrPhotosInfosWithPin(pin: Pin)
    {
        if pin.isFetchingPhotos {
            return  // return as early as possible
        } else { pin.isFetchingPhotos = true }
        
        FlickrClient.sharedInstance.getFlickrPhoto(withPin: pin) { result, error in
            if let error = error {
                print("Fetch Flickr photos with error: \(error.localizedDescription)")
            } else {
                if let dictArray = result where dictArray.count > 0 { // result is [[String:String]]
                    for dict in dictArray {
                        let _ = Photo(imageURL: dict["imageURL"], imageName: dict["imageName"], pin: pin,
                                      insertIntoManagedObjectContext: self.context)
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) { // save and update UI
                        CoreDataStackManager.sharedInstance.saveContext()
                        NSNotificationCenter.defaultCenter().postNotificationName(Notifications.FetchPhotosDone, object: nil)
                    }
                } else {
                    print("Couldn't get Flickr photos right now. Please try a different location.")
                }
            }
            
            pin.isFetchingPhotos = false
        }//closure
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == Storyboards.PinSegue {
            if let tourTBVC = segue.destinationViewController as? TourTabBarViewController {
                tourTBVC.pin = selectedPin
            }
        }
    }
    
    private struct Storyboards {
        static let PinSegue = "PinSegue"                // Pin to show Tab bar vc
        static let MapAnnoView = "MapAnnoView"          // MapView annotation view
    }
    
}//EndClass

// Map view only have delegate no data source protocol
extension RandomTourViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        var aPin = mapView.dequeueReusableAnnotationViewWithIdentifier(Storyboards.MapAnnoView) as? MKPinAnnotationView
        if aPin == nil {
            aPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Storyboards.MapAnnoView)
//            aPin?.canShowCallout = true
//            aPin?.userInteractionEnabled = true
//            aPin?.pinTintColor = UIColor.redColor()
        } else {
            aPin?.annotation = annotation
        }
        
        aPin?.animatesDrop = true
        aPin?.draggable = true
        
        return aPin
    }
    
    // work horse
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        // !!!Key point: deselect pin and setSelected state to true, this allows any pin on the map to be moved to a new location with a single long press gesture or with a single tap segue to photo album
        mapView.deselectAnnotation(view.annotation, animated: false) // Deselects the specified annotation and hides its callout view.
        view.setSelected(true, animated: false)
        
        let pin = view.annotation as! Pin
        
        // Update a Pin
        if draggingPinEnded {
            updatePin(pin)
            draggingPinEnded = false
            return
        }
        
        // Tap Pins to delete
        if editingMode {
            deletePin(pin)
        } else {
            selectedPin = pin   // only this case select a pin and perform a segue
            self.performSegueWithIdentifier(Storyboards.PinSegue, sender: self)
        }
    }
    
    // Update the map region
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // This case, mapView.region is after changing region. Means the changed region or the current region.
        currentMapRegion = CoordinateRegion(region: mapView.region)
    }
    
    // Drag a pin ended
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.Ending {
            draggingPinEnded = true
        }
    }
    
}
