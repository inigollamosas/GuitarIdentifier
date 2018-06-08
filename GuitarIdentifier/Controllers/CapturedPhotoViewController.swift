//
//  CapturedPhotoViewController.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 08/06/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import Foundation
import UIKit

class CapturedPhotoViewController: UIViewController{

    @IBOutlet weak var capturedPhoto: UIImageView!
    
    var photo: UIImage?
    
    override func viewDidLoad() {
        capturedPhoto.image = photo
    }
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
