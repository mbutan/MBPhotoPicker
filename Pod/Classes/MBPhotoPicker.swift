//
//  MBPhotoPicker.swift
//  MBPhotoPicker
//
//  Created by Marcin Butanowicz on 02/01/16.
//  Copyright © 2016 MBSSoftware. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

open class MBPhotoPicker: NSObject {
    
    // MARK: Localized strings
    open var alertTitle: String? = "Alert title"
    
    open var alertMessage: String? = "Alert message"
    
    open var actionTitleCancel: String = "Action Cancel"
    
    open var actionTitleTakePhoto: String = "Action take photo"
    
    open var actionTitleLastPhoto: String = "Action last photo"
    
    open var actionTitleOther: String = "Action other"
    
    open var actionTitleLibrary: String = "Action Library"
    
    
    // MARK: Photo picker settings
    open var allowDestructive: Bool = false
    
    open var allowEditing: Bool = false
    
    open var disableEntitlements: Bool = false
    
    open var cameraDevice: UIImagePickerControllerCameraDevice = .rear
    
    open var cameraFlashMode: UIImagePickerControllerCameraFlashMode = .auto
    
    open var resizeImage: CGSize?
    
    /**
     Using for iPad devices
     */
    open var presentPhotoLibraryInPopover = false
    
    open var popoverTarget: UIView?
    
    open var popoverRect: CGRect?
    
    open var popoverDirection: UIPopoverArrowDirection = .any
    
    var popoverController: UIPopoverController?
    
    /**
     List of callbacks variables
     */
    open var photoCompletionHandler: ((_ image: UIImage?) -> Void)?
    
    open var presentedCompletionHandler: (() -> Void)?
    
    open var cancelCompletionHandler: (() -> Void)?
    
    open var errorCompletionHandler: ((_ error: ErrorPhotoPicker) -> Void)?
    

    // MARK: Error's definition
    public enum ErrorPhotoPicker: String {
        case CameraNotAvailable = "Camera not available"
        case LibraryNotAvailable = "Library not available"
        case AccessDeniedCameraRoll = "Access denied to camera roll"
        case EntitlementiCloud = "Missing iCloud Capatability"
        case WrongFileType = "Wrong file type"
        case PopoverTarget = "Missing property popoverTarget while iPad is run"
        case Other = "Other"
    }
    

    // MARK: Public
    open func present() -> Void {
        let topController = UIApplication.shared.windows.first?.rootViewController
        present(topController!)
    }
    
    open func present(_ controller: UIViewController!) -> Void {
        self.controller = controller
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)
        
        let actionTakePhoto = UIAlertAction(title: self.localizeString(actionTitleTakePhoto), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.presentImagePicker(.camera, topController: controller)
            } else {
                self.errorCompletionHandler?(.CameraNotAvailable)
            }
        })
        
        let actionLibrary = UIAlertAction(title: self.localizeString(actionTitleLibrary), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                self.presentImagePicker(.photoLibrary, topController: controller)
            } else {
                self.errorCompletionHandler?(.LibraryNotAvailable)
            }
        })
        
        let actionLast = UIAlertAction(title: self.localizeString(actionTitleLastPhoto), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.lastPhotoTaken({ (image) -> Void in self.photoHandler(image) },
                errorHandler: { (error) -> Void in self.errorCompletionHandler?(.AccessDeniedCameraRoll) }
            )
        })
        
        
        let actionCancel = UIAlertAction(title: self.localizeString(actionTitleCancel), style: allowDestructive ? .destructive : .cancel, handler: { (alert: UIAlertAction!) -> Void in
            self.cancelCompletionHandler?()
        })
        
        alert.addAction(actionTakePhoto)
        alert.addAction(actionLibrary)
        alert.addAction(actionLast)
        alert.addAction(actionCancel)
        
        if !self.disableEntitlements {
            let actionOther = UIAlertAction(title: self.localizeString(actionTitleOther), style: .default, handler: { (alert: UIAlertAction!) -> Void in
                let document = UIDocumentMenuViewController(documentTypes: [kUTTypeImage as String, kUTTypeJPEG as String, kUTTypePNG as String, kUTTypeBMP as String, kUTTypeTIFF as String], in: .import)
                document.delegate = self
                controller.present(document, animated: true, completion: nil)
            })
            alert.addAction(actionOther)
        }
        
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let popover = self.popoverTarget else {
                self.errorCompletionHandler?(.PopoverTarget)
                return;
            }
            
            if let presenter = alert.popoverPresentationController {
                alert.modalPresentationStyle = .popover
                presenter.sourceView = popover;
                presenter.permittedArrowDirections = self.popoverDirection
                
                if let rect = self.popoverRect {
                    presenter.sourceRect = rect
                } else {
                    presenter.sourceRect = popover.bounds
                }
            }
        }
        
        controller.present(alert, animated: true) { () -> Void in
            self.presentedCompletionHandler?()
        }
    }
    
    // MARK: Private
    internal weak var controller: UIViewController?
    
    var imagePicker: UIImagePickerController!
    func presentImagePicker(_ sourceType: UIImagePickerControllerSourceType, topController: UIViewController!) {
        imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        imagePicker.isEditing = self.allowEditing
        if sourceType == .camera {
            imagePicker.cameraDevice = self.cameraDevice
            if UIImagePickerController.isFlashAvailable(for: self.cameraDevice) {
                imagePicker.cameraFlashMode = self.cameraFlashMode
            }
        }
        if UIDevice.current.userInterfaceIdiom == .pad && sourceType == .photoLibrary && self.presentPhotoLibraryInPopover {
            guard let popover = self.popoverTarget else {
                self.errorCompletionHandler?(.PopoverTarget)
                return;
            }
            
            self.popoverController = UIPopoverController(contentViewController: imagePicker)
            let rect = self.popoverRect ?? CGRect.zero
            self.popoverController?.present(from: rect, in: popover, permittedArrowDirections: self.popoverDirection, animated: true)
        } else {
            topController.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func photoHandler(_ image: UIImage!) -> Void {
        let resizedImage: UIImage = UIImage.resizeImage(image, newSize: self.resizeImage)
        self.photoCompletionHandler?(resizedImage)
    }
    
    func localizeString(_ string: String!) -> String! {
        var string = string
        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: "MBPhotoPicker", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                string = NSLocalizedString(string!, tableName: "Localizable", bundle: bundle, value: "", comment: "")
                
            } else {
                assertionFailure("Could not load the bundle")
            }
        }
        
        return string!
    }
}

