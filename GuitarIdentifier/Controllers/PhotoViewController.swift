import UIKit
import AVFoundation

class PhotoViewController: UIViewController  {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var photoButton: UIButton!
    
    var capturedImage: UIImage?
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    let sessionQueue = DispatchQueue(label: "session queue",
                                     attributes: [],
                                     target: nil)
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoDeviceInput: AVCaptureDeviceInput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
        photoButton.layer.cornerRadius = 10
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(getPhotoFromLibraryPressed))
    }
    
    @objc func getPhotoFromLibraryPressed() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        sessionQueue.async {
            DispatchQueue.main.async { [unowned self] in
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                self.previewLayer.videoGravity = .resizeAspectFill
                self.previewLayer.frame = self.previewView.bounds
                self.previewView.layer.addSublayer(self.previewLayer)
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [unowned self] in
            self.session.stopRunning()
        }
        super.viewWillDisappear(animated)
    }
    
    // MARK: Session Management
    
    private func configureSession() {
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            let dualCameraDeviceType: AVCaptureDevice.DeviceType
            if #available(iOS 11, *) {
                dualCameraDeviceType = .builtInDualCamera
            } else {
                dualCameraDeviceType = .builtInDuoCamera
            }
            
            if let dualCameraDevice = AVCaptureDevice.default(dualCameraDeviceType, for: AVMediaType.video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                /*
                 In some cases where users break their phones, the back wide angle camera is not available.
                 In this case, we should default to the front wide angle camera.
                 */
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            }
        } catch {
            print("Could not create video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        } else {
            print("Could not add photo output to the session")
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    @IBAction private func capturePhoto(_ sender: UIButton) {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        if self.videoDeviceInput.device.isFlashAvailable {
            photoSettings.flashMode = .auto
        }
        
        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto"{
            if let nc = segue.destination as? UINavigationController {
                if let vc = nc.viewControllers[0] as? CapturedPhotoViewController{
                    vc.photo = capturedImage
                }
            }
        }
    }
}

extension PhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    //    MARK: - Delegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        capturedImage = (info[UIImagePickerControllerOriginalImage] as! UIImage)
        performSegue(withIdentifier: "showPhoto", sender: nil)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate Methods

extension PhotoViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {

        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                if let image = UIImage(data: dataImage) {
                    capturedImage = image
                }
            }
        }
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let data = photo.fileDataRepresentation(),
            let image =  UIImage(data: data)  else {
                return
        }
        capturedImage = image
        performSegue(withIdentifier: "showPhoto", sender: nil)
    }
}
