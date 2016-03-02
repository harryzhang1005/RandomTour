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

class RandomTourViewController: UIViewController
{
    @IBOutlet weak var randomTourMapView: MKMapView!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    
    private let context = CoreDataStackManager.sharedInstance.managedObjectContext   // core data context
    private var editingMode = false // pins can be deleted or not
    private var isDragPinEnded = false  // the pin is dragable, this flag means drag is ended or not
    private var currentMapRegion: CoordinateRegion? // save map region when user want to change it
    private var selectedPin: Pin?   // current selected pin
    
    let center = NSNotificationCenter.defaultCenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // when app enter bg state or will be terminated, save the current map region if it has been changed by user
        center.addObserver(self, selector: "archiveCurrentMapRegion", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: "archiveCurrentMapRegion", name: UIApplicationWillTerminateNotification, object: nil)
        
        setupMapView()
        
        toolbar.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadPins()
        selectedPin = nil
    }
    
    deinit {
        center.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        center.removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
    }
    
    private func setupMapView()
    {
        randomTourMapView.delegate = self
        //randomTourMapView.mapType = MKMapType.Standard    // default?
        randomTourMapView.userInteractionEnabled = true

        // Here no need, only save map region when user want to change it
        // currentMapRegion = CoordinateRegion(region: randomTourMapView.region)
        
        unarchiveCurrentMapRegion()
    }
    
    // MARK: - Map Region
    
    lazy var currentRegionFilePath: String = { // Here need specify the variable type
        // The directory the application uses to store the store file. This code uses a directory named "com.happyguy.RandomTour" in the application's documents Application Support directory.
        // An array of NSURL objects identifying the requested directories. The directories are ordered according to the order of the domain mask constants, with items in the user domain first and items in the system domain last.
        
        //        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        //        return urls[urls.count-1]     // same as the below first
        
        // first : Returns a value less than or equal to the number of elements in `self`, *nondestructively*.
        let url = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!

        return url.URLByAppendingPathComponent("CurrentMapRegion").path!
    }()
    
    private func archiveCurrentMapRegion()
    {
        if let region = currentMapRegion {
            // Archives an object graph rooted at a given object by encoding it into a data object then atomically writes the resulting data object to a file at a given path, and returns a Boolean value that indicates whether the operation was successful.
            // Here will create a file by the path
            print("save region path: \(currentRegionFilePath)")
            NSKeyedArchiver.archiveRootObject(region, toFile: currentRegionFilePath)
        } else {
            print("current region is nil")
        }
    }
    
    private func unarchiveCurrentMapRegion()
    {
        if NSFileManager.defaultManager().fileExistsAtPath(currentRegionFilePath) { // At first the file will not exist
            currentMapRegion = NSKeyedUnarchiver.unarchiveObjectWithFile(currentRegionFilePath) as? CoordinateRegion
            if let region = currentMapRegion {
                print("unarchive set region")
                randomTourMapView.setRegion(region.mapRegion, animated: false)
            } else {
                print("unarchive failed")
            }
        }
    }
    
    // MARK: - Pin Handlers
    
    // Read Core Data
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
    
    // Delete Core Data
    private func deletePin(pin: Pin) {
        randomTourMapView.removeAnnotation(pin)
        context.deleteObject(pin)
        CoreDataStackManager.sharedInstance.saveContext()
    }
    
    private func updatePin(pin: Pin) {
        pin.photos = nil
        pin.places = nil
        CoreDataStackManager.sharedInstance.saveContext()
        getFlickrPhotos(pin)
    }

    @IBAction func editPins(sender: UIBarButtonItem) {
        editingMode = !editingMode
        toolbar.hidden = !editingMode
        // editBarButtonItem style is custom
        editingMode ? (editBarButtonItem.title = "Done") : (editBarButtonItem.title = "Edit")
    }

    // Long press to drop a pin
    @IBAction func addPin(sender: UILongPressGestureRecognizer)
    {
        // Only allow pin to be dropped on state .Began, otherwise we will end up with a series of pins
        if sender.state != .Began { return }
        
        let pointPress = sender.locationInView(randomTourMapView)
        
        // Converts a point in the specified view’s coordinate system to a map coordinate.
        let mapLocation = randomTourMapView.convertPoint(pointPress, toCoordinateFromView: randomTourMapView)
        
        let annoPin = Pin(lati: mapLocation.latitude, long: mapLocation.longitude)
        CoreDataStackManager.sharedInstance.saveContext()    // Save pin to Core Data
        
        getFlickrPhotos(annoPin)
        randomTourMapView.addAnnotation(annoPin)
        
        // Sets the visible region so that the map displays the specified annotations.
        //randomTourMapView.showAnnotations([annoPin], animated: true)  // here no need
    }
    
    // Pre-fetch Flickr photos
    private func getFlickrPhotos(pin: Pin)
    {
        if pin.isFetchingPhotos { return } else { pin.isFetchingPhotos = true }
        
        // NOTE: sometimes can't fetch photos, should try it later or change pin
        FlickrClient.sharedInstance.getFlickrPhoto(withPin: pin) { result, error in
            if let error = error {
                print(error)
            } else {
                if let dictArray = result { // result is [[String:String]]
                    for dict in dictArray {
                        let _ = Photo(imageURL: dict["imageURL"], imageName: dict["imageName"], pin: pin)
                    }
                    
                    // Back to main queue and save it
                    dispatch_async(dispatch_get_main_queue()) { CoreDataStackManager.sharedInstance.saveContext() }
                }
            }
            pin.isFetchingPhotos = false
        }//flickr
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == Storyboards.PinSegue {
            if let tourTBVC = segue.destinationViewController as? TourTabBarViewController {
                if let pin = selectedPin {
                    tourTBVC.pin = pin
                }
            }
        }
    }
    
    private struct Storyboards {
        static let PinSegue = "PinSegue"                // Pin to show Tab bar vc
        static let MapAnnoView = "MapAnnoView"          // MapView annotation view
    }
    
}

extension RandomTourViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        var annoView = mapView.dequeueReusableAnnotationViewWithIdentifier(Storyboards.MapAnnoView) as? MKPinAnnotationView
        if annoView == nil {
            annoView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Storyboards.MapAnnoView)
//            annoView!.canShowCallout = true
//            annoView?.userInteractionEnabled = true
//            annoView?.pinTintColor = UIColor.redColor()
        } else {
            annoView?.annotation = annotation
        }
        
        annoView?.animatesDrop = true
        annoView?.draggable = true
        
        // immediately select this pin view (needs to be selected first to be dragged)
        //annoView?.setSelected(true, animated: false)
        
        return annoView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        // deselect pin and setSelected state to true, this allows any pin on the map to be moved to a new location with a single long press gesture or with a single tap segue to photo album
        mapView.deselectAnnotation(view.annotation, animated: false)
        view.setSelected(true, animated: false)
        
        let pin = view.annotation as! Pin
        
        // Update a Pin
        if isDragPinEnded {
            updatePin(pin)
            isDragPinEnded = false
            return
        }
        
        // Tap Pins to delete
        if editingMode {
            deletePin(pin)
        } else {
            selectedPin = pin   // only this case select a pin and segue
            self.performSegueWithIdentifier(Storyboards.PinSegue, sender: self)
        }
    }
    
    // Here is key point to update the map region
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // This case, mapView.region is after changing region. Means the changed region or the current region.
        currentMapRegion = CoordinateRegion(region: mapView.region)
    }
    
//    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
//        // This case, mapView.region is before changing region
//    }
    
    // Drag a pin ended
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.Ending {
            isDragPinEnded = true
        }
    }
    
}
