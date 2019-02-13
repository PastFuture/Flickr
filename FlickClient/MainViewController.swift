//
//  MainViewController.swift
//  FlickClient
//
//  Created by Arthur on 10.02.2019.
//  Copyright © 2019 Arthur. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MBProgressHUD


class MainViewController: UIViewController {

    var photos: [Photo] = []
    var layoutType: LayoutType = .grid
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFlickrPhotos()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let photoViewController = segue.destination as? PhotoViewController,
            let indexPath = collectionView.indexPathsForSelectedItems?.first {
                photoViewController.photo = photos[indexPath.row]
            }
           
        
    }
    
    @IBAction func segmentedControlChanged(_ sender: UISegmentedControl){
        self.layoutType = LayoutType(rawValue: sender.selectedSegmentIndex) ?? .grid
        collectionView.reloadData()
        
    }

}
// MARK: - Collection View
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        let photo = photos[indexPath.row]
        cell.imageURL = layoutType == .grid ? photo.smallIMageURL : photo.bigIMageURL
        
        return cell
        
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = UICollectionReusableView()
        
        if kind == UICollectionView.elementKindSectionHeader{
            reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SearchHeader", for: indexPath)
        }
        
        return reusableView
    }
    
}
// MARK: - Flow layout
extension MainViewController: UICollectionViewDelegateFlowLayout {
    enum LayoutType: Int{
        case grid
        case list
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if layoutType == .grid {
            let itemWidth = collectionView.bounds.width / 3
            
            return CGSize(width: itemWidth, height: itemWidth)
        } else {
            return CGSize(width: collectionView.bounds.width,
                   height: 200)
        }
        
        
    }
    
    
}

extension MainViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        getFlickrPhotos(searchText: searchBar.text)
    }
    
}

// MARK: - Networking
extension MainViewController{
    func getFlickrPhotos(searchText: String? = nil){
        MBProgressHUD.showAdded(to: view , animated: true)
        
        fetchFlickrPhotos(searchText: searchText) { [weak self](photos) in
            guard let strongSelf = self else {return}
            MBProgressHUD.hide(for: strongSelf.view, animated: true)
            if let photos = photos{
                strongSelf.photos = photos
                strongSelf.collectionView.reloadData()
            }
        }
    }
    
    func fetchFlickrPhotos(searchText: String? = nil, completion: (([Photo]?) -> Void)? = nil){
    let url = URL(string: "https://api.flickr.com/services/rest/")!
    var parameters = [
        "method": "flickr.interestingness.getList",
        "api_key": "86997f23273f5a518b027e2c8c019b0f",
        "sort": "relevance",
        "per_page": "30",
        "format": "json",
        "nojsoncallback": "1",
        "extras": "url_q,url_z"
        ]
        
        if let searchText = searchText{
            parameters["method"] = "flickr.photos.search"
            parameters["text"] = searchText
        }
        
        Alamofire.request(url, method: .get, parameters: parameters).validate().responseData { (response) in
            switch response.result{
            case .success:
                guard let data = response.data, let json = try? JSON(data: data) else {
                    print("Error while parsing Flickr response")
                    completion?(nil)
                    return
                }
                
                let photosJSON = json["photos"]["photo"]
                let photos = photosJSON.arrayValue.flatMap  { Photo(json: $0) }
                
                
                
                completion?(photos)
                
            case .failure(let error):
                print("Error while fetching photos: \(error.localizedDescription)")
                completion?(nil)
            }
        }
    }
}
