//
//  LoginViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

import RxSwift
import RxCocoa

import KakaoSDKUser
import RxKakaoSDKUser
import RxKakaoSDKAuth
import KakaoSDKAuth
import UIKit

final class LoginViewModel {
    private let loginUsecase: LoginUsecaseProtocol
    private let disposeBag = DisposeBag()
    private(set) var token: String?
    
    // 이벤트를 방출하는 내부 트리거
    private let signUpResultRelay = PublishRelay<Result<Void, LoginError>>()
    
    var user = BehaviorRelay<User?>(value: nil)
    let isNewUser = BehaviorRelay<Bool>(value: false)

    init(
        loginUsecase: LoginUsecaseProtocol
        // groupUsecase: GroupUsecaseProtocol
    ) {
        self.loginUsecase = loginUsecase
        // self.groupUsecase = groupUsecase
        
        // ✅ 1. 캐시된 유저 불러오기
        if let cachedUser = UserDefaultsManager.shared.loadUser() {
            print("✅ loginVM - 캐시에서 불러온 유저: \(cachedUser)")
            self.user.accept(cachedUser)
            
            // ✅ 2. 서버에서 유저 불러오기
            fetchUserInfo()
        }
    }
    
    // MARK: - LoginViewController
    struct LoginInput {
        let kakaoLoginTapped: Observable<Void>
        let appleLoginTapped: Observable<Void>
    }
    
    struct LoginOutput {
        let loginResult: Driver<Result<Void, LoginError>>
    }
    
