//
//  ImageClassifierViewModel.swift
//  ImageClassifier
//
//  Created by Satvik  Jadhav on 4/4/25.
//

import Foundation
import CoreML
import Vision
import UIKit

// Enum to define available ML models
enum MLModelType: String, CaseIterable {
    case mobileNetV2 = "MobileNetV2"
    case resNet50 = "ResNet50"
}

class ImageClassifierViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var classificationResults: [MLModelType: String] = [:]
    @Published var isLoading: Bool = false
    @Published var currentModelType: MLModelType = .mobileNetV2
    @Published var compareModels: Bool = false
    
    // Private properties for Core ML models
    private var mobileNetModel: VNCoreMLModel
    private var resNetModel: VNCoreMLModel
    
    init() {
        do {
            let configuration = MLModelConfiguration()
            // Load MobileNetV2
            let mobileNet = try MobileNetV2(configuration: configuration).model
            self.mobileNetModel = try VNCoreMLModel(for: mobileNet)
            // Load ResNet50
            let resNet = try ResNet50(configuration: configuration).model
            self.resNetModel = try VNCoreMLModel(for: resNet)
        } catch {
            fatalError("Failed to load ML models: \(error)")
        }
    }
    
    func classifyImage(_ image: UIImage) {
        isLoading = true
        classificationResults = [:]
        
        // Determine which models to use
        let modelsToUse: [MLModelType] = compareModels ? MLModelType.allCases : [currentModelType]
        
        for modelType in modelsToUse {
            let model = modelType == .mobileNetV2 ? mobileNetModel : resNetModel
            
            let request = VNCoreMLRequest(model: model) { request, error in
                DispatchQueue.main.async {
                    if let results = request.results as? [VNClassificationObservation],
                       let topResult = results.first {
                        self.classificationResults[modelType] = "\(topResult.identifier) (\(Int(topResult.confidence * 100))%)"
                    } else {
                        self.classificationResults[modelType] = "Classification failed"
                    }
                    // Turn off loading when all models are done
                    if self.classificationResults.count == modelsToUse.count {
                        self.isLoading = false
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    DispatchQueue.main.async {
                        self.classificationResults[modelType] = "Classification failed: \(error)"
                        if self.classificationResults.count == modelsToUse.count {
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
}
