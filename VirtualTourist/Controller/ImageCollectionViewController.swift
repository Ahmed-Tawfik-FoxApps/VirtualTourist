//
//  ImageCollectionViewController.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/15/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ImageCollectionViewController: UIViewController {

    // MARK: IB Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    // MARK: Constants
    
    // MARK: Variables
    var pin: Pin!
    var isImageSelected : Bool {
        return collectionView.indexPathsForSelectedItems!.count != 0
    }
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            excuteSearch()
        }
    }
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the Map Region
        setMapRegion()
        
        // Configure Collection View Flow Layout
        configureFlowLayoutForWidth(view.frame.size.width)
        
        // Enable Multi Selection in Collection View
        collectionView.allowsMultipleSelection = true
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        
        // Create the fetch resuled controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            loadNewCollectionImages()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        configureFlowLayoutForWidth(size.width)
    }
    
    // MARK: IB Actions
    @IBAction func newCollection(_ sender: UIButton) {
        if isImageSelected {
            for indexPath in collectionView.indexPathsForSelectedItems! {
                if let image = fetchedResultsController!.object(at: indexPath) as? Image {
                    fetchedResultsController?.managedObjectContext.delete(image)
                    saveStack()
                }
            }
        } else {
            loadNewCollectionImages()
        }
    }
    
    // MARK: Helper Functions
    private func setMapRegion () {
        mapView.region = MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(0.25), longitudeDelta: CLLocationDegrees(0.25)))
        mapView.addAnnotation(pin)
    }
    
    private func configureFlowLayoutForWidth (_ width: CGFloat) {
        if flowLayout != nil {
            let space : CGFloat = 3.0
            let itemsPerLine = 3
            let dimensionFactor = width
            let dimension = (dimensionFactor - (CGFloat(itemsPerLine - 1) * space)) / CGFloat(itemsPerLine)
            
            flowLayout.minimumInteritemSpacing = space
            flowLayout.minimumLineSpacing = space
            flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        }
    }
    
    func loadNewCollectionImages() {
        updateUI(loading: true)
        FlickrClient.sharedInstance().getImageFromFilckrByCoordinates(coordinates: pin.coordinate) { (photosDictionary, error) in
            DispatchQueue.main.async {
                if error != nil {
                    print(error!.localizedDescription)
                } else {
                    /* GUARD: Is the "photo" key in photosDictionary? */
                    guard let photosArray = photosDictionary![FlickrClient.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                        print("Cannot find key '\(FlickrClient.FlickrResponseKeys.Photo)' in \(String(describing: photosDictionary))")
                        return
                    }
                    if photosArray.count == 0 {
                        let alert = UIAlertController(title: "No Image Found", message: "No image found on Flickr for this location, Please Try another location", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    // Delete Prvious Save Images
                    for photo in self.fetchedResultsController!.fetchedObjects! {
                        self.fetchedResultsController?.managedObjectContext.delete(photo as! NSManagedObject)
                    }
                    
                    var numberOfImagesToBeLoaded = self.fetchedResultsController!.fetchedObjects!.count

                    // Get and Save New Image Collection
                    for photoDictionary in photosArray {
                        let imageURLString = photoDictionary[FlickrClient.FlickrResponseKeys.MediumURL] as! String
                        let image = Image(imageURL: imageURLString, imageData: nil, pin: self.pin, context: self.fetchedResultsController!.managedObjectContext)
                        
                        DispatchQueue.global(qos: .utility).async {
                            let imageData = NSData(contentsOf: URL(string: imageURLString)!)!
                            numberOfImagesToBeLoaded -= 1
                            DispatchQueue.main.async {
                                image.imageData = imageData
                                if numberOfImagesToBeLoaded <= 0 {
                                    self.updateUI(loading: false)
                                    self.saveStack()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateUI(loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            newCollectionButton.isEnabled = false
            collectionView.allowsSelection = false
        } else {
            activityIndicator.stopAnimating()
            newCollectionButton.isEnabled = true
            collectionView.allowsSelection = true
        }
    }
}

// MARK: - ImageCollectionViewController
extension ImageCollectionViewController {
    func excuteSearch () {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: \n\(error)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
    
    private func saveStack () {
        do {
            try stack.saveContext()
        } catch {
            print("Error while asving context")
        }
    }
}

// MARK: - ImageCollectionViewController: NSFetchedResultsControllerDelegate
extension ImageCollectionViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
}

// MARK: - ImageCollectionViewController: MKMapViewDelegate
extension ImageCollectionViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

// MARK: - ImageCollectionViewController: UICollectionViewDataSource
extension ImageCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reusedId = "imageCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusedId, for: indexPath) as! ImageCell
        
        let image = fetchedResultsController?.object(at: indexPath) as? Image
        if let imageData = image?.imageData {
            cell.imageView.image = UIImage(data: imageData as Data)
        } else {
            cell.imageView.image = UIImage(named: "ImagePlaceHolder.png")
        }
    
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (fetchedResultsController?.sections![section].numberOfObjects)!
    }

}

// MARK: - ImageCollectionViewController: UICollectionViewDelegate
extension ImageCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 0.5
        newCollectionButton.setTitle(isImageSelected ? "Delete Selected Image" : "New Collection", for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.cellForItem(at: indexPath)?.alpha = 1
        newCollectionButton.setTitle(isImageSelected ? "Delete Selected Image" : "New Collection", for: .normal)
    }
}
