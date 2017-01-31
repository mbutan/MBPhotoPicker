//
//  ViewController.swift
//  PhotoPicker
//
//  Created by Marcin Butanowicz on 01/03/2016.
//  Copyright (c) 2016 Marcin Butanowicz. All rights reserved.
//

import UIKit
import MBPhotoPicker

class ViewController: UIViewController {
    
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var previewImageView: UIImageView!
    lazy var photo = MBPhotoPicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initial setup
        photo.disableEntitlements = false // If you don't want use iCloud entitlement just set this value True
        photo.alertTitle = nil
        photo.alertMessage = nil
        photo.resizeImage = CGSize(width: 250, height: 150)
        photo.allowDestructive = false
        photo.allowEditing = false
        photo.cameraDevice = .rear
        photo.cameraFlashMode = .auto
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            photo.popoverTarget = self.photoButton!
            photo.popoverDirection = .up
            photo.popoverRect = self.photoButton.bounds // It's also default value
        }
        
        photo.photoCompletionHandler = { (image: UIImage?) -> Void in
            self.previewImageView.image = image;
        }
        photo.cancelCompletionHandler = {
            print("Cancel Pressed")
        }
        photo.errorCompletionHandler = { (error: MBPhotoPicker.ErrorPhotoPicker) in
            print("Error: \(error.rawValue)")
        }
    }
    
    @IBAction func didTapPhotoPicker(_ sender: AnyObject) {
        photo.present(self)
    }
    
}

