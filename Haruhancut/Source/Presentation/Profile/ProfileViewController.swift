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

    private let profileViewModel: ProfileViewModelType
    private let homeViewModel: HomeViewModelType
    private let loginViewModel: LoginViewModelType
    
    init(profileViewModel: ProfileViewModelType, homeViewModel: HomeViewModelType, loginViewModel: LoginViewModelType) {
        self.profileViewModel = profileViewModel
        self.homeViewModel = homeViewModel
        self.loginViewModel = loginViewModel 
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Component
    private lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
            
        /*
        MARK: - bindUser()로 대체
        if let urlString = homeViewModel.user.value?.profileImageURL,
           let url = URL(string: urlString) {
            
            imageView.setImage(with: url)
        } else {
            imageView.setImage(UIImage(systemName: "person.fill")!)
            imageView.tintColor = .gray
        }
         */

        
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
        bindUser()
    }
    
    // MARK: - Bind
    /// ProfileViewController에서 homeViewModel.user를 RX로 관할하여, 프로필 이미지가 변경될 때마다 자동으로 UI를 업데이트 한다
    private func bindUser() {
        homeViewModel.user
            .compactMap { $0?.profileImageURL }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] urlString in
                guard let self = self else { return }
                guard let url = URL(string: urlString) else { return }
                
                // MARK: - 비동기 kf 이미지 설정
                self.profileImageView.setImage(with: url)
            })
            .disposed(by: disposeBag)
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
            
            // MARK: - 새 이미지 바로 반영 (사용자 경험 향상)
            self.profileImageView.setImage(image)
            
            // MARK: - 이미지 비동기 업로드
            profileViewModel.uploadImage(image: image)
                .bind(onNext: { [weak self] success in
                    guard let self = self else { return }
                    
                    if success {
                        if let profileViewModel = self.profileViewModel as? ProfileViewModel {
                            let updatedUser = profileViewModel.userRelay.value
                            self.homeViewModel.user.accept(updatedUser)
                        }
                    } else {
                        print("❌ 프로필 이미지 업로드 실패")
                    }
                }).disposed(by: disposeBag)
            
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
    ProfileViewController(profileViewModel: StubProfileViewModel(), homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0], cameraType: .camera), loginViewModel: StubLoginViewModel())
}

