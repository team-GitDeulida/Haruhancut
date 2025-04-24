//
//  LoginViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 4/1/25.
//

/*
 reference
 - https://velog.io/@pomme/UIButton-커스텀하기iOS-15.0-ver
 Driver는 RxCocoa가 만든 특별한 옵저버블 타입
 */

import UIKit
import RxSwift

import RxKakaoSDKAuth
import KakaoSDKAuth

import RxKakaoSDKUser
import KakaoSDKUser

final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    weak var coordinator: LoginFlowCoordinator?
    
    private let loginViewModel: LoginViewModel
    
    // MARK: - UI Components
    private lazy var kakaoLoginButton = SocialLoginButton(type: .kakao, title: "카카오로 계속하기")
    
    private lazy var appleLoginButton = SocialLoginButton(type: .apple, title: "Apple로 계속하기")
    
    private lazy var stackView: UIStackView = {
        // 카카오로그인버튼, 애플로그이넙튼 -> 스택뷰에 추가
        let st = UIStackView(arrangedSubviews: [
            kakaoLoginButton,
            appleLoginButton
        ])
        st.spacing = 10
        st.axis = .vertical
        st.distribution = .fillEqually
        st.alignment = .fill
        return st
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        bindViewModel()
    }
    
    // MARK: - Setup UI
    func makeUI() {
        // 배경 색상
        view.backgroundColor = .background
        
        // 스택뷰 -> 뷰에 추가
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 오토레이아웃 제약 추가
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.heightAnchor.constraint(equalToConstant: 130)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Bind ViewModel
    private func bindViewModel() {
        let input = LoginViewModel
            .LoginInput(kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable(),
                   appleLoginTapped: appleLoginButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    // MARK: - Bind VoewModelOutput
    private func bindViewModelOutput(output: LoginViewModel.LoginOutput) {
        output.loginResult
            .drive { result in
                switch result {
                case .success:
                    print("기존 회원 - 홈으로 화면전환")
                    self.coordinator?.showHome()
                case .failure(let error):
                    switch error {
                    case .noUser:
                        print("신규 회원 - 닉네임창으로 화면전환")
                        self.coordinator?.showNickname()
                    default:
                        print("bindViewModelOutput - 로그인 실패")
                    }
                }
            }.disposed(by: disposeBag)
    }
}

#Preview {
    LoginViewController(
        loginViewModel: .init(loginUsecase: LoginUsecase(repository: LoginRepository(
            kakaoLoginManager: KakaoLoginManager.shared, appleLoginManager: AppleLoginManager.shared, firebaseAuthManager: FirebaseAuthManager.shared))))
}