extension MBPhotoPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { () -> Void in
            self.cancelCompletionHandler?()
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] {
            self.photoHandler(image as! UIImage)
        } else {
            self.errorCompletionHandler?(.Other)
        }
        picker.dismiss(animated: true, completion: nil)
        self.popoverController = nil
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismiss(animated: true, completion: nil)
        self.popoverController = nil
    }
}

extension MBPhotoPicker: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        var error: NSError?
        let filerCordinator = NSFileCoordinator()
        filerCordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error, byAccessor: { (url: URL) -> Void in
            if let data: Data = try? Data(contentsOf: url) {
                if data.isSupportedImageType() {
                    if let image: UIImage = UIImage(data: data) {
                        self.photoHandler(image)
                    } else {
                        self.errorCompletionHandler?(.Other)
                    }
                } else {
                    self.errorCompletionHandler?(.WrongFileType)
                }
            } else {
                self.errorCompletionHandler?(.Other)
            }
        })
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.cancelCompletionHandler?()
    }
}

extension MBPhotoPicker: UIDocumentMenuDelegate {
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        self.controller?.present(documentPicker, animated: true, completion: nil)
    }
    
    public func documentMenuWasCancelled(_ documentMenu: UIDocumentMenuViewController) {
        self.cancelCompletionHandler?()
    }
}


extension MBPhotoPicker {
    internal func lastPhotoTaken (_ completionHandler: @escaping (_ image: UIImage?) -> Void, errorHandler: @escaping (_ error: NSError?) -> Void) {
        
        PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) -> Void in
            if (status == PHAuthorizationStatus.authorized) {
                let manager = PHImageManager.default()
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
                let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
                let asset: PHAsset? = fetchResult.lastObject
                
                let initialRequestOptions = PHImageRequestOptions()
                initialRequestOptions.isSynchronous = true
                initialRequestOptions.resizeMode = .fast
                initialRequestOptions.deliveryMode = .fastFormat
                
                manager.requestImageData(for: asset!, options: initialRequestOptions) { (data: Data?, title: String?, orientation: UIImageOrientation, info: [AnyHashable: Any]?) -> Void in
                    guard let dataImage = data else {
                        errorHandler(nil)
                        return
                    }
                    
                    let image:UIImage = UIImage(data: dataImage)!
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        completionHandler(image)
                    })
                }
            } else {
                errorHandler(nil)
            }
        }
    }
}

extension UIImage {
    static public func resizeImage(_ image: UIImage!, newSize: CGSize?) -> UIImage! {
        guard var size = newSize else { return image }
        
        let widthRatio = size.width/image.size.width
        let heightRatio = size.height/image.size.height
        
        let ratio = min(widthRatio, heightRatio)
        size = CGSize(width: image.size.width*ratio, height: image.size.height*ratio)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        
        let scaledImage: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}

extension Data {
    public func isSupportedImageType() -> Bool {
        var c = [UInt32](repeating: 0, count: 1)
        (self as NSData).getBytes(&c, length: 1)
        switch (c[0]) {
        case 0xFF, 0x89, 0x00, 0x4D, 0x49, 0x47, 0x42:
            return true
        default: 
            return false
        }
    }
}

