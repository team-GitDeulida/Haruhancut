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
    weak var coordinator: HomeCoordinator?
    private let disposeBag = DisposeBag()
    private let profileViewModel: ProfileViewModelType
    private let homeViewModel: HomeViewModelType
    private let loginViewModel: LoginViewModelType
    private var loadingView: UIView?
    
    // MARK: - UI
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

        // MARK: - 카메라 버튼 탭
        imageView.onCameraTapped = { [weak self] in
            guard let self = self else { return }
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        
        // MARK: - 프로필 버튼 탭
        imageView.onProfileTapped = { [weak self] in
            guard let self = self else { return }
            
            guard let image = self.profileImageView.image else {
                print("이미지가 없습니다.")
                return
            }
            
            let previewVC = ImagePreviewViewController(image: image)
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true)
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
        button.addTarget(self, action: #selector(navigateToNicknameSetting), for: .touchUpInside)
        return button
    }()
    
    private lazy var hStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [profileImageView, UIView(), nicknameLabel, UIView(), editButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        
        return stack
    }()
    
    private lazy var collectionView: UICollectionView = {
        let spacing: CGFloat = 1
        let columns: CGFloat = 3

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = .zero

        // 셀 너비 계산
        let totalSpacing = (columns - 1) * spacing
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / columns
        
        // 높이를 너비의 1.5배로 설정
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(ProfilePostCell.self, forCellWithReuseIdentifier: ProfilePostCell.identifier)
        cv.backgroundColor = .clear
        return cv
    }()


    
    init(profileViewModel: ProfileViewModelType, homeViewModel: HomeViewModelType, loginViewModel: LoginViewModelType) {
        self.profileViewModel = profileViewModel
        self.homeViewModel = homeViewModel
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        bindUser()
        setupNavigation()
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
        
        homeViewModel.user
            .compactMap { $0?.nickname }
            .distinctUntilChanged()
            .bind(onNext: { [weak self] nickname in
                guard let self = self else { return }
                
                self.nicknameLabel.text = nickname
            })
            .disposed(by: disposeBag)

        
        let output = homeViewModel.transform()
        // allPostsByDate -> [Post]로 변환
        output.allPostsByDate
            .map { dict -> [Post] in
                // 1) 날짜 키 내림차순 정렬
                let sortedKeys = dict.keys.sorted(by: >)
                // 2) 각 키의 [Post]를 꺼내서 하나의 배열로 합치기
                return sortedKeys
                    .compactMap { dict[$0] }
                    .flatMap { $0 }
                    .filter { $0.userId == self.homeViewModel.user.value?.uid }
            }
            .drive(collectionView.rx.items(
                cellIdentifier: ProfilePostCell.identifier,
                cellType: ProfilePostCell.self)
            ) { _, post, cell in
                cell.configure(with: post)
            }
            .disposed(by: disposeBag)
        
        // 포스트 터치 바인딩
        collectionView.rx.modelSelected(Post.self)
            .asDriver()
            .drive(onNext: { [weak self] post in
                guard let self = self else { return }
                self.startPostDetail(post: post)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .mainBlack
        
        [hStack, collectionView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            hStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            hStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: hStack.bottomAnchor, constant: 50),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigation() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(navigateToSetting)
        )
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "프로필"
        navigationItem.backBarButtonItem = backItem
    }
    
    @objc func navigateToSetting() {
        coordinator?.startSetting()
    }
    
    @objc func navigateToNicknameSetting() {
        coordinator?.startNicknameChange()
    }
    
    /// 포스트 화면 이동
    private func startPostDetail(post: Post) {
        coordinator?.startPostDetail(post: post)
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
            self.setPopGestureEnabled(false)     // <-- 제스처 막기
            self.showLoadingIndicator()
            
            // MARK: - 이미지 비동기 업로드
            profileViewModel.uploadImage(image: image)
                .bind(onNext: { [weak self] success in
                    guard let self = self else { return }
                    self.hideLoadingIndicator()
                    self.setPopGestureEnabled(true)  // <-- 다시 허용
                    if success {
                        if let profileViewModel = self.profileViewModel as? ProfileViewModel {
                            let updatedUser = profileViewModel.userRelay.value
                            self.homeViewModel.user.accept(updatedUser)
                            
                            guard let groupId = homeViewModel.group.value?.groupId else { return }
                            self.homeViewModel.fetchGroup(groupId: groupId)
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

extension ProfileViewController {
    
    // MARK: - 제스처 잠금/해제
    private func setPopGestureEnabled(_ enabled: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
    }
    
    private func showLoadingIndicator() {
        guard let rootView = self.navigationController?.view ?? self.view else { return }
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.isUserInteractionEnabled = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingView.addSubview(indicator)

        rootView.addSubview(loadingView)
        self.loadingView = loadingView

        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: rootView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),

            indicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
    }

    
    private func showLoadingIndicator_noNavi() {
         let loadingView = UIView(frame: view.bounds)
         loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
         loadingView.isUserInteractionEnabled = true
         
         let indicator = UIActivityIndicatorView(style: .large)
         indicator.center = loadingView.center
         indicator.startAnimating()
         
         loadingView.addSubview(indicator)
         view.addSubview(loadingView)
         self.loadingView = loadingView
     }
     
     private func hideLoadingIndicator() {
         loadingView?.removeFromSuperview()
         loadingView = nil
     }
}

//#Preview {
//    ProfileSettingViewController(
//        loginViewModel: LoginViewModel(loginUsecase: StubLoginUsecase()))
//}



#Preview {
    ProfileViewController(profileViewModel: StubProfileViewModel(), homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0], cameraType: .camera), loginViewModel: StubLoginViewModel())
}

