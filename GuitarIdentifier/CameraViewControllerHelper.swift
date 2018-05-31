//
//  CameraViewControllerHelper.swift
//  GuitarIdentifier
//
//  Created by Iñigo on 30/05/2018.
//  Copyright © 2018 Iñigo. All rights reserved.
//

import UIKit
import Vision

class CameraViewControllerHelper{
    
    
    struct Prediction {
        let labelIndex: Int
        let confidence: Float
        let boundingBox: CGRect
    }
    
    // Intersection over union. It calculates the degree of intersection between 2 rectangles. It is a value between 0% (no overlap) and 100% (perfect overlap). Generally, the smaller the better
    static func IoU(_ a: CGRect, _ b: CGRect) -> Float {
        
        let intersection = a.intersection(b)
        let union = a.union(b)
        return Float((intersection.width * intersection.height) / (union.width * union.height))
    }
    
    // Draws the border and the label for the indentified element
    static func frameObject(_ prediction: Prediction, _ source: CGRect, _ color: CGColor, _ label: String) -> CALayer {
        
        let rectWidth = source.size.width * prediction.boundingBox.size.width
        let rectHeight = source.size.height * prediction.boundingBox.size.height
        let outline = CATextLayer()
        outline.string = label
        outline.frame = CGRect(x: prediction.boundingBox.origin.x * source.size.width, y:prediction.boundingBox.origin.y * source.size.height, width: rectWidth, height: rectHeight)
        outline.borderWidth = 2.0
        outline.borderColor = color
        return outline
    }
    
    // getPredictions
    static func indentifyLabels(observations: [VNCoreMLFeatureValueObservation], nmsThreshold: Float = 0.5) -> [Prediction] {
        
        if observations.count == 0 {
            return []
        }
        
        let coordinates = observations[0].featureValue.multiArrayValue!
        let confidence = observations[1].featureValue.multiArrayValue!
        
        let confidenceThreshold = 0.25
        var unorderedPredictions = [Prediction]()
        let numBoundingBoxes = confidence.shape[0].intValue
        let numClasses = confidence.shape[1].intValue
        let confidencePointer = UnsafeMutablePointer<Double>(OpaquePointer(confidence.dataPointer))
        let coordinatesPointer = UnsafeMutablePointer<Double>(OpaquePointer(coordinates.dataPointer))
        // for every identified box
        for b in 0..<numBoundingBoxes {
            var maxConfidence = 0.0
            var maxIndex = 0
            // we only want one (the best) identified class
            for c in 0..<numClasses {
                let conf = confidencePointer[b * numClasses + c]
                if conf > maxConfidence {
                    maxConfidence = conf
                    maxIndex = c
                }
            }
            // if its good enough, we keep it
            if maxConfidence > confidenceThreshold {
                let x = coordinatesPointer[b * 4]
                let y = coordinatesPointer[b * 4 + 1]
                let w = coordinatesPointer[b * 4 + 2]
                let h = coordinatesPointer[b * 4 + 3]
                
                let rect = CGRect(x: CGFloat(x - w/2), y: CGFloat(y - h/2),
                                  width: CGFloat(w), height: CGFloat(h))
                
                let prediction = Prediction(labelIndex: maxIndex,
                                            confidence: Float(maxConfidence),
                                            boundingBox: rect)
                unorderedPredictions.append(prediction)
            }
        }
        return filterPredictions(unorderedPredictions: unorderedPredictions, nmsThreshold: nmsThreshold)
    }
    
    
    // Filter out the predictions that are intersecting
    static func filterPredictions(unorderedPredictions: [Prediction], nmsThreshold: Float) -> [Prediction]{
        
        var predictions: [Prediction] = []
        let orderedPredictions = unorderedPredictions.sorted { $0.confidence > $1.confidence }
        var keep = [Bool](repeating: true, count: orderedPredictions.count)
        for i in 0..<orderedPredictions.count {
            if keep[i] {
                predictions.append(orderedPredictions[i])
                let bbox1 = orderedPredictions[i].boundingBox
                for j in (i+1)..<orderedPredictions.count {
                    if keep[j] {
                        let bbox2 = orderedPredictions[j].boundingBox
                        if CameraViewControllerHelper.IoU(bbox1, bbox2) > nmsThreshold {
                            keep[j] = false
                        }
                    }
                }
            }
        }
        return predictions
    }
}
