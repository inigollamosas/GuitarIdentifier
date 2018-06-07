//
//  MainViewController.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 07/06/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import UIKit
import Foundation

class MainViewController: UIViewController {

    var chosenPhoto = UIImageView()

    @IBAction func videoPressed(_ sender: Any) {
        performSegue(withIdentifier: "showVideo", sender: nil)
    }
    
    @IBAction func photoPressed(_ sender: Any) {
        
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            if let destinationVC = segue.destination as? PhotoViewController {
                destinationVC.photo = chosenPhoto
            }
        }
    }

}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        chosenPhoto.image = info[UIImagePickerControllerOriginalImage] as UIImage
        performSegue(withIdentifier: "showPhoto", sender: nil)
    }
}
