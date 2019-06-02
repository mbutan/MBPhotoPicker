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

public class MBPhotoPicker: NSObject {

  // MARK: Localized strings
  public var alertTitle: String? = "Alert title"

  public var alertMessage: String? = "Alert message"

  public var actionTitleCancel: String = "Action Cancel"

  public var actionTitleTakePhoto: String = "Action take photo"

  public var actionTitleLastPhoto: String = "Action last photo"

  public var actionTitleOther: String = "Action other"

  public var actionTitleLibrary: String = "Action Library"

  // MARK: Photo picker settings
  public var allowDestructive: Bool = false

  public var allowEditing: Bool = false

  public var disableEntitlements: Bool = false

  public var cameraDevice: UIImagePickerControllerCameraDevice = .Rear

  public var cameraFlashMode: UIImagePickerControllerCameraFlashMode = .Auto

  public var resizeImage: CGSize?

  /**
   Using for iPad devices
   */
  public var popoverTarget: UIView?

  public var popoverRect: CGRect?

  public var popoverDirection: UIPopoverArrowDirection = .Any

  /**
   List of callbacks variables
   */
  public var photoCompletionHandler: ((_ image: UIImage) -> Void)?

  public var presentedCompletionHandler: (())?

  public var cancelCompletionHandler: (())?

  public var errorCompletionHandler: ((_ error: ErrorPhotoPicker) -> Void)?

  // MARK: Error's definition
  public enum ErrorPhotoPicker: String {
    case cameraNotAvailable = "Camera not available"
    case libraryNotAvailable = "Library not available"
    case accessDeniedCameraRoll = "Access denied to camera roll"
    case entitlementiCloud = "Missing iCloud Capatability"
    case wrongFileType = "Wrong file type"
    case popoverTarget = "Missing property popoverTarget while iPad is run"
    case other = "Other"
  }

  // MARK: Public
  public func present() {
    let topController = UIApplication.sharedApplication().windows.first?.rootViewController
    present(topController!)
  }

  public func present(_ controller: UIViewController) {
    self.controller = controller

    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .ActionSheet)

    let actionTakePhoto = UIAlertAction(
      title: self.localizeString(actionTitleTakePhoto),
      style: .Default,
      handler: { _ in
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
          self.presentImagePicker(.Camera, topController: controller)
        } else {
          self.errorCompletionHandler?(error: .CameraNotAvailable)
        }
    })

    let actionLibrary = UIAlertAction(
      title: self.localizeString(actionTitleLibrary),
      style: .Default,
      handler: { _ in
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
          self.presentImagePicker(.PhotoLibrary, topController: controller)
        } else {
          self.errorCompletionHandler?(error: .LibraryNotAvailable)
        }
    })

    let actionLast = UIAlertAction(
      title: self.localizeString(actionTitleLastPhoto),
      style: .Default,
      handler: { _ in
        self.lastPhotoTaken({ (image) in self.photoHandler(image) },
                            errorHandler: { (error) in self.errorCompletionHandler?(error: .AccessDeniedCameraRoll) }
        )
    })


    let actionCancel = UIAlertAction(
      title: self.localizeString(actionTitleCancel),
      style: allowDestructive ? .Destructive : .Cancel,
      handler: { _ in
        self.cancelCompletionHandler?()
    })

    alert.addAction(actionTakePhoto)
    alert.addAction(actionLibrary)
    alert.addAction(actionLast)
    alert.addAction(actionCancel)

    if !self.disableEntitlements {
      let actionOther = UIAlertAction(
        title: self.localizeString(actionTitleOther),
        style: .Default,
        handler: { _ in
          let document = UIDocumentMenuViewController(
            documentTypes: [kUTTypeImage as String,
                            kUTTypeJPEG as String,
                            kUTTypePNG as String,
                            kUTTypeBMP as String,
                            kUTTypeTIFF as String],
            inMode: .Import)
          document.delegate = self
          controller.presentViewController(document, animated: true, completion: nil)
      })
      alert.addAction(actionOther)
    }


    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      guard let popover = self.popoverTarget else {
        self.errorCompletionHandler?(error: .PopoverTarget)
        return
      }

      if let presenter = alert.popoverPresentationController {
        alert.modalPresentationStyle = .Popover
        presenter.sourceView = popover
        presenter.permittedArrowDirections = self.popoverDirection

        if let rect = self.popoverRect {
          presenter.sourceRect = rect
        } else {
          presenter.sourceRect = popover.bounds
        }
      }
    }

    controller.presentViewController(alert, animated: true) { () in
      self.presentedCompletionHandler?()
    }
  }

  // MARK: Private
  internal weak var controller: UIViewController?

  var imagePicker: UIImagePickerController!
  func presentImagePicker(sourceType: UIImagePickerControllerSourceType, topController: UIViewController!) {
    imagePicker = UIImagePickerController()
    imagePicker.sourceType = sourceType
    imagePicker.delegate = self
    imagePicker.editing = self.allowEditing
    if sourceType == .Camera {
      imagePicker.cameraDevice = self.cameraDevice
      if UIImagePickerController.isFlashAvailableForCameraDevice(self.cameraDevice) {
        imagePicker.cameraFlashMode = self.cameraFlashMode
      }
    }
    topController.presentViewController(imagePicker, animated: true, completion: nil)
  }

  func photoHandler(_ image: UIImage) {
    let resizedImage: UIImage = UIImage.resizeImage(image, newSize: self.resizeImage)
    self.photoCompletionHandler?(image: resizedImage)
  }

  func localizeString(_ string: String) -> String! {
    let podBundle = NSBundle(forClass: self.classForCoder)
    if let bundleURL = podBundle.URLForResource("MBPhotoPicker", withExtension: "bundle") {
      if let bundle = NSBundle(URL: bundleURL) {
        string = NSLocalizedString(string, tableName: "Localizable", bundle: bundle, value: "", comment: "")

      } else {
        assertionFailure("Could not load the bundle")
      }
    }

    return string!
  }
}

