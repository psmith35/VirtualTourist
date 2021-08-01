//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Paul Smith on 5/30/21.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    let gapSize: CGFloat = 2.0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var albumFlowLayout: UICollectionViewFlowLayout!
    
    var dataController:DataController!
    var pin: Pin!

    var ops: [BlockOperation] = []
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var mapAnnotation: MKPointAnnotation!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
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
        
        mapAnnotation = MKPointAnnotation()
        self.mapView.addAnnotation(mapAnnotation)
        
        albumFlowLayout.minimumInteritemSpacing = gapSize
        albumFlowLayout.minimumLineSpacing = gapSize
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateMapView()
        if let count = fetchedResultsController.fetchedObjects?.count, count <= 0 {
            newCollectionButton.isEnabled = false
            FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, completion: handleUpdateResponse(photos:error:))
        }
        else {
            self.photoCollectionView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    deinit {
        for o in ops { o.cancel() }
        ops.removeAll()
    }
        
    func updateMapView() {
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)

        mapAnnotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        self.mapView.setCenter(CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), animated: false);
    }
    
    func handleUpdateResponse(photos: [PhotoResponse]?, error: Error?) {
        if let error = error {
            showUpdateFailure(error: error)
        }
        if let photos = photos {
            for photo in photos {
                addPhoto(photoResponse: photo)
            }
            photoCollectionView.reloadData()
        }
        newCollectionButton.isEnabled = true
    }
    
    func downloadImage(photo: Photo){
        guard let url = URL(string: photo.urlPath!) else {
            return
        }
        let session = URLSession.shared
        let request: URLRequest = URLRequest(url: url)
        let task = session.dataTask(with: request) {data, response, downloadError in
            DispatchQueue.main.async {
                guard let photoData = data else {
                    print(downloadError?.localizedDescription ?? "Error Downloading Photo")
                    return
                }
                self.updatePhoto(photo: photo, photoData: photoData)
            }
        }
        task.resume()
    }
    
    func addPhoto(photoResponse: PhotoResponse) {
        let photo = Photo(context: dataController.viewContext)
        photo.urlPath = photoResponse.urlStringValue
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    func updatePhoto(photo: Photo, photoData: Data) {
        photo.photoData = photoData
        try? dataController.viewContext.save()
    }

    func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    func deleteAll() {
        if let objects = fetchedResultsController.fetchedObjects {
            for object in objects {
                dataController.viewContext.delete(object)
            }
            try? dataController.viewContext.save()
        }
    }
    
    func showUpdateFailure(error: Error?) {
        let alertVC = UIAlertController(title: "Update Failed", message: error?.localizedDescription ?? "", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        newCollectionButton.isEnabled = false
        deleteAll()
        FlickrClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, completion: handleUpdateResponse(photos:error:))
    }

}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dimension = (view.bounds.size.width - (gapSize*2.0))/3.0
        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        collectionView.isHidden = count <= 0
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        guard let photo = fetchedResultsController.fetchedObjects?[indexPath.row] else {
            return cell
        }
        
        if let photoData = photo.photoData {
            cell.imageView.image = UIImage(data: photoData)
        }
        else {
            downloadImage(photo: photo)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
        deletePhoto(at: indexPath)
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}

extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                ops.append(BlockOperation(block: { [weak self] in
                    guard let indexPath = newIndexPath else {
                        return
                    }
                    self?.photoCollectionView.insertItems(at: [indexPath])
                }))
            case .delete:
                ops.append(BlockOperation(block: { [weak self] in
                    guard let indexPath = indexPath else {
                        return
                    }
                    self?.photoCollectionView.deleteItems(at: [indexPath])
                }))
            case .update:
                ops.append(BlockOperation(block: { [weak self] in
                    guard let indexPath = indexPath else {
                        return
                    }
                    self?.photoCollectionView.reloadItems(at: [indexPath])
                }))
            case .move:
                ops.append(BlockOperation(block: { [weak self] in
                    guard let indexPath = indexPath, let newIndexPath = newIndexPath else {
                        return
                    }
                    self?.photoCollectionView.moveItem(at: indexPath, to: newIndexPath)
                }))
            default:
                break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            ops.append(BlockOperation(block: { [weak self] in
                self?.photoCollectionView.insertSections(indexSet)
            }))
        case .delete:
            ops.append(BlockOperation(block: { [weak self] in
                self?.photoCollectionView.deleteSections(indexSet)
            }))
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoCollectionView.performBatchUpdates({ () -> Void in
            for op: BlockOperation in self.ops { op.start() }
        }, completion: { (finished) -> Void in self.ops.removeAll() })
    }
    
}
