//
//  CapturedPhotoViewController.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 08/06/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import Foundation
import UIKit
import CoreML
import Vision
import ImageIO

class CapturedPhotoViewController: UIViewController{

    @IBOutlet weak var capturedPhoto: UIImageView!
    @IBOutlet weak var categoriesView: UIView!
    @IBOutlet weak var categoriesLabel: UILabel!
    
    var categories: [String: Float] = [:]
    var photo: UIImage? {
        didSet{
            updateClassifications(for: photo!)
        }
    }
    
    override func viewDidLoad() {

        capturedPhoto.image = photo
        capturedPhoto.contentMode = .scaleToFill
        categoriesView.layer.cornerRadius = 10
    }

    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func updateClassifications(for image: UIImage) {
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: GuitarClassifier().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.categoriesLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            let classifications = results as! [VNClassificationObservation]
            if classifications.isEmpty {
                self.categoriesLabel.text = "Nothing recognized."
            } else {
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    return String("\(classification.identifier) (\(classification.confidence * 100)%)")
                }
                self.categoriesLabel.text = descriptions.joined(separator: "\n")
            }
        }
    }
}