extension MBPhotoPicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true) { () in
      self.cancelCompletionHandler?()
    }
  }

  public func imagePickerController(picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [String: AnyObject]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
      self.photoHandler(image)
    } else {
      self.errorCompletionHandler?(error: .Other)
    }
    picker.dismissViewControllerAnimated(true, completion: nil)
  }

  public func imagePickerController(picker: UIImagePickerController,
                                    didFinishPickingImage image: UIImage,
                                    editingInfo: [String: AnyObject]?) {
    picker.dismissViewControllerAnimated(true, completion: nil)
  }
}

extension MBPhotoPicker: UIDocumentPickerDelegate {
  public func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
    var error: NSError?
    let filerCordinator = NSFileCoordinator()
    filerCordinator.coordinateReadingItemAtURL(url,
                                               options: .WithoutChanges,
                                               error: &error,
                                               byAccessor: { (url: NSURL) in
                                                if let data: NSData = NSData(contentsOfURL: url) {
                                                  if data.isSupportedImageType() {
                                                    if let image: UIImage = UIImage(data: data) {
                                                      self.photoHandler(image)
                                                    } else {
                                                      self.errorCompletionHandler?(error: .Other)
                                                    }
                                                  } else {
                                                    self.errorCompletionHandler?(error: .WrongFileType)
                                                  }
                                                } else {
                                                  self.errorCompletionHandler?(error: .Other)
                                                }
    })
  }

  public func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
    self.cancelCompletionHandler?()
  }
}

extension MBPhotoPicker: UIDocumentMenuDelegate {
  public func documentMenu(documentMenu: UIDocumentMenuViewController,
                           didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
    documentPicker.delegate = self
    self.controller?.presentViewController(documentPicker, animated: true, completion: nil)
  }

  public func documentMenuWasCancelled(documentMenu: UIDocumentMenuViewController) {
    self.cancelCompletionHandler?()
  }
}

extension MBPhotoPicker {
  internal func lastPhotoTaken (completionHandler: (_ image: UIImage?) -> Void,
                                errorHandler: (_ error: NSError?) -> Void) {

    PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
      guard status == PHAuthorizationStatus.Authorized else {
        errorHandler(error: nil)
        return
      }

      let manager = PHImageManager.defaultManager()
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
      let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
      let asset: PHAsset? = fetchResult.lastObject as? PHAsset

      let initialRequestOptions = PHImageRequestOptions()
      initialRequestOptions.synchronous = true
      initialRequestOptions.resizeMode = .Fast
      initialRequestOptions.deliveryMode = .FastFormat

      manager.requestImageDataForAsset(asset!, options: initialRequestOptions) { (data: NSData?, title: String?, orientation: UIImageOrientation, info: [NSObject: AnyObject]?) in
        guard let dataImage = data else {
          errorHandler(error: nil)
          return
        }

        let image: UIImage = UIImage(data: dataImage)!

        dispatch_async(dispatch_get_main_queue(), { () in
          completionHandler(image: image)
        })
      }
    }
  }
}

extension UIImage {
  static public func resizeImage(image: UIImage!, newSize: CGSize?) -> UIImage! {
    guard var size = newSize else { return image }

    let widthRatio = size.width/image.size.width
    let heightRatio = size.height/image.size.height

    let ratio = min(widthRatio, heightRatio)
    size = CGSize(image.size.width*ratio, image.size.height*ratio)

    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
    image.drawInRect(CGRect(origin: .zero, size: size))

    let scaledImage: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return scaledImage
  }
}

extension NSData {
  public func isSupportedImageType() -> Bool {
    var bytes = [UInt32](count: 1, repeatedValue: 0)
    self.getBytes(&bytes, length: 1)
    switch (bytes[0]) {
    case 0xFF, 0x89, 0x00, 0x4D, 0x49, 0x47, 0x42:
      return true
    default:
      return false
    }
  }
}
