////  CameraViewController.swift
////  Haruhancut
////
////  Created by 김동현 on 4/27/25.
////
//
//import UIKit
//import AVFoundation
//
//final class CameraViewController: UIViewController {
//    
//    weak var coordinator: HomeCoordinator?
//
//    private let viewModel = CameraViewModel()
//    private var captureSession: AVCaptureSession?
//    private var previewLayer: AVCaptureVideoPreviewLayer?
//    
//    private let cameraView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .black
//        return view
//    }()
//    
//    private lazy var captureButton: UIButton = {
//        let button = UIButton()
//        button.backgroundColor = .white
//        button.layer.cornerRadius = 35
//        button.layer.masksToBounds = true
//        return button
//    }()
//
//    // MARK: - LifeCycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCamera()
//        makeUI()
//    }
//    
//    private func setupCamera() {
//        let session = AVCaptureSession()
//        session.sessionPreset = .photo
//        
//        guard let camera = AVCaptureDevice.default(for: .video),
//              let input = try? AVCaptureDeviceInput(device: camera) else {
//            print("카메라 접근 실패")
//            return
//        }
//        
//        session.addInput(input)
//        
////        let preview = AVCaptureVideoPreviewLayer(session: session)
////        preview.videoGravity = .resizeAspectFill
////        view.layer.addSublayer(preview)
////        self.previewLayer = preview
//        
//        
//        self.captureSession = session
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            session.startRunning()
//        }
//    }
//    
//    // MARK: - UI Setting
//    private func makeUI() {
//        view.backgroundColor = .mainBlack
//        // 1. 카메라 뷰 먼저 추가 !!!
//        view.addSubview(cameraView)
//        cameraView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            cameraView.widthAnchor.constraint(equalTo: cameraView.heightAnchor) // 정사각형
//        ])
//        
//        // 2. 버튼 추가
//        view.addSubview(captureButton)
//        captureButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            captureButton.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 20),
//            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            captureButton.widthAnchor.constraint(equalToConstant: 70),
//            captureButton.heightAnchor.constraint(equalToConstant: 70)
//        ])
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        if previewLayer == nil, let session = captureSession {
//            let preview = AVCaptureVideoPreviewLayer(session: session)
//            preview.videoGravity = .resizeAspectFill
//            preview.frame = cameraView.bounds
//            cameraView.layer.addSublayer(preview)
//            self.previewLayer = preview
//        } else {
//            previewLayer?.frame = cameraView.bounds
//        }
//    }
//
//}
//
//#Preview {
//    CameraViewController()
//}

//
////
////  CameraViewController.swift
////  Haruhancut
////
////  Created by 김동현 on 4/27/25.
////
//
//import UIKit
//import AVFoundation
//
//final class CameraViewController: UIViewController {
//    
//    weak var coordinator: HomeCoordinator?
//
//    private let viewModel = CameraViewModel()
//    private var captureSession: AVCaptureSession?
//    private var previewLayer: AVCaptureVideoPreviewLayer?
//    
//    private let cameraView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .black
//        return view
//    }()
//    
//    private lazy var captureButton: UIButton = {
//        let button = UIButton()
//        button.backgroundColor = .white
//        button.layer.cornerRadius = 35
//        button.layer.masksToBounds = true
//        return button
//    }()
//
//    // MARK: - LifeCycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        makeUI() // ✅ 화면 먼저 그리기
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        // ✅ 화면 뜬 후, 백그라운드에서 카메라 세팅
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            self?.setupCamera()
//        }
//    }
//    
//    // MARK: - Camera Setup
//    private func setupCamera() {
//        let session = AVCaptureSession()
//        session.sessionPreset = .photo
//        
//        guard let camera = AVCaptureDevice.default(for: .video),
//              let input = try? AVCaptureDeviceInput(device: camera) else {
//            print("카메라 접근 실패")
//            return
//        }
//        
//        session.addInput(input)
//        self.captureSession = session
//        
//        session.startRunning()
//        
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            if self.previewLayer == nil {
//                let preview = AVCaptureVideoPreviewLayer(session: session)
//                preview.videoGravity = .resizeAspectFill
//                preview.frame = self.cameraView.bounds
//                self.cameraView.layer.addSublayer(preview)
//                self.previewLayer = preview
//            }
//        }
//    }
//    
//    // MARK: - UI Setting
//    private func makeUI() {
//        view.backgroundColor = .mainBlack
//        
//        // 1. 카메라 뷰 추가
//        view.addSubview(cameraView)
//        cameraView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            cameraView.widthAnchor.constraint(equalTo: cameraView.heightAnchor) // 정사각형
//        ])
//        
//        // 2. 촬영 버튼 추가
//        view.addSubview(captureButton)
//        captureButton.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            captureButton.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 20),
//            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            captureButton.widthAnchor.constraint(equalToConstant: 70),
//            captureButton.heightAnchor.constraint(equalToConstant: 70)
//        ])
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        // 미리보기 프레임 업데이트
//        previewLayer?.frame = cameraView.bounds
//    }
//}
//
//#Preview {
//    CameraViewController()
//}


//
//  CameraViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?

    private let viewModel = CameraViewModel()
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        // button.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        preparePreviewLayer() // ✅ 화면 뜨자마자 previewLayer 먼저 준비
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // ✅ 화면 뜬 후, 백그라운드에서 카메라 세션 연결
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    // MARK: - Prepare PreviewLayer
    private func preparePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer()
        preview.videoGravity = .resizeAspectFill
        preview.frame = cameraView.bounds
        cameraView.layer.addSublayer(preview)
        self.previewLayer = preview
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("카메라 접근 실패")
            return
        }
        
        session.addInput(input)
        self.captureSession = session
        
        session.startRunning()
        
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.session = session // ✅ 나중에 연결만 해줌
        }
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        
        view.addSubview(cameraView)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 200),
//            cameraView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            cameraView.widthAnchor.constraint(equalToConstant: 200),
//            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor)
//        ])

        NSLayoutConstraint.activate([
            // 위치
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor)
        ])
        
        view.addSubview(cameraBtn)
        cameraBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            // captureButton.widthAnchor.constraint(equalToConstant: 70),
            // captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.bounds
    }
}

#Preview {
    CameraViewController()
}
