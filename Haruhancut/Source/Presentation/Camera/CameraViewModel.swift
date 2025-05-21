//  CameraViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit
import AVFoundation

final class CameraViewModel: NSObject {
    
    private(set) var captureSession: AVCaptureSession?   // 카메라 세션 객체
    private let videoOutput = AVCaptureVideoDataOutput() // 영상 프레임 출력(무음 캡처)
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private let context = CIContext()
    private(set) var currentImage: UIImage?

    var onFrameCaptured: ((UIImage) -> Void)?

    // MARK: - 카메라 초기화
    func configureSession() {
        sessionQueue.async { [weak self] in
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            
            guard let camera = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  session.canAddInput(input) else {
                print("❌ 카메라 설정 실패")
                return
            }
            session.addInput(input)
            
            self?.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
            if session.canAddOutput(self!.videoOutput) {
                session.addOutput(self!.videoOutput)
            }

            self?.captureSession = session
            session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
        }
    }

    func captureCurrentFrame() -> UIImage? {
        return currentImage
    }
}

// MARK: - CMSampleBuffer 처리
extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        let image = UIImage(cgImage: cgImage,
                            scale: UIScreen.main.scale,
                            orientation: .right)
        currentImage = image
        onFrameCaptured?(image)
    }
}
