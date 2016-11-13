//
//  CameraViewController.swift
//  GridCameraView
//
//  Created by Cristopher A. Bautista Gómez on 11/13/16.
//  Copyright © 2016 Cristopher A. Bautista Gómez. All rights reserved.
//


import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet weak fileprivate var collectionView: UICollectionView!
    @IBOutlet weak fileprivate var collectionViewLayout: UICollectionViewFlowLayout!
    @IBOutlet weak fileprivate var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak fileprivate var currentImage: UIImageView!
    
    var picker:UIImagePickerController = UIImagePickerController()
    var tagPickerView:UIPickerView! = UIPickerView()
    
    fileprivate var assets: PHFetchResult<PHAsset>?
    let allPhotosOptions = PHFetchOptions()
    
    fileprivate var sideSize: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        picker.allowsEditing = true
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    //MARK: - Lifecycle
    class func loadFromStoryboard() -> CameraViewController! {
        let _storyboard = UIStoryboard(name: "Picker", bundle: Bundle.main)
        return _storyboard.instantiateViewController(withIdentifier: "ImagePickerVC") as! CameraViewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sideSize = collectionView.bounds.width  / 4
        collectionViewLayout.itemSize = CGSize(width: sideSize, height: sideSize)
        collectionViewLayout.minimumLineSpacing = 0
        collectionViewLayout.minimumInteritemSpacing = 0
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.reloadAssets()
        } else {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                if status == .authorized {
                    self.reloadAssets()
                } else {
                    self.showNeedAccessMessage()
                }
            })
        }
    }
    //MARK: - Functions
    fileprivate func showNeedAccessMessage() {
        let alert = UIAlertController(title: "Image picker", message: "App need get access to photos", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }))
        
        show(alert, sender: nil)
    }
    fileprivate func reloadAssets() {
        self.reloadAssets(photosAssets: nil)
    }
    fileprivate func reloadAssets(photosAssets : PHFetchResult<PHAsset>?) {
        var photosAssetsLocal = photosAssets
        activityIndicator.startAnimating()
        if photosAssetsLocal == nil{
            photosAssetsLocal = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: allPhotosOptions)
        }
        assets = photosAssetsLocal
        collectionView.reloadData()
        activityIndicator.stopAnimating()
    }
    
}

//MARK: - UICollectionViewDataSource
extension CameraViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (assets != nil) ? assets!.count + 1 : 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0{
            let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCollectionView", for: indexPath) as! CameraCollectionView
            myCell.configure(self)
            return myCell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickerCell", for: indexPath)
        }
    }
}

extension CameraViewController : PHPhotoLibraryChangeObserver{
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            if assets != nil {
                if let changeDetails = changeInstance.changeDetails(for: assets!) {
                    // Update the cached fetch result.
                    reloadAssets( photosAssets: changeDetails.fetchResultAfterChanges)
                }
            }else{
                self.reloadAssets()
            }
        }
    }
}

//MARK: - UICollectionViewDelegate
extension CameraViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == 0{
            let myCell = cell as! CameraCollectionView
            myCell.startVideoView()
        }else{
            PHImageManager.default().requestImage(for: (assets?[indexPath.row - 1])!, targetSize: CGSize(width: sideSize, height: sideSize), contentMode: .aspectFill, options: nil) { (image: UIImage?, info: [AnyHashable: Any]?) -> Void in
                (cell as! ImagePickerCell).image = image
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0{
            openCamera()
        }
        else{
            selectAsset(atPosition: indexPath.row - 1)
        }
    }
    
    func selectAsset(atPosition : Int){
        if (assets?.count)! > 0 {
            let width = self.view.bounds.width
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            
            PHImageManager.default().requestImage(for: (assets?[atPosition])!, targetSize: CGSize(width: width, height: width), contentMode: .aspectFill, options: options) { (image: UIImage?, info: [AnyHashable: Any]?) -> Void in
                if let _image = image {
                    self.currentImage.image = _image
                }
            }
        }
    }
}

//MARK: - ImagePicker
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
            present(self.picker, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "Camera", message: "Cant't access to camera", preferredStyle: .alert)
            show(alert, sender: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {
            // Add it to the photo library.
            let image = info[UIImagePickerControllerEditedImage] as? UIImage
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
            }, completionHandler: {success, error in
                if !success { print("error creating asset: \(error)") }
            })
            self.currentImage.image = image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
