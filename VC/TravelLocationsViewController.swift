//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Paul Smith on 5/30/21.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var ops: [BlockOperation]!
    let userDefaults = UserDefaults.standard
    
    let latKey: String = "lat"
    let longKey: String = "long"
    let latDeltaKey: String = "latDelta"
    let longDeltaKey: String = "longDelta"
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.numberOfTouchesRequired = 1
        self.mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        updateMapView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    deinit {
        for o in ops { o.cancel() }
        ops.removeAll()
    }
    
    @objc func handleTap(sender: UIGestureRecognizer) {
        if sender.state == .began
        {
            let locationInView = sender.location(in: self.mapView)
            let locationOnMap = self.mapView.convert(locationInView, toCoordinateFrom: self.mapView)
            addPin(location: locationOnMap)
        }
    }
    
    func addPin(location: CLLocationCoordinate2D){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = location.latitude
        pin.longitude = location.longitude
        try? dataController.viewContext.save()
    }
    
    func updateMapView() {
        guard let mapPins = fetchedResultsController.fetchedObjects else {
            return
        }
        self.mapView.removeAnnotations(self.mapView.annotations)
        var annotations = [MKPointAnnotation]()
        
        for pin in mapPins {

            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)

            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            annotations.append(annotation)
        }

        self.mapView.addAnnotations(annotations)
        zoom()
    }
    
    func zoom(){
        guard let longitudeDelta = userDefaults.object(forKey: longDeltaKey) as? CLLocationDegrees,
           let latitudeDelta = userDefaults.object(forKey: latDeltaKey) as? CLLocationDegrees,
           let longitude = userDefaults.object(forKey: longKey) as? CLLocationDegrees,
           let latitude = userDefaults.object(forKey: latKey) as? CLLocationDegrees else {
            return
        }
    
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func setUserDefaults(){
        userDefaults.setValue(self.mapView.region.center.latitude, forKey: latKey)
        userDefaults.setValue(self.mapView.region.center.longitude, forKey: longKey)
        userDefaults.setValue(self.mapView.region.span.latitudeDelta, forKey: latDeltaKey)
        userDefaults.setValue(self.mapView.region.span.longitudeDelta, forKey: longDeltaKey)
    }

}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let photoVC = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController")as! PhotoAlbumViewController
        guard let pins = fetchedResultsController.fetchedObjects,
              let annotation = view.annotation,
              let indexPath = pins.firstIndex(where: { (pin) -> Bool in
            pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude
        }) else {
            return
        }
        photoVC.pin = pins[indexPath]
        photoVC.dataController = dataController
        self.navigationController?.pushViewController(photoVC, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setUserDefaults()
    }
    
}

extension TravelLocationsViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            ops.append(BlockOperation(block: { [weak self] in
                if let pin = anObject as? Pin {
                    let pointAnnotation = MKPointAnnotation()
                    pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                    self?.mapView.addAnnotation(pointAnnotation)
                }
            }))
        default: break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        ops = [BlockOperation]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for operation in ops {
            operation.start()
        }
        ops = nil
    }
    
}
