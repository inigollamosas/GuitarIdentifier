//
//  PhotoViewController.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 07/06/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import Foundation
import UIKit

class PhotoViewController: UIViewController {
    
    var photo: UIImageView?
    
    override func viewDidLoad() {
        if let p = photo{
            p.frame = self.view.frame
            self.view.addSubview(p)
        }
    }
}
