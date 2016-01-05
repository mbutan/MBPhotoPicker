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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var photo: MBPhotoPicker?
    @IBAction func didTapPhotoPicker(sender: AnyObject) {
        photo = MBPhotoPicker()
        photo?.disableEntitlements = false // If you don't want use iCloud entitlement just set this value True
        photo?.alertTitle = nil
        photo?.alertMessage = nil
        photo?.resizeImage = CGSizeMake(250, 150)
        photo?.allowDestructive = false
        photo?.allowEditing = false
        photo?.cameraDevice = .Rear
        photo?.cameraFlashMode = .Auto
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            photo?.popoverTarget = self.photoButton!
            photo?.popoverDirection = .Up
            photo?.popoverRect = self.photoButton.bounds // It's also default value
        }
        
        photo?.photoCompletionHandler = { (image: UIImage!) -> Void in
            self.previewImageView.image = image;
        }
        photo?.cancelCompletionHandler = {
            print("Cancel Pressed")
        }
        photo?.errorCompletionHandler = { (error: MBPhotoPicker.ErrorPhotoPicker!) -> Void in
            print("Error: \(error.rawValue)")
        }
        photo?.present(self)
    }
    
}

