//
//  CameraViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//
/*
 🔍 왜 굳이 captureSession?.stopRunning()으로 종료해주는가?

 1. 카메라는 제한된 리소스입니다
 iOS에서 카메라는 시스템 자원이기 때문에,
 다른 앱이나 시스템 기능과 경쟁 관계에 있어요.
 뷰에서 벗어났는데도 계속 카메라가 켜져 있으면:
 배터리 낭비
 백그라운드에서 카메라 점유 상태 유지
 App Store 심사 리젝 사유 될 수 있어요 😥
 
 2. 버그/깜빡임/크래시 유발 가능성
 AVCaptureSession이 중복 실행되거나,
 다시 돌아왔을 때 세션이 꼬이면 카메라 미리보기가 안 나오는 버그가 생기기 쉬워요.
 그래서 보통은 뷰가 사라질 때 정리하고,
 다시 들어오면 깨끗한 상태로 세션을 새로 구성합니다.
 
 3. 메모리 관리 차원에서도 권장
 카메라 관련 오브젝트 (AVCaptureSession, AVCaptureDeviceInput, 등)는 무겁고 시스템 자원을 많이 사용해요.
 한 번 쓰고 나면 nil로 해제해서 메모리에서 내려주는 게 좋습니다.
 
 ✅ 그래서 권장 흐름은?

 단계    동작
 viewDidAppear    카메라 세션 시작 (startRunning())
 viewDidDisappear    카메라 세션 종료 (stopRunning(), nil로 해제)
 
 
 앱이 사진을 저장할 때 권한 필요
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>촬영한 사진을 앨범에 저장하기 위해 접근이 필요합니다.</string>
 
 <key>NSCameraUsageDescription</key>
 <string>사진 촬영을 위해 카메라 접근이 필요합니다.</string>

 */


//
//  CameraViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//
/*
 🔍 왜 굳이 captureSession?.stopRunning()으로 종료해주는가?

 1. 카메라는 제한된 리소스입니다
 iOS에서 카메라는 시스템 자원이기 때문에,
 다른 앱이나 시스템 기능과 경쟁 관계에 있어요.
 뷰에서 벗어났는데도 계속 카메라가 켜져 있으면:
 배터리 낭비
 백그라운드에서 카메라 점유 상태 유지
 App Store 심사 리젝 사유 될 수 있어요 😥
 
 2. 버그/깜빡임/크래시 유발 가능성
 AVCaptureSession이 중복 실행되거나,
 다시 돌아왔을 때 세션이 꼬이면 카메라 미리보기가 안 나오는 버그가 생기기 쉬워요.
 그래서 보통은 뷰가 사라질 때 정리하고,
 다시 들어오면 깨끗한 상태로 세션을 새로 구성합니다.
 
 3. 메모리 관리 차원에서도 권장
 카메라 관련 오브젝트 (AVCaptureSession, AVCaptureDeviceInput, 등)는 무겁고 시스템 자원을 많이 사용해요.
 한 번 쓰고 나면 nil로 해제해서 메모리에서 내려주는 게 좋습니다.
 
 ✅ 그래서 권장 흐름은?

 단계    동작
 viewDidAppear    카메라 세션 시작 (startRunning())
 viewDidDisappear    카메라 세션 종료 (stopRunning(), nil로 해제)
 
 
 앱이 사진을 저장할 때 권한 필요
 <key>NSPhotoLibraryAddUsageDescription</key>
 <string>촬영한 사진을 앨범에 저장하기 위해 접근이 필요합니다.</string>
 
 <key>NSCameraUsageDescription</key>
 <string>사진 촬영을 위해 카메라 접근이 필요합니다.</string>

 */

/*
import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?

    private let viewModel = CameraViewModel()
    private var captureSession: AVCaptureSession?               // 카메라 세션 객체
    private var previewLayer: AVCaptureVideoPreviewLayer?       // 카메라 화면을 보여줄 레이어
    private let photoOutput = AVCapturePhotoOutput()            // 카메라 촬영을 위한 출력 객체
    
    // 중복 카메라 설정 방지 플래그
    private var isCameraConfigured = false
    
    // 카메라 화면이 보여질 뷰(이 위에 previewLayer 올림)
    private let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    // 촬영 버튼
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
         button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        preparePreviewLayer() // 미리보기 layer 초기화
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 중복설정 방지
        guard !isCameraConfigured else { return }
        isCameraConfigured = true
        
        // 카메라 설정(백그라운드 스레드에서 실행)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // MARK: - 화면 벗어나면 세션 중지 및 리소스 정리
        // 화면을 벗어날 때 세션 종료
        captureSession?.stopRunning()
        captureSession = nil
        
        // 미리보기 레이어(previewLayer) 제거(선택사항)
        previewLayer?.removeFromSuperlayer()
        
        // 재진입시 카메라 다시 설정(setupCamera 호출)되도록 플래그 초기화
        isCameraConfigured = false
    }

    
    // MARK: - 카메라 미리보기 layer 설정
    private func preparePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer()
        preview.videoGravity = .resizeAspectFill    // 화면 채우면서 비율 유지
        preview.frame = cameraView.bounds           // 초기 프레임 설정
        cameraView.layer.addSublayer(preview)       // cameraView에 layer 추가
        self.previewLayer = preview                 // 나중에 참조할 수 있도록 저장
    }
    
    // MARK: - 카메라 설정
    private func setupCamera() {
        // 1. 세션 설정
        let session = AVCaptureSession()
        session.sessionPreset = .photo // 고해상도 사진 모드
        
        // 후면 카메라를 입력으로 설정
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("카메라 접근 실패")
            return
        }
        
        // 세션에 입력 추가
        if session.canAddInput(input) {
            session.addInput(input)
        }

        // 세션에 사진 출력 추가
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        // 세션 저장 및 시작
        self.captureSession = session
        session.startRunning()
        
        // 메인 스레드에서 previewLayer와 세션 연결
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.session = session
        }
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        [cameraView, cameraBtn].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // cameraView 제약조건
        NSLayoutConstraint.activate([
            // 위치
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor)
        ])

        // 촬영 버튼 제약조건
        NSLayoutConstraint.activate([
            cameraBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
    }
    
    // MARK: - 레이아웃 갱신(프레임 동기화)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 프레임이 달라졌을 때만 previewLayer 위치/크기 갱신
        if previewLayer?.frame != cameraView.bounds {
            previewLayer?.frame = cameraView.bounds
        }
    }
}

// MARK: - 1. 카메라 사진으로 저장하는 방법
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
            print("사진 촬영 오류: \(error.localizedDescription)")
            return
        }

        // 사진 데이터를 JPEG 형태로 변환
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("이미지 변환 실패")
            return
        }

        // 사진 앨범에 저장
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("✅ 사진 저장 완료")
    }
}

#Preview {
    CameraViewController()
}
*/


