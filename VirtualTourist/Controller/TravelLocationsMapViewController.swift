//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/12/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: IB Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editPinLabel: UILabel!
    @IBOutlet weak var editPinButton: UIBarButtonItem!
    
    // MARK: Constants

    // MARK: Variables
    var isEditMode = false
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            excuteSearch()
            updateAllPins()
        }
    }
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Restore the Saved Location
        restoreMapLocation()
        // Add the Long Press Gusture Recognizer
        addLongPressGestureRecognizer()
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        
        // Create the fetch resuled controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // MARK: IB Actions
    @IBAction func editPins(_ sender: UIBarButtonItem) {
        switch sender.title! {
        case "Edit":
            editPinLabel.isHidden = false
            editPinButton.title = "Done"
            isEditMode = true
        case "Done":
            editPinLabel.isHidden = true
            editPinButton.title = "Edit"
            isEditMode = false
        default:
            break
        }
    }
    
    
    // MARK: Helper Functions
    private func restoreMapLocation () {
        if UserDefaults.standard.bool(forKey: "userLocationSaved") {
            let lat = CLLocationDegrees(UserDefaults.standard.double(forKey: "latitude"))
            let lon = CLLocationDegrees(UserDefaults.standard.double(forKey: "longitude"))
            let latDelta = CLLocationDegrees(UserDefaults.standard.double(forKey: "latitudeDelta"))
            let lonDelta = CLLocationDegrees(UserDefaults.standard.double(forKey: "longitudeDelta"))
            mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        }
    }

    private func saveMapLocation () {
        UserDefaults.standard.set(true, forKey: "userLocationSaved")
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "latitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "longitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        UserDefaults.standard.synchronize()        
    }
    
    private func addLongPressGestureRecognizer () {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotaion(press:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func addAnnotaion(press: UILongPressGestureRecognizer) {
        if press.state == .began {
            let location = press.location(in: mapView)
            let coordinates = mapView.convert(location, toCoordinateFrom: mapView)
            
            let _ = Pin(latitude: coordinates.latitude, longitude: coordinates.longitude, context: fetchedResultsController!.managedObjectContext)
            saveStack()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageViewSegue" {
            let imageCollectionViewController = segue.destination as? ImageCollectionViewController
            if let sender = sender as? Pin {
                imageCollectionViewController?.pin = sender
            }
        }
    }
}

// MARK: - TravelLocationsMapViewController
extension TravelLocationsMapViewController {
    func excuteSearch () {
        if let fetchController = fetchedResultsController {
            do {
                try fetchController.performFetch()
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
    
    private func updateAllPins () {
        if let allPins = fetchedResultsController?.fetchedObjects {
            for pin in allPins {
                if let pin = pin as? Pin {
                    mapView.addAnnotation(pin)
                }
            }
        }
    }
}

// MARK: - TravelLocationsMapViewController: MKMapViewDelegate
extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapLocation()
    }
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        if isEditMode {
            if let pin = view.annotation as? Pin {
                fetchedResultsController?.managedObjectContext.delete(pin)
                saveStack()
            }
        } else {
            performSegue(withIdentifier: "imageViewSegue", sender: view.annotation)
        }
    }
}

// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate
extension TravelLocationsMapViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let pin = anObject as? Pin {
            switch type {
            case .insert:
                addPin(pin)
            case .delete:
                removePin(pin)
            case .move:
                removePin(pin)
                addPin(pin)
            case .update:
                removePin(pin)
                addPin(pin)
            }
        }
    }
    
    private func addPin(_ pin : Pin) {
        mapView.addAnnotation(pin)
    }
    
    private func removePin(_ pin : Pin) {
        mapView.removeAnnotation(pin)
    }
}