    /// UI와 바인딩할 목적이면 return 아니면 내부에샤 input.xxx진행
    func transform(input: LoginInput) -> LoginOutput {
        let kakaoResult = input.kakaoLoginTapped
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWIthKakao() // Observable<Result<String, LoginError>>
            }
            // 토큰 발급 후 -> FirebaseAuth 인증
            /// result - 앞서 .flatMapLatest에서 전달되는 스트림의 값 Result<String, LoginError>
            /// 클로저 최종 리턴 타입 -> Observable<Result<Void, LoginError>>
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in /// Result<String, LoginError>
                guard let self = self else { return .just(.failure(.signUpError)) }
                switch result {
                case .success(let token):
                    self.token = token
                    return self.loginUsecase.authenticateUser(prividerID: "kakao", idToken: token, rawNonce: nil) /// Observable<Result<Void, LoginError>>
                case .failure(let error):
                    return .just(.failure(error))                                                                 /// Observable<Result<Void, LoginError>>
                }
            }
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUsecase.fetchUserInfo()
                        .map { user -> Result<Void, LoginError> in
                            /// 기존 유저라면
                            if let user = user {
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                
                                return .success(())
                                
                            } else {
                                /// 신규 유저라면
                                self.user.accept(User.empty(loginPlatform: .kakao))
                                if let user = user {
                                    UserDefaultsManager.shared.saveUser(user)
                                }
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
        
        let appleResult = input.appleLoginTapped
            .flatMapLatest { [weak self] _ -> Observable<Result<(String, String), LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWithApple() // Observable<Result<String, LoginError>>
            }
            // 토큰 발급 후 -> FirebaseAuth 인증
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in /// Result<String, LoginError>
                guard let self = self else { return .just(.failure(.signUpError)) }
                switch result {
                case .success(let (token, rawNonce)):
                    self.token = token
                    return self.loginUsecase.authenticateUser(prividerID: "apple", idToken: token, rawNonce: rawNonce)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUsecase.fetchUserInfo()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                /// 기존 회원
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                
                                return .success(())
                            } else {
                                /// 신규 회원
                                self.user.accept(User.empty(loginPlatform: .apple))
                                if let user = user {
                                    UserDefaultsManager.shared.saveUser(user)
                                }
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
        
        let mergedResult = Observable
            .merge(kakaoResult, appleResult)
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        return LoginOutput(loginResult: mergedResult)
    }
     
    private func fetchUserInfo() {
        loginUsecase.fetchUserInfo()
            .bind(onNext: { [weak self] user in
                guard let self = self else { return }
                if let user = user {
                    print("✅ loginVM - 서버에서 불러온 유저: \(user)")
                    self.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                } else {
                    print("❌ 사용자 정보 없음 캐시 삭제 진행")
                    self.user.accept(nil)
                    UserDefaultsManager.shared.removeUser()
                    UserDefaultsManager.shared.removeGroup()
                    
                    // 강제 로그아웃 유도
                    NotificationCenter.default.post(name: .userForceLoggedOut, object: nil)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - NicknameViewController
    struct NicknameInput {
         let nicknameText: Observable<String>
         let nextBtnTapped: Observable<Void>
    }
    
    struct NicknameOutput {
        let moveToBirthday: Driver<Void>
        let isNicknameValid: Driver<Bool>
    }
    
    func transform(input: NicknameInput) -> NicknameOutput {
        
        // 닉네임 다음 버튼 입력 이벤트 감지(viewModel이 구독)
        let nextBtnTapped = input.nextBtnTapped
            .withLatestFrom(input.nicknameText)
            .do(onNext: { [weak self] nickname in
                guard let self = self else { return }
                if var currentUser = self.user.value {
                    currentUser.nickname = nickname
                    self.user.accept(currentUser)
                }
            })
            .map { _ in } /// Observable<Void>
            .asDriver(onErrorDriveWith: .empty())
        
        // 닉네임 유효성
        let isNicknameValid = input.nicknameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출

        return NicknameOutput(moveToBirthday: nextBtnTapped, isNicknameValid: isNicknameValid)
        
        
    }
    
    // MARK: - BirthdayViewController
    struct BirthdayInput {
        let birthdayDate: Observable<Date>
        let nextBtnTapped: Observable<Void>
    }
    
    struct BirthdayOutput {
        let moveToProfile: Driver<Void>
    }
    
    func transform(input: BirthdayInput) -> BirthdayOutput {
        let nextBtnTapped = input.nextBtnTapped
            .withLatestFrom(input.birthdayDate)
            .do(onNext: { [weak self] birthdayDate in
                guard let self = self else { return }
                if var currentUser = self.user.value {
                    currentUser.birthdayDate = birthdayDate
                    self.user.accept(currentUser)
                }
            })
            .map { _ in } /// Observable<Void>
            .asDriver(onErrorDriveWith: .empty())
        
        return BirthdayOutput(moveToProfile: nextBtnTapped)
    }
    
    // MARK: - ProfileSettingViewController
    struct ProfileInput {
        let nextBtnTapped: Observable<Void>
        let selectedImage: Observable<UIImage?>
    }
    
    struct ProfileOutput {
        let signUpResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: ProfileInput) -> ProfileOutput {
        
        let signUpResult = signUpResultRelay
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        // A.withLatestFrom(B)
        // A가 이벤트를 발생시킬 때, B의 가장 최근 값을 가져온다
        input.nextBtnTapped
            .withLatestFrom(input.selectedImage)
            .flatMapLatest { [weak self] image -> Observable<Result<Void, LoginError>> in
                
                guard let self = self,
                      let currentUser = self.user.value else {
                    return Observable.just(.failure(.signUpError))
                }
                
                // 회원가입 진행
                return self.registerUser(user: currentUser)
                    .flatMap { result -> Observable<Result<Void, LoginError>> in
                        switch result {
                        case .success:
                            guard let user = self.user.value else {
                                return Observable.just(.failure(.signUpError))
                            }
                            // 이미지가 있다변 업로드 -> user 업데이트
                            if let image = image {
                                return self.loginUsecase
                                    .uploadImage(user: user, image: image)
                                    .flatMap { result -> Observable<Result<Void, LoginError>> in
                                        switch result {
                                        case .success(let url):
                                            var updatedUser = user
                                            updatedUser.profileImageURL = url.absoluteString
                                            return self.updateUser(user: updatedUser)
                                        case .failure(let error):
                                            return .just(.failure(error))
                                        }
                                    }
                            } else {
                                return Observable.just(.success(()))
                            }
                        case .failure(let error):
                            return Observable.just(.failure(error))
                        }
                    }
                
            }
            .bind(to: signUpResultRelay)
            .disposed(by: disposeBag)
        return ProfileOutput(signUpResult: signUpResult)
    }
    
    private func registerUser(user: User) -> Observable<Result<Void, LoginError>> {
        loginUsecase
            .registerUserToRealtimeDatabase(user: user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                }
                return result.mapToVoid()
            }
    }
    
    private func updateUser(user: User) -> Observable<Result<Void, LoginError>> {
        UserDefaultsManager.shared.saveUser(user)
        return loginUsecase.updateUser(user)
    }
}

final class StubLoginViewModel {
    
}

extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}

// MARK: - 강제 로그아웃
extension Notification.Name {
    static let userForceLoggedOut = Notification.Name("userForceLoggedOut")
}
