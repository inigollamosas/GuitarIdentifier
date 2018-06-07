//
//  ViewController.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 30/05/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import UIKit

import UIKit
import AVFoundation
import Vision
import CoreML

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Connect InterfaceBuilder views to code
    @IBOutlet weak var cameraView: UIView!
    
    private var requests = [VNRequest]()
    
    // Create a layer to display camera frames in the UIView
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    // Create an AVCaptureSession
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()
    
    private var classifier = ObjectDetector()
    
    var userDefined: [String: String] = [:]
    var labels: [String] = []
    var labelColors: [CGColor] = []
    var nmsThreshold: Float = 0.0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        userDefined = classifier.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey]! as! [String : String]
        labels = userDefined["classes"]!.components(separatedBy: ",")
        for _ in labels{
            labelColors.append(UIColor(red: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                       green: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                       blue: CGFloat(arc4random()) / CGFloat(UInt32.max),
                                       alpha: 1.0).cgColor)
        }
        nmsThreshold = Float(userDefined["non_maximum_suppression_threshold"]!) ?? 0.5
        cameraView?.layer.addSublayer(cameraLayer)
        cameraLayer.frame = cameraView.bounds
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        self.captureSession.startRunning()
        setupVision()
    }
    
    // Gets in once. Initialises the classifier and attaches the handler
    func setupVision() {
        
        guard let visionModel = try? VNCoreMLModel(for: classifier.model) else {
            fatalError("Can’t load VisionML model")
        }
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: vNCoreMLRequestCompletionHandler)
        classificationRequest.imageCropAndScaleOption = .scaleFill
        requests = [classificationRequest]
    }
    
    // Continuously getting the images
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var requestOptions:[VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 6)!, options: requestOptions)
        do {
            // Perfom the object identification request
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }
    
    // Classifier handler. Gets in because on captureOutput() does imageRequestHandler.perform(self.requests), and requests is [nNCoreMLRequest(model: visionModel, completionHandler: VNCoreMLRequestCompletionHandler)]
    func vNCoreMLRequestCompletionHandler(request: VNRequest, error: Error?) {
        
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            fatalError("unexpected result type from VNCoreMLRequest")
        }
        let indentifiedObjects = CameraViewControllerHelper.indentifyLabels(observations: observations, nmsThreshold: nmsThreshold)

        DispatchQueue.main.async {
        self.cameraLayer.sublayers?.removeSubrange(1...)
            for object in indentifiedObjects {
                print(self.labels[object.labelIndex])
                self.cameraLayer.addSublayer(CameraViewControllerHelper.frameObject(object, self.cameraView.frame, self.labelColors[object.labelIndex], self.labels[object.labelIndex]))
            }
        }
    }
}

