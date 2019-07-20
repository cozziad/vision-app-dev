//
//  ViewController.swift
//  vision-app-dev
//
//  Created by Anthony Cozzi on 7/19/19.
//  Copyright © 2019 Anthony Cozzi. All rights reserved.
//

import UIKit

class CameraVC: UIViewController {

    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var IDLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: RoundedShadow!
    @IBOutlet weak var roundedShadowView: RoundedShadow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

