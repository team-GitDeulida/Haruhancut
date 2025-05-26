//  ProfileViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit
import FirebaseAuth
import RxSwift
import Kingfisher

final class ProfileViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    weak var coordinator: HomeCoordinator?

    private let profileViewModel = ProfileViewModel()
    private let homeViewModel: HomeViewModelType
    
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Component
//    private lazy var profileImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 10
//        imageView.clipsToBounds = true
//        imageView.backgroundColor = .Gray500
//        
//        if let urlString = homeViewModel.user.value?.profileImageURL,
//           let url = URL(string: urlString) {
//            imageView.kf.setImage(with: url)
//        } else {
//            imageView.image = UIImage(systemName: "person.fill")
//            imageView.tintColor = .gray
//        }
//        
//        return imageView
//    }()

    private lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        
        if let urlString = homeViewModel.user.value?.profileImageURL,
           let url = URL(string: urlString) {
            
            imageView.setImage(with: url)
            
//            KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
//                switch result {
//                case .success(let value):
//                    Task { @MainActor [weak self] in
//                        guard let self else { return }
//                        self.homeViewModel.uploadProfileImage(value.image)
//                            .observe(on: MainScheduler.instance)
//                            .subscribe(onNext: { success in
//                                print(success != nil ? "✅ 프로필 업로드 성공" : "❌ 업로드 실패")
//                            })
//                            .disposed(by: self.disposeBag)
//                    }
//                case .failure(let error):
//                    print("❌ 이미지 다운로드 실패: \(error)")
//                }
//            }
        } else {
            imageView.setImage(UIImage(systemName: "person.fill")!)
            imageView.tintColor = .gray
        }

        
        imageView.onCameraTapped = { [weak self] in
            guard let self = self else { return }
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        return imageView
    }()
    
    private lazy var nicknameLabel: HCLabel = {
       let label = HCLabel(type: .main(text: homeViewModel.user.value?.nickname ?? "닉네임"))
        return label
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.tintColor = .mainWhite
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [profileImageView, nicknameLabel, UIView(), editButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        
        return stack
    }()
    
    private lazy var logoutBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.addTarget(self, action: #selector(logout), for: .touchUpInside)
        return button
    }()
    
    private lazy var testBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Test", for: .normal)
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        
        [hStack, logoutBtn, testBtn].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            hStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            hStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        
        NSLayoutConstraint.activate([
            logoutBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            testBtn.topAnchor.constraint(equalTo: logoutBtn.bottomAnchor, constant: 50),
            testBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func logout() {
        do {
            UserDefaultsManager.shared.removeUser()
            UserDefaultsManager.shared.removeGroup()
            try Auth.auth().signOut()
            print("로그아웃 성공")
            coordinator?.showLogin()
            homeViewModel.stopObservingGroup()
            
            
        } catch let signOutError as NSError {
            print("로그아웃 실패: %@", signOutError)
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ 해당 소스타입 사용 불가")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    // 이미지 선택 완료
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let image = info[.originalImage] as? UIImage {
            // 이미지 설정
            self.profileImageView.setImage(image)
            //self.selectedImage = image
        }
    }

    // 선택 취소
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

#Preview {
    ProfileSettingViewController(
        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()))
}



#Preview {
    ProfileViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0], cameraType: .camera))
}

