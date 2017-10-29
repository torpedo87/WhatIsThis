//
//  RoundedShadowImgView.swift
//  WhatIsThis
//
//  Created by junwoo on 2017. 10. 29..
//  Copyright © 2017년 samchon. All rights reserved.
//

import UIKit

class RoundedShadowImgView: UIImageView {

  override func awakeFromNib() {
    self.layer.shadowColor = UIColor.darkGray.cgColor
    self.layer.shadowRadius = 15
    self.layer.shadowOpacity = 0.75
    
    self.layer.cornerRadius = 15
  }

}
