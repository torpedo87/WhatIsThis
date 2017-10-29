//
//  CameraVC.swift
//  WhatIsThis
//
//  Created by junwoo on 2017. 10. 29..
//  Copyright © 2017년 samchon. All rights reserved.
//

import UIKit

class CameraVC: UIViewController {

  @IBOutlet weak var roundedLabelView: RoundedShadowView!
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var confidenceLabel: UILabel!
  @IBOutlet weak var identificationLabel: UILabel!
  @IBOutlet weak var capturedImgView: RoundedShadowImgView!
  @IBOutlet weak var flashBtn: RoundedShadowBtn!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
}