// MARK: - 코드 이해하고 mvvm으로 진행 예정

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {
    
    weak var coordinator: HomeCoordinator?

    // private let cameraViewModel = CameraViewModel()
    private var captureSession: AVCaptureSession?               // 카메라 세션 객체
    private var previewLayer: AVCaptureVideoPreviewLayer?       // 카메라 화면을 보여줄 레이어
    
    // MARK: - 캡처 방식을 사용한다면 필요한 프로퍼티들
    private let videoOutput = AVCaptureVideoDataOutput()        // 영상 프레임 출력(무음 캡처)
    private var currentImage: UIImage?                          // 가장 최근 프레임 저장용
    private var freezeImageView: UIImageView?                   // 캡처한 이미지 띄우는 용ㄷ

    
    private var isCameraConfigured = false                      // 중복 카메라 설정 방지 플래그
    
    // 카메라 화면이 보여질 뷰(이 위에 previewLayer 올림)
    private let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    // 촬영 버튼
    private lazy var cameraBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        button.tintColor = .mainWhite
        button.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        button.imageView?.contentMode = .scaleAspectFit
         button.addTarget(self, action: #selector(captureCurrentFrame), for: .touchUpInside)
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        preparePreviewLayer() // 미리보기 layer 초기화
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 중복설정 방지
        guard !isCameraConfigured else { return }
        isCameraConfigured = true
        
        // 카메라 설정(백그라운드 스레드에서 실행)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupCamera()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 다음 뷰가 previewVC라면 종료하지 않고 여기서 리턴하겠다
        if let topVC = navigationController?.topViewController,
           topVC is ImageUploadViewController { return }
        
        // MARK: - 화면 벗어나면 세션 중지 및 리소스 정리
        // 화면을 벗어날 때 세션 종료
        captureSession?.stopRunning()
        captureSession = nil
        
        // 미리보기 레이어(previewLayer) 제거(선택사항)
        previewLayer?.removeFromSuperlayer()
        
        // 재진입시 카메라 다시 설정(setupCamera 호출)되도록 플래그 초기화
        isCameraConfigured = false
    }

    
    // MARK: - 카메라 미리보기 layer 설정
    private func preparePreviewLayer() {
        let preview = AVCaptureVideoPreviewLayer()
        preview.videoGravity = .resizeAspectFill    // 화면 채우면서 비율 유지
        preview.frame = cameraView.bounds           // 초기 프레임 설정
        cameraView.layer.addSublayer(preview)       // cameraView에 layer 추가
        self.previewLayer = preview                 // 나중에 참조할 수 있도록 저장
    }
    
    // MARK: - 카메라 설정
    private func setupCamera() {
        // 1. 세션 설정
        let session = AVCaptureSession()
        session.sessionPreset = .photo // 고해상도 사진 모드
        
        // 후면 카메라를 입력으로 설정
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("카메라 접근 실패")
            return
        }
        
        // 세션에 입력 추가
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // 비디오 출력 설정
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // 세션 저장 및 시작
        self.captureSession = session
        session.startRunning()
        
        // 메인 스레드에서 previewLayer와 세션 연결
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.session = session
        }
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        [cameraView, cameraBtn].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // cameraView 제약조건
        NSLayoutConstraint.activate([
            // 위치
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor)
        ])

        // 촬영 버튼 제약조건
        NSLayoutConstraint.activate([
            cameraBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraBtn.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
    }
    
    // MARK: - 레이아웃 갱신(프레임 동기화)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 프레임이 달라졌을 때만 previewLayer 위치/크기 갱신
        if previewLayer?.frame != cameraView.bounds {
            previewLayer?.frame = cameraView.bounds
        }
    }
}

// MARK: - 실시간 프레임 처리 (CMSampleBuffer → UIImage)
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - 프레임 캡처하여 저장 (무음 촬영)
    @objc private func captureCurrentFrame() {
        guard let image = currentImage else {
            print("현재 프레임 없음")
            return
        }
        
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//        print("✅ 무음 사진 저장 완료")


        assert(Thread.isMainThread, "❌ UI 변경은 반드시 메인 스레드에서 수행해야 합니다")
        coordinator?.navigateToUpload(image: image)
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage,
                                  scale: UIScreen.main.scale,
                                  orientation: .right) // 카메라 방향 보정
            self.currentImage = uiImage
        }
    }
}

#Preview {
    CameraViewController()
}



