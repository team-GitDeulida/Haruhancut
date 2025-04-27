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

import Lottie

final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    weak var coordinator: LoginFlowCoordinator?
    
    private let loginViewModel: LoginViewModel
    
    // MARK: - UI Components
    
    let animationView: LottieAnimationView = {
        let lottie = LottieAnimationView(name: "LottieCamera")
        return lottie
    }()
    
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
        animationView.play()
        // observeUserState()
    }
    
    // MARK: - Setup UI
    func makeUI() {
        // 배경 색상
        view.backgroundColor = .background
        
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // 위치
            animationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 220),
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 크기
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
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
        /// 버튼을 눌렀을 때 로그인 흐름 결과
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
    
    /// 앱 실행 직후 or 유저 정보가 변할 때
//    private func observeUserState() {
//        loginViewModel.user
//            .asDriver()
//            .drive(onNext: { [weak self] user in
//                guard let self = self else { return }
//                
//                if let user = user {
//                    // 🔥 유저가 생겼으면 자동으로 홈 화면 이동
//                    print("✅ 캐시나 자동 로그인 성공 → 홈으로 이동")
//                    self.coordinator?.showHome()
//                } else {
//                    // 🔥 유저 없으면 로그인 버튼만 보여줌
//                    print("❌ 유저 없음 → 로그인 버튼 보여주는 중")
//                }
//            })
//            .disposed(by: disposeBag)
//    }
}

#Preview {
    LoginViewController(
        loginViewModel: .init(loginUsecase: LoginUsecase(repository: LoginRepository(
            kakaoLoginManager: KakaoLoginManager.shared, appleLoginManager: AppleLoginManager.shared, firebaseAuthManager: FirebaseAuthManager.shared)), groupUsecase: StupGroupUsecase()))
}
