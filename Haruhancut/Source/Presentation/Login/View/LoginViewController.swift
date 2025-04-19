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
    
    private let loginViewModel: LoginViewModel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(loginViewModel: LoginViewModel) {
        self.loginViewModel = loginViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Bind ViewModel
    private func bindViewModel() {
        
        // 버튼 탭 이벤트를 viewModel의 Input으로 전달
        let input = LoginViewModel.Input(
            kakaoLoginTapped: kakaoLoginButton.rx.tap.asObservable(),
            appleLoginTapped: appleLoginButton.rx.tap.asObservable(),
            nicknameText: .never(),
            nicknameNextBtnTapped: .never(),
            birthdayDate: .never(),
            birthdayNextTapped: .never()
        )
            
        // viewModel의 transform함수 호출 -> Output 반환
        let output = loginViewModel.transform(input: input)
        bindViewModelOutput(output: output)
    }
    
    // MARK: - Bind VoewModelOutput
    private func bindViewModelOutput(output: LoginViewModel.Output) {
        // 로그인 결과를 구독하여 UI 흐름 처리
        output.loginResult
            .drive { result in
                switch result {
                case .success:
                    // 기존 유저 로그인 성공 -> 홈뷰로 이동
                    self.navigateToNextScreen("home")
                case .failure(let error):
                    switch error {
                    case .noUser:
                        // 신규 유저 -> 닉네임 설정뷰로 이동
                        self.navigateToNextScreen("nickname")
                    default:
                        print("로그인 실패: \(error.description)")
                    }
                }
            }.disposed(by: disposeBag)
    }
    
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
    
    func navigateToNextScreen(_ destination: String) {
        
        switch destination {
        case "home":
            self.navigationController?.setViewControllers([
                HomeViewController(loginViewModel: loginViewModel, homeViewModel: HomeViewModel())
            ], animated: true)
        case "nickname":
            self.navigationController?.setViewControllers([
                NicknameSettingViewController(loginViewModel: loginViewModel)
            ], animated: true)
        case "home_":
            let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate
            let window = sceneDelegate?.window

            let homeVC = HomeViewController(loginViewModel: loginViewModel, homeViewModel: HomeViewModel())
            window?.rootViewController = homeVC
            window?.makeKeyAndVisible()
        default:
            break
        }
    }
}

#Preview {
    LoginViewController(
        loginViewModel: .init(loginUsecase: LoginUsecase(repository: LoginRepository(
            kakaoLoginManager: KakaoLoginManager.shared, appleLoginManager: AppleLoginManager.shared, firebaseAuthManager: FirebaseAuthManager.shared))))
}
