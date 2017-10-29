//
//  CameraVC.swift
//  WhatIsThis
//
//  Created by junwoo on 2017. 10. 29..
//  Copyright © 2017년 samchon. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class CameraVC: UIViewController {
  
  var captureSession: AVCaptureSession!
  var cameraOutput: AVCapturePhotoOutput!
  var previewLayer: AVCaptureVideoPreviewLayer!
  var photoData: Data?

  @IBOutlet weak var roundedLabelView: RoundedShadowView!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var confidenceLabel: UILabel!
  @IBOutlet weak var identificationLabel: UILabel!
  @IBOutlet weak var capturedImgView: RoundedShadowImgView!
  @IBOutlet weak var flashBtn: RoundedShadowBtn!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    previewLayer.frame = cameraView.bounds
  }
  
  //초기화
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
    tap.numberOfTapsRequired = 1
    
    
    captureSession = AVCaptureSession()
    captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
    let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
    
    do {
      //input
      let input = try AVCaptureDeviceInput(device: backCamera!)
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
      }
      
      //output
      cameraOutput = AVCapturePhotoOutput()
      if captureSession.canAddOutput(cameraOutput) {
        captureSession.addOutput(cameraOutput)
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        //aspect ratio
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraView.layer.addSublayer(previewLayer)
        cameraView.addGestureRecognizer(tap)
        captureSession.startRunning()
      }
    } catch {
      debugPrint("could not setup camera :", error.localizedDescription)
    }
  }
  
  @objc func didTapCameraView() {
    let settings = AVCapturePhotoSettings()
    
    //thumbnail size
    //let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first
    //let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
    //settings.previewPhotoFormat = previewFormat
    settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
    
    cameraOutput.capturePhoto(with: settings, delegate: self)
  }
  
  func resultsMethod(request: VNRequest, error: Error?) {
    guard let results = request.results as? [VNClassificationObservation] else { return }
    for classification in results {
      if classification.confidence < 0.5 {
        self.identificationLabel.text = "I'm not sure what this is"
        self.confidenceLabel.text = ""
        print("low------", classification.identifier)
        continue
      } else {
        self.identificationLabel.text = classification.identifier
        self.confidenceLabel.text = "CONFIDENCE: \(Int(classification.confidence * 100))%"
        print("high---------", classification.identifier)
        break
      }
    }
  }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
      debugPrint(error)
    } else {
      photoData = photo.fileDataRepresentation()
      
      //coreML 에 보내기
      do {
        //Vision을 이용해 뇌 모델 만들기
        let model = try VNCoreMLModel(for: SqueezeNet().model)
        let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
        let handler = VNImageRequestHandler(data: photoData!)
        try handler.perform([request])
      } catch {
        debugPrint("could not send to coreML: ", error.localizedDescription)
      }
      
      let image = UIImage(data: photoData!)
      self.capturedImgView.image = image
    }
  }
}
