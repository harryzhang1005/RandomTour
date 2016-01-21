//
//  PhotosCollectionViewController.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit
import CoreData     // not really using

private let reuseIdentifier = "PhotoCell"

class PhotosCollectionViewController: UIViewController
{
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var miniMapView: MKMapView!
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var spinnerMain: UIActivityIndicatorView!
    // The pin has no image label
    
    private let context = CoreDataStackManager.sharedInstance.managedObjectContext
    
    //// not using start ////
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageName", ascending: true)]
        
        let fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchController
    }()
    
    private func setupFetchedResultsController()
    {
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("\(error)")
        }
    }
    //// not using end ////
    
    private var selectedIndexPaths = [NSIndexPath]()    // maybe no need, just use collection's indexPathsForSelectedItems()
    
    private var pin: Pin?   // Model
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        setupPhotosCollectionView()
        
        spinnerMain.hidesWhenStopped = true
        
        if let pin = (tabBarController as? TourTabBarViewController)?.pin { self.pin = pin }
        
        setupMiniMapView()
        getFlickrPhotos()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // tabBarController : The nearest ancestor in the view controller hierarchy that is a tab bar controller. (read-only)
        tabBarController?.title = "Photos"  // works
        
        if let pin = pin {
            let mapRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)    // distance by xxx meter
            miniMapView.setRegion(mapRegion, animated: true)
            miniMapView.addAnnotation(pin)
            //miniMapView.showAnnotations([pin], animated: true)
        }
        
        // here need check photos button state
        togglePhotosButtonState()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // The margins used to lay out content in a section. The default edge insets are all set to 0.
        flowLayout.minimumInteritemSpacing = 8.0
        flowLayout.minimumLineSpacing = 8.0
        
        var itemCount: CGFloat = 3
        if isLandscapeOrientation() { itemCount = 5 }
        let itemWidth = (view.bounds.width - CGFloat((itemCount - 1)*8)) / itemCount
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth*1.2)
        
        photosCollectionView.collectionViewLayout = flowLayout
    }
    
    private func isLandscapeOrientation() -> Bool {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation)
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        view.layoutSubviews()   // trigger viewWillLayoutSubviews
    }
    
    private func setupPhotosCollectionView()
    {
        photosCollectionView.dataSource = self
        photosCollectionView.delegate = self
        photosCollectionView.allowsMultipleSelection = true // default is false
    }
    
    private func setupMiniMapView()
    {
        //miniMapView.delegate = self
        //miniMapView.mapType = MKMapType.Standard
        miniMapView.userInteractionEnabled = false
    }
    
    private func getFlickrPhotos()
    {
        if let pin = pin { // Get Flickr Photos by Pin
            if let _ = pin.photos where pin.photos?.count > 0 {
                print("photos in pin")
                self.photosCollectionView.reloadData()
            } else {
                print("new fetched photos")
                spinnerMain.startAnimating()
                if pin.isFetchingPhotos { return } else { pin.isFetchingPhotos = true }
                photosButton.enabled = false
                FlickrClient.sharedInstance.getFlickrPhoto(withPin: pin) { result, error in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.spinnerMain.stopAnimating()
                        self.photosButton.enabled = true
                    }//mainQ
                    if error != nil {
                        print(error)
                    } else {
                        if let dictArray = result {
                            for retPhoto in dictArray {
                                let _ = Photo(imageURL: retPhoto["imageURL"], imageName: retPhoto["imageName"], pin: pin)
                            }
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                CoreDataStackManager.sharedInstance.saveContext()    // Save Photos to Core Data
                                self.photosCollectionView.reloadData()
                            }//mainQ
                        }
                    }
                    pin.isFetchingPhotos = false
                }//FlickrPhoto
            }
        }//pin
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func handlePhotos(sender: UIButton)
    {
        if selectedIndexPaths.count > 0 {
            deletePhotos()
            updatePhotoButtonTitle()
        }
        else { // more new photos
            cleanCurrentPhotosInPin()
            getFlickrPhotos()
        }
    }
    
    private func cleanCurrentPhotosInPin()
    {
        if let pin = pin {
            pin.photos = nil
            CoreDataStackManager.sharedInstance.saveContext()
        }

        // another way
//        if let fetchedObjects = fetchedResultsController.fetchedObjects {
//            for obj in fetchedObjects {
//                let photo = obj as! Photo
//                context.deleteObject(photo)
//            }
//            CoreDataStackManager.sharedInstance.saveContext()
//        }
    }
    
    private func updatePhotoButtonTitle() {
        if selectedIndexPaths.count > 0 {
            photosButton.setTitle("Delete Photo(s)", forState: .Normal)
        } else {
            photosButton.setTitle("New Photos", forState: .Normal)
        }
    }
    
    private func togglePhotosButtonState() {
        if photosButton.currentTitle == "New Photos" {
            if pin!.isFetchingPhotos {
                photosButton.enabled = false
            } else {
                photosButton.enabled = true
            }
        } else {
            photosButton.enabled = true
        }
    }
    
    /*
    attempt to add identical layout attributes to list of on screen attributes to animated
    attempt to create two animations for new global item index 4
    fatal error: Array index out of range
    */
    private func deletePhotos()
    {
        if selectedIndexPaths.count > 0
        {
            for indexPath in selectedIndexPaths
            {
                let photo = pin!.photos![indexPath.row]   // fatal error: Array index out of range
                context.deleteObject(photo) // Here is correct way to delete a photo
            }
            CoreDataStackManager.sharedInstance.saveContext()
            
            photosCollectionView.deleteItemsAtIndexPaths(selectedIndexPaths)
            photosCollectionView.performBatchUpdates(nil, completion: nil) // Animates multiple insert, delete, reload, and move operations as a group.
            selectedIndexPaths.removeAll() // clean up
        }//if
    }

}

extension PhotosCollectionViewController: UICollectionViewDataSource
{
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //let sectionInfo = self.fetchedResultsController.sections![section]
        //return sectionInfo.numberOfObjects
        
        return pin!.photos!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Configure the cell
        let photo = pin!.photos![indexPath.row]
        cell.configCell(photo)
        
        return cell
    }
    
}

// MARK: UICollectionViewDelegate

extension PhotosCollectionViewController: UICollectionViewDelegate
{
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let photo = pin!.photos![indexPath.row]
        if !photo.didFetchImageData { return false }
        return true
    }
    
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let photo = pin!.photos![indexPath.row]
        if !photo.didFetchImageData { return false }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPaths.append(indexPath)
        updatePhotoButtonTitle()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let index = selectedIndexPaths.indexOf(indexPath) {
            selectedIndexPaths.removeAtIndex(index)
        }
        updatePhotoButtonTitle()
    }

    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }
    
    func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        
    }
    
    
}

extension PhotosCollectionViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // x
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // x
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // x
    }
}

