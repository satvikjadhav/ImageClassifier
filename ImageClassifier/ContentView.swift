//
//  ContentView.swift
//  ImageClassifier
//
//  Created by Satvik  Jadhav on 4/4/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var viewModel = ImageClassifierViewModel()
    @State private var showBiasAlert = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // App title
                Text("Image Classifier")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top)
                
                // Model selection picker
                Picker("Model", selection: $viewModel.currentModelType) {
                    ForEach(MLModelType.allCases, id: \.self) { modelType in
                        Text(modelType.rawValue).tag(modelType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Compare models toggle
                Toggle("Compare Models", isOn: $viewModel.compareModels)
                    .font(.title2)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                
                // Image display
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .transition(.opacity)
                        .animation(.easeInOut, value: selectedImage)
                } else {
                    Text("Select an image to classify")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Classify button
                if selectedImage != nil {
                    Button("Classify Image") {
                        viewModel.classifyImage(selectedImage!)
                    }
                    .font(.title2)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.black)
                }
                
                // Classification results
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if !viewModel.classificationResults.isEmpty {
                    VStack(spacing: 10) {
                        if viewModel.compareModels {
                            ForEach(MLModelType.allCases, id: \.self) { modelType in
                                if let result = viewModel.classificationResults[modelType] {
                                    Text("\(modelType.rawValue): \(result)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(10)
                                }
                            }
                        } else if let result = viewModel.classificationResults[viewModel.currentModelType] {
                            Text(result)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                        
                        // Bias warning button
                        Button(action: { showBiasAlert = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.white)
                        }
                        .alert(isPresented: $showBiasAlert) {
                            Alert(
                                title: Text("AI Bias Warning"),
                                message: Text("AI models can have biases based on their training data. Results should be interpreted with caution and not taken as absolute truth."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.classificationResults)
                }
                
                Spacer()
                
                // Image picker button
                PhotosPicker("Select Image", selection: $selectedItem, matching: .images)
                    .font(.title2)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.black)
            }
            .padding()
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    viewModel.classificationResults = [:] // Reset results
                }
            }
        }
    }
}

// Preview provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
