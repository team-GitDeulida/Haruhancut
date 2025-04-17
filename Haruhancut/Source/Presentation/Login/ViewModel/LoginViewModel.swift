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
    private let disposeBag = DisposeBag()
    
    var user: User?
    
    private let loginUsecase: LoginUsecaseProtocol
    private(set) var token: String?
    
    init(loginUsecase: LoginUsecaseProtocol) {
        self.loginUsecase = loginUsecase
        
        // 앱 실행 시 캐시된 유저 불러오기
        if let cachedUser = UserDefaultsManager.shared.loadUser() {
            self.user = cachedUser
        }
        fetchMyInfo()
    }
    
    // 이벤트를 방출하는 내부 트리거
    private let signUpResultRelay = PublishRelay<Result<Void, LoginError>>()
    
    struct Input { // View에서 발생할 Input 이벤트(Stream)들
        // ViewModel 외부에서 전달받는 입력(Input)을 정의한 구조체
        // - Observable을 사용하는 이유는 ViewModel 내부 로직을 숨기고 단방향으로 이벤트만 전달받기 위함
        // - Subject(PublishSubject, Relay 등)를 외부에 노출하면 ViewController에서 onNext 등을 직접 호출할 수 있어 사이드 이펙트 위험이 존재함
        // MARK: - LoginView - 버튼 탭 이벤트 (읽기 전용 스트림)
        let kakaoLoginTapped: Observable<Void>
        let appleLoginTapped: Observable<Void>
        
        // MARK: - NicknameSettingView
        let nicknameText: Observable<String>
        let nicknameNextBtnTapped: Observable<Void>

        // MARK: - BirthdaySettingView
        let birthdayDate: Observable<Date>
        let birthdayNextTapped: Observable<Void>
    }
    
    struct Output {  // View에 반영시킬 Output Stream들
        // ViewModel 외부로 전달하는 출력(Output)을 정의한 구조체
        // - 내부에서 Subject 등을 사용하더라도 외부에는 Observable만 노출함으로써
        //   ViewModel의 내부 로직을 캡슐화하고 단방향 데이터 흐름을 유지
        // MARK: - 성공/실패에 따라 view분기처리 하기 위해 Result 사용
        // MARK: - 에러를 UI 흐름과 함꼐 다루기 위해 Result 사용
        // MARK: - 유저리스트, nicknameText등 단순 데이터 스트림 필요시는 Result x
        let loginResult: Driver<Result<Void, LoginError>> // 로그인 결과 스트림 (읽기 전용)
        let moveToBirthday: Driver<Void>
        let isNicknameValid: Driver<Bool>
        //let moveToHome: Driver<Void>
        let signUpResult: Driver<Result<Void, LoginError>>
    }
    
    func transform(input: Input) -> Output {
        let kakaoLoginResult = input.kakaoLoginTapped
            // 카카오 로그인 -> idToken 발급
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWIthKakao()
            }
            // 토큰 발급 후 -> FirebaseAuth 인증
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .just(.failure(.signUpError)) }
                switch result {
                case .success(let token):
                    self.token = token
                    return self.loginUsecase.authenticateUser(prividerID: "kakao", idToken: token, rawNonce: nil)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            // 인증 성공 시 -> Realtime Database에서 인증 조회
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUsecase.fetchUserFromDatabase()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                print("기존유저입니다")
                                // 기존 유저 -> 유저 정보 저장 후 .success 반환
                                self.user = user
                                UserDefaultsManager.shared.saveUser(user)
                                UserDefaultsManager.shared.markSignupCompleted()
                                return .success(())
                            } else {
                                print("신규유저입니다")
                                // 신규 유저 -> 빈 유저 모델로 초기화 후 .noUser 반환 -> 회원가입 플로우 진입
                                self.user = User.empty(loginPlatform: .kakao)
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
    
        let appleLoginResult = input.appleLoginTapped
            // Observable → Observable 연결
            .flatMapLatest { [weak self] _ -> Observable<Result<(String, String), LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWithApple()
            }
            // 토큰 발급 후 -> FirebaseAuth 인증
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .just(.failure(.signUpError)) }
                switch result {
                case .success(let (token, rawNonce)):
                    self.token = token
                    return self.loginUsecase.authenticateUser(prividerID: "apple", idToken: token, rawNonce: rawNonce)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            // 인증 성공 시 -> Realtime Database에서 인증 조회
            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    return self.loginUsecase.fetchUserFromDatabase()
                        .map { user -> Result<Void, LoginError> in
                            if let user = user {
                                // 기존 유저 -> 유저 정보 저장 후 .success 반환
                                self.user = user
                                UserDefaultsManager.shared.saveUser(user)
                                UserDefaultsManager.shared.markSignupCompleted()
                                return .success(())
                            } else {
                                // 신규 유저 -> 빈 유저 모델로 초기화 후 .noUser 반환 -> 회원가입 플로우 진입
                                self.user = User.empty(loginPlatform: .apple)
                                return .failure(.noUser)
                            }
                        }
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
        
        // 두 로그인 결과 병합 (카카오 or 애플)
        let mergedLoginResult = Observable
            .merge(kakaoLoginResult, appleLoginResult)
            .asDriver(onErrorJustReturn: .failure(.signUpError)) // ✅ Driver는 에러 허용 X → 기본값 처리 필요
        
        // 닉네임 입력 후 다음 버튼 탭 → 생일 뷰로 이동
        let nicknameNext = input.nicknameNextBtnTapped
            .withLatestFrom(input.nicknameText)
            .do(onNext: { [weak self] nickname in
                self?.user?.nickname = nickname
            })
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        // 닉네임 유효성 체크
        let isNicknameValid = input.nicknameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출
        
        // 회원가입 결과 전달
        let signUpResult = signUpResultRelay
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        // ✅ moveToHome 제거 → 내부에서 subscribe 처리 즉 ViewModel 내부에서만 트리거 처리
        input.birthdayNextTapped
            .withLatestFrom(input.birthdayDate)
            .subscribe(onNext: { [weak self] birthdate in
                guard let self = self else { return }
                self.user?.birthdayDate = birthdate
                if let user = self.user{
                    registerUser(user: user)
                }
            }).disposed(by: disposeBag)

        return Output(loginResult: mergedLoginResult, moveToBirthday: nicknameNext, isNicknameValid: isNicknameValid, signUpResult: signUpResult)
    }
    
    /// 신규 유저 회원가입 비즈니스 로직
    /// - Parameters:
    ///   - user: 신규 유저
    ///   - idToken: 유저 토큰
    /*
    private func authenticateAndRegisterUser(user: User, idToken: String, rawNonce: String?) {
        loginUsecase
            // 1. FirebaseAuth 진행 // Observable<Result<Void, LoginError>>
            .authenticateUser(prividerID: user.loginPlatform.rawValue, idToken: idToken, rawNonce: rawNonce)
            // 결과에 따라 다른 Observable 흐름으로 전환
            .flatMap { [weak self] result -> Observable<Result<User, LoginError>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success:
                    // 2. 인증 성공시 유저 등록
                    return self.loginUsecase.registerUserToRealtimeDatabase(user: user)
                    /*
                    return Observable.just(())
                            .delay(.milliseconds(200), scheduler: MainScheduler.instance)
                            .flatMap { self.loginUsecase.registerUserToRealtimeDatabase(user: user) }
                     */
                case .failure:
                    return .just(.failure(.authError))
                }
            }
            .map { [weak self] result in
                if case .success(let user) = result {
                    self?.user = user
                    print("유저 업데이트: \(user)")
                    UserDefaultsManager.shared.saveUser(user)
                    UserDefaultsManager.shared.markSignupCompleted()
                }
                return result.mapToVoid()
            }
            .bind(to: signUpResultRelay)
            .disposed(by: disposeBag)
    }
     */
    
    private func registerUser(user: User) {
        loginUsecase
            .registerUserToRealtimeDatabase(user: user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user = user
                    UserDefaultsManager.shared.saveUser(user)
                    UserDefaultsManager.shared.markSignupCompleted()
                }
                return result.mapToVoid()
            }
            .bind(to: signUpResultRelay)
            .disposed(by: disposeBag)
    }
    
    private func fetchMyInfo() {
        
        if let cached = UserDefaultsManager.shared.loadUser() {
                print("✅ 캐시에서 불러온 유저: \(cached.nickname)")
                self.user = cached
                return
            }
        
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
                self?.user = user
                 print("✅ 기존 유저 정보 불러옴: \(String(describing: user))")
            } catch {
                print("❌ 유저 디코딩 실패: \(error.localizedDescription)")
            }
        }
    }

}

final class StubLoginViewModel {
    
}

extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
