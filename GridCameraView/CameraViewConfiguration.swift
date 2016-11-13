//
//  CameraViewConfiguration.swift
//  AVCam Swift
//
//  Created by Cristopher Adan Bautista Gomez on 11/11/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

protocol CameraViewConfiguration{
    var session : AVCaptureSession {get set}
    var sessionQueue : DispatchQueue  {get set}
    var previewVideoView: PreviewView { get }
    
    // Mutable Properties
    func setupResult () -> SessionSetupResult
    func setupResult (_ : SessionSetupResult)
    
    func isSessionRunning () -> Bool
    func isSessionRunning (_ : Bool)
    
    func videoDeviceInput () -> AVCaptureDeviceInput
    func videoDeviceInput (_ :AVCaptureDeviceInput)
    
    func viewController () -> UIViewController?
}

// MARK: Session Management
enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

extension CameraViewConfiguration where Self: UICollectionViewCell {
    
    func checkCameraAccess (){
        //initVariables()
        previewVideoView.session = session
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
                if !granted {
                    self.setupResult(.notAuthorized)
                }
                self.sessionQueue.resume()
            })
            
        default:
            setupResult(.notAuthorized)
        }
    }
    
    func startCameraSession (){
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    func startVideoView (){
        sessionQueue.async {
            switch self.setupResult() {
            case .success:
                self.session.startRunning()
                self.isSessionRunning(self.session.isRunning)
                
            case .notAuthorized:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                    }))
                    
                    self.viewController()?.present(alertController, animated: true, completion: nil)
                }
                
            case .configurationFailed:
                DispatchQueue.main.async { [unowned self] in
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    
//                    self.viewController()?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func stopVideoView(){
        sessionQueue.async { [unowned self] in
            if self.setupResult() == .success {
                self.session.stopRunning()
                self.isSessionRunning(self.session.isRunning)
            }
        }
    }
    
    // Call this on the session queue.
    func configureSession() {
        if setupResult() != .success {
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput(videoDeviceInput)
            }
            else {
                print("Could not add video device input to the session")
                setupResult(.configurationFailed)
                session.commitConfiguration()
                return
            }
        }
        catch {
            print("Could not create video device input: \(error)")
            setupResult(.configurationFailed)
            session.commitConfiguration()
            return
        }
        session.commitConfiguration()
    }
}
