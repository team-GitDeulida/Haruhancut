//
//  ProfileSettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/26/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ProfileSettingViewController: UIViewController {
    weak var coordinator: LoginFlowCoordinator?
    
    private let disposeBag = DisposeBag()
    private let loginViewModel: LoginViewModel
    private var selectedImage: UIImage?
    
    private lazy var mainLabel: UILabel = HCLabel(type: .main(text: "\(loginViewModel.user.value?.nickname ?? "닉네임") 님의 프로필을 설정해 주세요"))
    
    private lazy var subLabel: UILabel = HCLabel(type: .sub(text: "지금은 넘어가도 되요!"))
    
    private lazy var labelStackView: UIStackView = {
        let st = UIStackView(arrangedSubviews: [
            mainLabel,
            subLabel
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually // 모든 뷰가 동일한 크기
        // 뷰의 크기를 축 반대 방향으로 꽉 채운다
        // 세로 스택일 경우, 각 뷰의 가로 너비가 스택의 가로폭에 맞춰진다
        st.alignment = .fill
        return st
    }()
    
    private lazy var profileImageView: ProfileImageView = {
        let imageView = ProfileImageView(size: 100, iconSize: 60)
        imageView.onCameraTapped = { [weak self] in
            guard let self = self else { return }
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        return imageView
    }()
    
    private lazy var nextButton: UIButton = HCNextButton(title: "완료")
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        bindViewModel()
    }
    
    private func makeUI() {
        view.backgroundColor = .background

        // MARK: - labelStack setup
        // 1. view에 버튼 추가
        view.addSubview(labelStackView)
        
        // 2. 오토레이아웃 활성화
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            labelStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),        // y축 위치
            labelStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20) // x축 위치
        ])
        
        
        view.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            profileImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        
        
        // MARK: - NextButtonn setup
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // y축 위치
            nextButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),              // x축 위치
            
            nextButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),// 좌우 패딩
            nextButton.heightAnchor.constraint(equalToConstant: 50) // 버튼 높이
        ])
    }
    
    private func bindViewModel() {
        let input = LoginViewModel.ProfileInput(nextBtnTapped: nextButton.rx.tap.asObservable(), selectedImage: nextButton.rx.tap.map { [weak self] in self?.selectedImage } ) // 버튼 탭 시점 기준 최신 이미지
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    private func bindViewModelOutput(output: LoginViewModel.ProfileOutput) {

        output.signUpResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    coordinator?.showHome()
                case .failure(let error):
                    print("❌ [VC] 회원가입 실패: \(error)")
                }
            }).disposed(by: disposeBag)
    }
}

// MARK: - 앨범 선택 관련
extension ProfileSettingViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
            self.selectedImage = image
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

