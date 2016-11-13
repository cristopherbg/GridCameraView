//
//  CameraCollectionView.swift
//  AVCam Swift
//
//  Created by Cristopher A. Bautista Gómez on 11/13/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraCollectionView: UICollectionViewCell {
        @IBOutlet weak var previewView: PreviewView!
        var session = AVCaptureSession()
        var _setupResult: SessionSetupResult = .success
        var sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
        var _isSessionRunning = false
        var _videoDeviceInput: AVCaptureDeviceInput!
    
    weak var superViewController: UIViewController?
 
    //awakeFromNib, willMoveToSuperView, didMoveToSuperView
    
    func configure(_ parent: UIViewController){
        self.superViewController = parent
        checkCameraAccess ()
        startCameraSession()
    }
}

extension CameraCollectionView : CameraViewConfiguration{
    
    func setupResult () -> SessionSetupResult{
        return _setupResult
    }
    func setupResult (_ value : SessionSetupResult){
        _setupResult = value
    }
    
    func isSessionRunning () -> Bool {
        return _isSessionRunning
    }
    func isSessionRunning (_ value : Bool){
        _isSessionRunning = value
    }
    
    func videoDeviceInput () -> AVCaptureDeviceInput{
        return _videoDeviceInput
    }
    func videoDeviceInput (_ value :AVCaptureDeviceInput){
        _videoDeviceInput = value
    }
    
    var previewVideoView: PreviewView {
        return previewView
    }
    
    func viewController () -> UIViewController?{
        return superViewController
    }
}
