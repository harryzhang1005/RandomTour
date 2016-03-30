//
//  PhotosCollectionViewController.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

class PhotosCollectionViewController: UIViewController
{
    @IBOutlet weak var miniMapView: MKMapView!                  // Show selected pin on the map
    @IBOutlet weak var photosCollectionView: UICollectionView!  // Show fetched photos
    @IBOutlet weak var photosButton: UIButton!                  // Fetch more photos
    @IBOutlet weak var spinnerMain: UIActivityIndicatorView!    // Fetching photos infos
    
    private let context = CoreDataStackManager.sharedInstance.managedObjectContext
    private var selectedIndexPaths = [NSIndexPath]() // or use photosCollectionView.indexPathsForSelectedItems()
    private var blurView: UIVisualEffectView!   // Add blur view when fetching photos infos
    private var pin: Pin?   // Model, the current selected pin on the map
    
    // MARK: - VC Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tabBarController : The nearest ancestor in the view controller hierarchy that is a tab bar controller. (read-only)
        tabBarController?.title = "Photos"
        
        setupPhotosCollectionView()
        
        spinnerMain.hidesWhenStopped = true
        
        // Get our model
        if let pin = (tabBarController as? TourTabBarViewController)?.pin {
            self.pin = pin
        }
        setupMiniMapView()
        fetchFlickrPhotosInfos()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotosCollectionViewController.updateUI),
                                                         name: Notifications.FetchPhotosDone, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: Notifications.FetchPhotosDone, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // here need check photos button state
        setNewPhotosButtonState()
    }
    
    private func setupPhotosCollectionView()
    {
        photosCollectionView.dataSource = self
        photosCollectionView.delegate = self
        photosCollectionView.allowsMultipleSelection = true // default is false
        setupPhotosCollectionViewLayout()
    }
    
    private func setupMiniMapView()
    {
        miniMapView.userInteractionEnabled = false
        
        if let pin = pin {
            let mapRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)    // distance by meters
            miniMapView.setRegion(mapRegion, animated: true)
            miniMapView.addAnnotation(pin)
            //miniMapView.showAnnotations([pin], animated: true) // already set map region, so no need this guy anymore
        }
    }
    
    func updateUI() {
        spinnerMain.stopAnimating()
        removeBlurEffect()
        photosCollectionView.reloadData()
    }
    
    // MARK: - Layout UI
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //setupPhotosCollectionViewLayout()
    }
    
    private func setupPhotosCollectionViewLayout() {
        let flowLayout = UICollectionViewFlowLayout()
        
        // The margins used to lay out content in a section. The default edge insets are all set to 0.
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = CVLayoutConstants.MinimumItemSpacing
        flowLayout.minimumLineSpacing = CVLayoutConstants.MinimumItemSpacing
        
        let itemCount: CGFloat = isLandscapeOrientation() ? CVLayoutConstants.LandscapeItemCount : CVLayoutConstants.PortraitItemCount
        let itemWidth = (view.bounds.width - CGFloat((itemCount - 1)*CVLayoutConstants.MinimumItemSpacing)) / itemCount
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth*CVLayoutConstants.CellItemSizeRatio)
        
        photosCollectionView.collectionViewLayout.invalidateLayout()
        photosCollectionView.collectionViewLayout = flowLayout
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ (_) in
            self.addBlurEffect()
            }) { (_) in
                self.removeBlurEffect()
                self.setupPhotosCollectionViewLayout()
        }
        
        //self.photosCollectionView.setNeedsLayout()
        // view.layoutSubviews() trigger viewWillLayoutSubviews, but You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead to do so prior to the next drawing update. If you want to update the layout of your views immediately, call the layoutIfNeeded method.
    }
    
    // MARK: - Handle Photo Download
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self.cancelAllOperations()
    }
    
    // You should use NSOperation to maintain a list of threads in one queue and its so easy syntactically.
    private var downloadsInProgress = [NSIndexPath : NSOperation]()
    lazy var downloadsQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Photos Download Queue"
        return queue
    }()
    
    private func addPhotoDownloadOperation(forPhoto photo: Photo) {
        // Check the indexPath is existing or not
        let indexPath = photo.indexPath!
        guard downloadsInProgress[indexPath] == nil else { return }
        
        // Create a new photo download operation
        let downloadOp = PhotoDownloader(photoRecord: photo.photoRecord!)
        
        downloadOp.completionBlock = {
            if downloadOp.cancelled { return }
            
            dispatch_async(GCDQueues.GlobalMainQueue) { // update UI
                self.downloadsInProgress.removeValueForKey(indexPath)
                //self.collectionView.reloadItemsAtIndexPaths([indexPath])  // !!!: very bad response
                
                let visibleCells = self.photosCollectionView.visibleCells() as! [PhotoCollectionViewCell]
                for cell in visibleCells {
                    if indexPath == self.photosCollectionView.indexPathForCell(cell) {
                        cell.backgroundView = UIImageView(image: photo.image)
                        cell.spinner.stopAnimating()
                        photo.didFetchImageData = true
                        break
                    }
                }
            }
        }
        
        // Add the photo download operation to the queue
        self.downloadsInProgress[indexPath] = downloadOp
        self.downloadsQueue.addOperation(downloadOp)
    }
    
    // MARK: - UIScrollViewDelegate methods
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.suspendAllOperations()             // suspend all photo download operations
    }
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            handleOperationsForOnscreenCells()  // handle operations for on-screen cells
            self.resumeAllOperations()          // resume all photo download operations
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        handleOperationsForOnscreenCells()  // handle operations for on-screen cells
        self.resumeAllOperations()          // resume all photo download operations
    }
    
    // MARK: - Actions
    
    // fetch new photos or delete selected photos
    @IBAction func handlePhotos(sender: UIButton)
    {
        if selectedIndexPaths.count > 0 {
            deletePhotos()
        }
        else { // fetch more photos
            cleanCurrentPhotosInPin()
            fetchFlickrPhotosInfos()
        }
    }
    
    // MARK: - Private helpers
    
    // The off-screen cells should stop download operations
    private func handleOperationsForOnscreenCells()
    {
        // 1 Get all the currently visible items in the collection view to an array containing index paths
        let indexPathsOnscreenCells = self.photosCollectionView.indexPathsForVisibleItems()  // [NSIndexPath]
        
        // 2 Construct a set of all pending operations in the download operations in progress, indexPaths in the set
        let allPendingOperations = NSMutableSet(array: Array(downloadsInProgress.keys)) // key is indexPath
        print("current all pending operations count: \(allPendingOperations.count)")   // Sometimes 0 ? maybe timing reason
        
        // 3 Note: here using mutableCopy
        let toBeCancelledSet = allPendingOperations.mutableCopy() as! NSMutableSet
        let visibleCellSet = NSSet(array: indexPathsOnscreenCells)
        toBeCancelledSet.minusSet(visibleCellSet as Set<NSObject>)  // get the final to be cancelled operations set
        
        // 4 Construct a set of index paths that need their operations started. Start with index paths all visible rows, and then remove the ones where operations are already pending.
        let toBeStarted = visibleCellSet.mutableCopy() as! NSMutableSet
        //toBeStarted.minusSet((allPendingOperations as NSSet) as Set<NSObject>)
        toBeStarted.minusSet(allPendingOperations as Set<NSObject>)   // !!!: Here is key point
        
        // 5 cancel all off-screens operations
        for indexPath in toBeCancelledSet      // Can NOT use (a in b)
        {
            let indexPath = indexPath as! NSIndexPath
            
            if let pendingDownloadOp = downloadsInProgress[indexPath] {
                pendingDownloadOp.cancel()
            }
            downloadsInProgress.removeValueForKey(indexPath)  // put here more safety
        }
        
        // 6 start all on-screen operations
        for indexPath in toBeStarted
        {
            let indexPath = indexPath as! NSIndexPath
            let photo = photoAtIndexPath(indexPath: indexPath)
            
            if let photoRecord = photo.photoRecord where photoRecord.state == PhotoRecordState.New {
                addPhotoDownloadOperation(forPhoto: photo) // ONLY here really start to download image or use local image
            }
        }
    }
    
    private func cancelAllOperations() {
        downloadsQueue.cancelAllOperations()
    }
    private func resumeAllOperations() {
        downloadsQueue.suspended = false
    }
    private func suspendAllOperations() {
        downloadsQueue.suspended = true
    }
    
    private func photoAtIndexPath(indexPath indexPath: NSIndexPath) -> Photo {
        let photo = pin!.photos![indexPath.row]
        photo.indexPath = indexPath
        if photo.photoRecord == nil {
            if let remotePath = photo.imageURL {
                photo.photoRecord = PhotoRecord(url: NSURL(string: remotePath)!)
            }
        }
        return photo
    }
    
    private func isLandscapeOrientation() -> Bool {
        return UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation)
    }
    
    // self.photosCollectionView.collectionViewLayout.collectionViewContentSize() // this is dynmaic size with cell items count
    private func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = photosCollectionView.bounds
        // !!!: An integer bit mask that determines how the receiver resizes itself when its superview’s bounds change.
        blurView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        photosCollectionView.addSubview(blurView)
        photosCollectionView.bringSubviewToFront(spinnerMain)
        photosCollectionView.userInteractionEnabled = false
        photosButton.enabled = false
    }
    
    private func removeBlurEffect() {
        if let blurView = blurView where blurView.superview != nil { blurView.removeFromSuperview() }
        self.photosCollectionView.userInteractionEnabled = true
        photosButton.enabled = true
    }
    
    private func fetchFlickrPhotosInfos()
    {
        if let pin = pin {
            if let _ = pin.photos where pin.photos?.count > 0 {
                self.updateUI()
            }
            else {
                self.addBlurEffect()
                spinnerMain.startAnimating()
                if pin.isFetchingPhotos {
                    print("The photos is fetching for this pin!")
                    return
                } else { pin.isFetchingPhotos = true }
                
                FlickrClient.sharedInstance.getFlickrPhoto(withPin: pin) { result, error in
                    
                    if let error = error {
                        print("Get Flickr photos with error: \(error.localizedDescription)")
                        dispatch_async(GCDQueues.GlobalMainQueue) {
                            self.updateUI()
                            self.alertMessage("Oops! Something wrong. Please try it again.")
                        }
                    }
                    else {
                        if let dictArray = result where dictArray.count > 0 {
                            for aPhoto in dictArray {
                                let _ = Photo(imageURL: aPhoto["imageURL"], imageName: aPhoto["imageName"], pin: pin,
                                              insertIntoManagedObjectContext: self.context)
                            }
                            
                            dispatch_async(GCDQueues.GlobalMainQueue) {
                                CoreDataStackManager.sharedInstance.saveContext()    // Save Photos to Core Data
                                self.updateUI()
                            }
                        }
                        else {
                            dispatch_async(GCDQueues.GlobalMainQueue) {
                                self.updateUI()
                                self.alertMessage("Couldn't get Flickr photos right now. Please try a different location.")
                            }
                        }
                    }
                    
                    pin.isFetchingPhotos = false
                }//closure
            }
        }//pin
    }
    
    private func alertMessage(msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .Alert)
        let cancel = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(cancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func cleanCurrentPhotosInPin()
    {
        if let pin = pin {
            pin.cleanImages()
            pin.photos = nil
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }
    
    private func togglePhotoButtonTitle() {
        let buttonTitle = (selectedIndexPaths.count > 0) ? Storyboards.DeletePhotos : Storyboards.NewPhotos
        photosButton.setTitle(buttonTitle, forState: .Normal)
    }
    
    private func setNewPhotosButtonState() {
        photosButton.enabled = (pin != nil && pin!.isFetchingPhotos) ? false : true
    }
    
    private func deletePhotos()
    {
        if selectedIndexPaths.count > 0
        {
            for indexPath in selectedIndexPaths
            {
                let photo = pin!.photos![indexPath.row]
                deleteLocalImageDataFile(photo) // Also delete local image file
                context.deleteObject(photo)     // Here is correct way to delete a photo from core data
            }
            CoreDataStackManager.sharedInstance.saveContext()   // save once for better performance
            
            // Animates multiple insert, delete, reload, and move operations as a group.
          //photosCollectionView.performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)?)
            photosCollectionView.performBatchUpdates({ [unowned self] in
                self.photosCollectionView.deleteItemsAtIndexPaths(self.selectedIndexPaths)
                }) { [unowned self] (_) in
                    self.selectedIndexPaths.removeAll()
                    self.togglePhotoButtonTitle()
            }
        }
    }
    
    private func deleteLocalImageDataFile(photo: Photo) {
        if let photoRecord = photo.photoRecord {
            photoRecord.deleteImageDataFile()
        }
    }
    
    private struct Storyboards {
        static let PhotoCell = "PhotoCell"              // Collection view cell
        static let NewPhotos = "New Photos"
        static let DeletePhotos = "Delete Photo(s)"
    }
    
    private struct CVLayoutConstants {
        static let PortraitItemCount: CGFloat = 3
        static let LandscapeItemCount: CGFloat = 5
        static let MinimumItemSpacing: CGFloat = 8
        static let CellItemSizeRatio: CGFloat = 1.2
    }

}//EndClass

// MARK: - UICollectionViewDataSource

extension PhotosCollectionViewController: UICollectionViewDataSource
{
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (pin != nil && pin!.photos?.count > 0) ? pin!.photos!.count : 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(Storyboards.PhotoCell, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Configure the cell
        let photo = photoAtIndexPath(indexPath: indexPath)
        if let photoRecord = photo.photoRecord where photoRecord.state == PhotoRecordState.New {
            if !self.photosCollectionView.dragging && !self.photosCollectionView.decelerating {
                addPhotoDownloadOperation(forPhoto: photo)  // ONLY here really start to download image or use local image
            }
        }
        cell.photo = photo
        
        return cell
    }
    
}

// MARK: - UICollectionViewDelegate

extension PhotosCollectionViewController: UICollectionViewDelegate
{
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let photo = pin!.photos![indexPath.row]
        return photo.didFetchImageData || photo.photoRecord?.state == PhotoRecordState.Downloaded ? true : false
    }
    
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let photo = pin!.photos![indexPath.row]
        
        return photo.didFetchImageData || photo.photoRecord?.state == PhotoRecordState.Downloaded ? true : false
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        selectedIndexPaths.append(indexPath)
        togglePhotoButtonTitle()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let index = selectedIndexPaths.indexOf(indexPath) {
            selectedIndexPaths.removeAtIndex(index)
        }
        togglePhotoButtonTitle()
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

extension Photo {
    var image: UIImage? {
        if self.photoRecord?.state == PhotoRecordState.Downloaded {
            return self.photoRecord?.image  // image comes online or offline (local image file)
        }
        return UIImage.defaultImage
    }
}
