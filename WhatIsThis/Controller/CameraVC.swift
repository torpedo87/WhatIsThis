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

enum FlashState {
  case on
  case off
}

class CameraVC: UIViewController {
  
  var captureSession: AVCaptureSession!
  var cameraOutput: AVCapturePhotoOutput!
  var previewLayer: AVCaptureVideoPreviewLayer!
  var photoData: Data?
  var flashState: FlashState = .off
  var speechSynthesizer = AVSpeechSynthesizer()

  @IBOutlet weak var spinner: UIActivityIndicatorView!
  @IBOutlet weak var roundedLabelView: RoundedShadowView!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var confidenceLabel: UILabel!
  @IBOutlet weak var identificationLabel: UILabel!
  @IBOutlet weak var capturedImgView: RoundedShadowImgView!
  @IBOutlet weak var flashBtn: RoundedShadowBtn!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    speechSynthesizer.delegate = self
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    previewLayer.frame = cameraView.bounds
    spinner.isHidden = true
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
    cameraView.isUserInteractionEnabled = false
    spinner.isHidden = false
    spinner.startAnimating()
    
    let settings = AVCapturePhotoSettings()
    
    //thumbnail size
    //let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first
    //let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
    //settings.previewPhotoFormat = previewFormat
    settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
    
    if flashState == .off {
      settings.flashMode = .off
    } else {
      settings.flashMode = .on
    }
    
    cameraOutput.capturePhoto(with: settings, delegate: self)
  }
  
  //요청을 입력하면 결과를 처리한다
  func resultsMethod(request: VNRequest, error: Error?) {
    guard let results = request.results as? [VNClassificationObservation] else { return }
    for classification in results {
      if classification.confidence < 0.5 {
        let unknownObjectMessage = "이게 뭔지 내가 어떻게 알아. 다시 찍어봐 임마"
        self.identificationLabel.text = unknownObjectMessage
        synthesizeSpeech(fromString: unknownObjectMessage)
        self.confidenceLabel.text = ""
        //print("low------", classification.identifier)
        break
      } else {
        let identification = classification.identifier
        let confidence = Int(classification.confidence * 100)
        self.identificationLabel.text = identification
        self.confidenceLabel.text = "CONFIDENCE: \(confidence)%"
        let completeSentence = "이거 \(identification) 같은데, \(confidence)% 정도 확실해"
        synthesizeSpeech(fromString: completeSentence)
        //print("high---------", classification.identifier)
        break
      }
    }
  }
  
  //string 을 입력하면 말한다
  func synthesizeSpeech(fromString string:String) {
    let speechUtterence = AVSpeechUtterance(string: string)
    speechSynthesizer.speak(speechUtterence)
  }
  
  @IBAction func flashBtnPressed(_ sender: Any) {
    switch flashState {
    case .off:
      flashBtn.setTitle("FLASH ON", for: .normal)
      flashState = .on
    case .on:
      flashBtn.setTitle("FLASH OFF", for: .normal)
      flashState = .off
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

extension CameraVC: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    cameraView.isUserInteractionEnabled = true
    spinner.isHidden = true
    spinner.stopAnimating()
  }
}
