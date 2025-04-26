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

final class LoginViewModel {
    private let loginUsecase: LoginUsecaseProtocol
    private let disposeBag = DisposeBag()
    private(set) var token: String?
    
    // 이벤트를 방출하는 내부 트리거
    private let signUpResultRelay = PublishRelay<Result<Void, LoginError>>()
    
    var user = BehaviorRelay<User?>(value: nil)
    let isNewUser = BehaviorRelay<Bool>(value: false)

    init(loginUsecase: LoginUsecaseProtocol) {
        self.loginUsecase = loginUsecase
        
        // 앱 실행 시 캐시된 유저 불러오기
        if let cachedUser = UserDefaultsManager.shared.loadUser() {
            print("✅ 캐시에서 불러온 유저: \(cachedUser)")
            self.user.accept(cachedUser)
        } else {
            print("❌ 캐시에 저장된 유저 없음")
        }
        
        fetchMyInfo()
        
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
                    return self.loginUsecase.fetchUserFromDatabase()
                        .map { user -> Result<Void, LoginError> in
                            /// 기존 유저라면
                            if let user = user {
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                UserDefaultsManager.shared.markSignupCompleted()
                                return .success(())
                            } else {
                                /// 신규 유저라면
                                self.user.accept(User.empty(loginPlatform: .kakao))
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
                    return self.loginUsecase.fetchUserFromDatabase()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                /// 기존 회원
                                self.user.accept(user)
                                UserDefaultsManager.shared.saveUser(user)
                                UserDefaultsManager.shared.markSignupCompleted()
                                return .success(())
                            } else {
                                /// 신규 회원
                                self.user.accept(User.empty(loginPlatform: .apple))
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
    
    private func fetchMyInfo() {
        
        // 1. 현재 로그인된 유저 UID 가져오기
        guard let uid = Auth.auth().currentUser?.uid else {
            print("🔸 로그인된 유저 없음")
            return
        }

        // 2. Realtime Database 참조 설정
        let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
        let userRef = ref.child("users").child(uid)
        
        // 3. 데이터 fetch
        userRef.observeSingleEvent(of: .value) { [weak self] snapshot, _  in
            guard let value = snapshot.value as? [String: Any] else {
                print("❌ 사용자 정보 없음")
                return
            }
            
            do {
                // 4. Dictionary → Data → UserDTO → User
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let dto = try JSONDecoder().decode(UserDTO.self, from: data)
                let user = dto.toModel()
                guard let self = self else { return }
                if let user = user {
                    self.user.accept(user)
                    UserDefaultsManager.shared.saveUser(user)
                }
                print("✅ 기존 유저 정보 불러옴: \(String(describing: user))")
            } catch {
                print("❌ 유저 디코딩 실패: \(error.localizedDescription)")
            }
        }
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
                if var currentUser = self?.user.value {
                    currentUser.nickname = nickname
                    self?.user.accept(currentUser)
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
        let signUpResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: BirthdayInput) -> BirthdayOutput {
        let signUpResult = signUpResultRelay
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        // 생일 다음 버튼
        input.nextBtnTapped
            .withLatestFrom(input.birthdayDate)
            .bind(onNext: { [weak self] birthdayDate in
                if var currentUser = self?.user.value {
                    currentUser.birthdayDate = birthdayDate
                    self?.user.accept(currentUser)
                    
                    if let user = self?.user.value {
                        self?.registerUser(user: user)
                    }
                }
            }).disposed(by: disposeBag)
        
        return BirthdayOutput(signUpResult: signUpResult)
    }
    
    private func registerUser(user: User) {
        loginUsecase
            .registerUserToRealtimeDatabase(user: user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user.accept(user)
                     UserDefaultsManager.shared.saveUser(user)
                     UserDefaultsManager.shared.markSignupCompleted()
                }
                return result.mapToVoid()
            }
            .bind(to: signUpResultRelay)
            .disposed(by: disposeBag)
    }
}

final class StubLoginViewModel {
    
}

extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
