//
//  CameraVC.swift
//  WhatIsThis
//
//  Created by junwoo on 2017. 10. 29..
//  Copyright © 2017년 samchon. All rights reserved.
//

import UIKit
import AVFoundation

class CameraVC: UIViewController {
  
  var captureSession: AVCaptureSession!
  var cameraOutput: AVCapturePhotoOutput!
  var previewLayer: AVCaptureVideoPreviewLayer!

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
        captureSession.startRunning()
      }
    } catch {
      debugPrint("could not setup camera :", error.localizedDescription)
    }
  }
}
