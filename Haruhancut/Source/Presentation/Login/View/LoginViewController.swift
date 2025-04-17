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
    private lazy var kakaoLoginButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "Logo Kakao")
        config.baseBackgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
        config.imagePlacement = .leading    // 이미지가 텍스트 왼쪽에 위치
        config.imagePadding = 20            // 이미지와 텍스트 사이 간격
        config.title = "카카오로 계속하기"
        config.baseForegroundColor = .black
        // 폰트 설정
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.hcFont(.semiBold, size: 16)
            // UIFont.systemFont(ofSize: 16, weight: .medium)
            return outgoing
        }
        button.configuration = config
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        // 상태에 따라 배경색 바꾸기
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            if button.isHighlighted {
                config?.baseBackgroundColor = UIColor(red: 0.8, green: 0.72, blue: 0.0, alpha: 1.0) // 눌렸을 때 진한 노랑
            } else {
                config?.baseBackgroundColor = .kakao // 기본 노랑
            }
            button.configuration = config
        }
        return button
    }()
    
    private lazy var appleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.image = UIImage(named: "Logo Apple")
        config.baseBackgroundColor = .white
        config.imagePlacement = .leading    // 이미지가 텍스트 왼쪽에 위치
        config.imagePadding = 20            // 이미지와 텍스트 사이 간격
        config.title = "Apple로 계속하기"
        config.baseForegroundColor = .black
        // 폰트 설정
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.hcFont(.semiBold, size: 16)
            // UIFont.systemFont(ofSize: 16, weight: .medium)
            return outgoing
        }
        button.configuration = config
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        // 상태에 따라 배경색 바꾸기
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            if button.isHighlighted {
                config?.baseBackgroundColor = UIColor(white: 0.9, alpha: 1.0) // 눌렀을 때 약간 회색
            } else {
                config?.baseBackgroundColor = .apple
            }
            button.configuration = config
        }
//        button.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
        return button
    }()
    
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
                HomeViewController(loginViewModel: loginViewModel)
            ], animated: true)
        case "nickname":
            self.navigationController?.setViewControllers([
                NicknameSettingViewController(loginViewModel: loginViewModel)
            ], animated: true)
        case "home_":
            let sceneDelegate = UIApplication.shared.connectedScenes
                .first?.delegate as? SceneDelegate
            let window = sceneDelegate?.window

            let homeVC = HomeViewController(loginViewModel: loginViewModel)
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
