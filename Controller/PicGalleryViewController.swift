//
//  PicGalleryViewController.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 10/15/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//

import UIKit
import CoreData
import MapKit

private let reuseIdentifier = "PhotoCell"

class PicGalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate  {
    
    
    // Location object for which Flickr images are displayed in collection view
    
    
    var location:Location!
    var photoData:[Photo] = [Photo]()
    var selectedIndexPaths = [NSIndexPath]()
    var photosSelected = false
    var currentPage = 0
    
    // Track index paths for Selection, Insertion, Update and Deletion of images
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // Datatask to fetch images for new collection
    var dataTask: URLSessionDataTask?
    
   @IBOutlet weak var photoCollectionView: UICollectionView!
    
    
    @IBOutlet weak var layout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var locationMapView: MKMapView!
    
    @IBOutlet weak var newPhotoCollection: UIButton!
    
    
    //MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        locationMapView.delegate = self
        // Register cell classes
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        addSelectedAnnotation()
        print("selected pin location: \(location)")
        
        fetchPhotos()
        
    }
    
    //Mark: Show Selected Pin on MapView
    func addSelectedAnnotation(){
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(location.latitude)
        let lon = CLLocationDegrees(location.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        
        //zoom into an appropriate region
        let span = MKCoordinateSpanMake(0.25, 0.25)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        DispatchQueue.main.async() {
            self.locationMapView.addAnnotation(annotation)
            self.locationMapView.setRegion(region, animated: true)
        }
    }
    
    //Layout collection view
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width, with space
        let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(photoCollectionView.frame.width / 3)
        layout.itemSize = CGSize(width: width, height: width)
        photoCollectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        let index = selectedIndexPaths.index(of: indexPath as NSIndexPath)
        
        if let index = index {
            selectedIndexPaths.remove(at: index)
            cell.photoImage.alpha = 1.0
        } else {
            selectedIndexPaths.append(indexPath as NSIndexPath)
            print(selectedIndexPaths)
            selectedIndexPaths.sort{$1.row < $0.row}
            print("Selected IndexPaths: \(selectedIndexPaths)")
            
            cell.photoImage.alpha = 0.25
        }
        
        if selectedIndexPaths.count > 0 {
            newPhotoCollection.setTitle("Delete", for: .normal)
            photosSelected = true
        } else {
            newPhotoCollection.setTitle("New Collection", for: .normal)
            photosSelected = false
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cellPhoto = collectionView.dequeueReusableCell(withReuseIdentifier:"photoCell", for: indexPath) as! PhotoCell
        configureCell(cell: cellPhoto, atIndexPath: indexPath as NSIndexPath)
        
        return cellPhoto
    }
    
    // This method will download the image and display as soon  as the imgae is downloaded
    func configureCell(cell:PhotoCell, atIndexPath indexPath:NSIndexPath) {
        
        // Show the placeholder image untill the time image is being downloaded
        if cell != nil {
            //print("\(cell)")
        }
        
        let photo = photoData[indexPath.row]
        
        var cellImage = UIImage(named: "imagePlaceholder")
      
        cell.photoImage.image = nil
  
        cell.photoDownloadActivityIndicator.startAnimating()
        
        // Set the flickr image if already available (from hard disk or image cache)
        if photo.imageData != nil {
            DispatchQueue.main.async() {
                cell.photoDownloadActivityIndicator.stopAnimating()
            }
            cell.photoImage.image = UIImage(data: photo.imageData as! Data)
        } else {
            
            FlickrClient.sharedInstance().taskForImage(filePath: photo.imageUrl!) { (results, error) in
                
                guard let imageData = results else {
                    self.displayAlert(title: "Image data error", message: "error")
                    return
                }
                
                DispatchQueue.main.async(){
                    photo.imageData = imageData as NSData?
                    cell.photoDownloadActivityIndicator.stopAnimating()
                    cell.photoImage.image = UIImage(data: photo.imageData as! Data)
                }
                
            }        }
        if selectedIndexPaths.index(of: indexPath as NSIndexPath) != nil {
            cell.photoImage.alpha = 0.25
        }else {
            cell.photoImage.alpha = 1.0
        }
    }
    
    //MARK:- Core Data
    
    func fetchPhotos(){
        
        //MARK: Fetch Request
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest() as! NSFetchRequest<Photo>
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "location = %@", self.location)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStackManager.getContext(), sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        if let data = fetchedResultsController.fetchedObjects, data.count > 0 {
            print("\(data.count) photos from core data fetched.")
            photoData = data
            self.photoCollectionView.reloadData()
        } else {
            getPhotosFromFlickr(currentPageNumber:currentPage)
        }
    }
    
    @IBAction func getNewCollections(_ sender: Any) {
        if photosSelected {
            removeSelectedPhotos()
            self.photoCollectionView.reloadData()
            photosSelected = false
            newPhotoCollection.setTitle("New Collection", for: .normal)
        } else {
            for photo in photoData {
                CoreDataStackManager.getContext().delete(photo)
            }
            CoreDataStackManager.saveContext()
            currentPage += 1
            getPhotosFromFlickr(currentPageNumber: currentPage)
            
        }
    }
    
    func removeSelectedPhotos() {
        if selectedIndexPaths.count > 0 {
            for indexPath in selectedIndexPaths {
                let photo = photoData[indexPath.row]
                CoreDataStackManager.getContext().delete(photo)
                self.photoData.remove(at: indexPath.row)
                self.photoCollectionView.deleteItems(at: [indexPath as IndexPath])
                print("photo at row \(indexPath.row) deleted")
            }
            CoreDataStackManager.saveContext()
        }
        selectedIndexPaths = [NSIndexPath]()
    }
    
    func getPhotosFromFlickr(currentPageNumber: Int) {
        
        FlickrClient.sharedInstance().getImagesFromFlickr(location,currentPage) { (results, error) in
            
            guard error == nil else {
                self.displayAlert(title: "Could not get photos from flickr", message: error?.localizedDescription)
                return
            }
            
            DispatchQueue.main.async() {
                if results != nil {
                    self.photoData = results!
                    
                    print("\(self.photoData.count) photos from flickr fetched")
                    self.photoCollectionView.reloadData()
                }
            }
        }
    }
    
    // Alert
    func displayAlert(title:String, message:String?) {
        
        if let message = message {
            let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    
}


