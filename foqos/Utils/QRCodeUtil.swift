import SwiftUI
import AVFoundation

class QRCodeUtil: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var onCodeScanned: ((String) -> Void)?
    
    func scanQRCode(completion: @escaping (String) -> Void) {
        self.onCodeScanned = completion
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Could not create video input: \(error)")
            return
        }
        
        let session = AVCaptureSession()
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            print("Could not add video input to session")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("Could not add metadata output to session")
            return
        }
        
        self.captureSession = session
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            captureSession?.stopRunning()
            onCodeScanned?(stringValue)
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
}

