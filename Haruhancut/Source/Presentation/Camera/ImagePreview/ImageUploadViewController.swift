//
//  ImageUploadViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/21/25.
//

import UIKit
import RxSwift

final class ImageUploadViewController: UIViewController {
    weak var coordinator: HomeCoordinator?
    
    private let homeViewModel: HomeViewModelType
    private let image: UIImage
    private let disposeBag = DisposeBag()
    
    private let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    // 이미지를 보여줄 이미지 뷰 추가 ✅
    private lazy var imageView: UIImageView = {
        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    // 이미지 업로드 버튼
    private lazy var uploadButton: HCUploadButton = {
        let button = HCUploadButton(title: "업로드")
        button.addTarget(self, action: #selector(uploadAndBackToHome), for: .touchUpInside)
        return button
    }()
    
    init(image: UIImage, homeViewModel: HomeViewModelType) {
        self.image = image
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
    }
    
    private func makeUI() {
        view.backgroundColor = .mainBlack
        [cameraView, uploadButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        cameraView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        // cameraView 제약조건
        NSLayoutConstraint.activate([
            // 위치
            cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor),
            
            // imageView가 cameraView를 가득 채우도록 설정
            imageView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            
            // uploadButton
            uploadButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            uploadButton.widthAnchor.constraint(equalToConstant: 200),
            uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func uploadAndBackToHome() {
        
        // 버튼 비활성화
        uploadButton.isEnabled = false
        uploadButton.alpha = 0.5
        
        homeViewModel.uploadPost(image: image)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] success in
                guard let self = self else { return }
                self.coordinator?.backToHome()
                if success {
                    print("✅ 업로드 성공 - 홈 이동")
                    self.uploadButton.isEnabled = true
                    self.uploadButton.alpha = 1.0
                } else {
                    print("❌ 업로드 실패")
                }
            })
            .disposed(by: disposeBag)
    }
}

#Preview {
    ImageUploadViewController(image: UIImage(), homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0], cameraType: .camera))
}
