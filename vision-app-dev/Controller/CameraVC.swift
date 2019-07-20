//
//  ViewController.swift
//  vision-app-dev
//
//  Created by Anthony Cozzi on 7/19/19.
//  Copyright © 2019 Anthony Cozzi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class CameraVC: UIViewController {

    //Outlets
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    @IBOutlet weak var IDLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: RoundedShadow!
    @IBOutlet weak var roundedShadowView: RoundedShadow!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    //Vars
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    var flashIsOn: Bool = false
    
    var speechSynth = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynth.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input){captureSession.addInput(input)}
            
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput){captureSession.addOutput(cameraOutput!)}
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewLayer.connection?.videoOrientation = .portrait
            cameraView.addGestureRecognizer(tap)
            cameraView.layer.addSublayer(previewLayer!)
            captureSession.startRunning()
        }
        catch{}
    }
    
    @objc func didTapCameraView(sender: UITapGestureRecognizer){
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if flashIsOn{settings.flashMode = .on}
        else{settings.flashMode = .off}
    
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error:Error?){
      
        var didFind = false
        guard let results = request.results as? [VNClassificationObservation] else {return}

        for classification in results{
            if classification.confidence < 0.5{
                self.IDLbl.text = "Not sure about that?"
                self.confidenceLbl.text = ""
            }
            else{
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.IDLbl.text = identification
                self.confidenceLbl.text = "Confidence: \(confidence)%"
                let speechString = "Looks like a \(identification) with \(confidence) percent confidence"
                SynthSpeech(fromString: speechString)
                didFind = true
                break
            }
        }
        if !didFind {SynthSpeech(fromString: "What are you showing me foo")}
    }
    
    @IBAction func flashBtnPressed(_ sender: Any) {
        if flashIsOn{
            flashIsOn = false
            flashBtn.setTitle("FLASH OFF", for: .normal)
        }
        else{
            flashIsOn = true
            flashBtn.setTitle("FLASH ON", for: .normal)
        }
    }
    
    func SynthSpeech (fromString string:String){
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynth.speak(speechUtterance)
    }
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{debugPrint(error);return}
        
        photoData = photo.fileDataRepresentation()
        let image = UIImage(data: photoData!)
        self.captureImageView.image = image
        
        do{
            let model = try VNCoreMLModel(for: SqueezeNet().model)
            let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
            let handler = VNImageRequestHandler(data: photoData!)
            try handler.perform([request])
        }catch{debugPrint(error)}
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}
