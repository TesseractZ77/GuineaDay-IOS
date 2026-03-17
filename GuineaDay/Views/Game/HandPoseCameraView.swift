import SwiftUI
import AVFoundation
import Vision

struct HandPoseCameraView: UIViewControllerRepresentable {
    var onHandDetected: (CGPoint, Bool) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cvc = CameraViewController()
        cvc.delegate = context.coordinator
        return cvc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: HandPoseCameraView
        
        init(_ parent: HandPoseCameraView) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didDetectHandAt point: CGPoint, isGrabbing: Bool) {
            // Pass data back to swiftui via closure
            DispatchQueue.main.async {
                self.parent.onHandDetected(point, isGrabbing)
            }
        }
    }
}

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didDetectHandAt point: CGPoint, isGrabbing: Bool)
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    weak var delegate: CameraViewControllerDelegate?
    
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480
        
        // Find front camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // Need to ensure orientation is basically correct
            if let connection = videoDataOutput.connection(with: .video) {
                connection.videoRotationAngle = 90 // Portrait orientation
                connection.isVideoMirrored = true // Mirror for front camera so left is left
            }
        }
        
        handPoseRequest.maximumHandCount = 1
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([handPoseRequest])
            
            guard let observation = handPoseRequest.results?.first else {
                return
            }
            
            let indexFingerTip = try observation.recognizedPoint(.indexTip)
            let thumbTip = try observation.recognizedPoint(.thumbTip)
            let indexBase = try observation.recognizedPoint(.indexMCP)
            
            // Confidence check
            guard indexFingerTip.confidence > 0.3 else { return }
            
            // Normalized points in vision coordinate space (bottom left origin)
            let point = indexFingerTip.location
            
            // Rough heuristic for grabbing: is distance between index tip and thumb tip small?
            // OR is the index tip lower than the index base (finger curled inward)
            let distance = hypot(indexFingerTip.location.x - thumbTip.location.x, indexFingerTip.location.y - thumbTip.location.y)
            let isGrabbing = distance < 0.05 || (indexFingerTip.location.y < indexBase.location.y)
            
            delegate?.cameraViewController(self, didDetectHandAt: point, isGrabbing: isGrabbing)
            
        } catch {
            print("Vision error: \(error)")
        }
    }
}
