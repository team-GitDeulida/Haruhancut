//
//  LoginViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/8/25.
//

import Foundation
import FirebaseAuth

import RxSwift
import RxCocoa

import KakaoSDKUser
import RxKakaoSDKUser
import RxKakaoSDKAuth
import KakaoSDKAuth


final class LoginViewModel {
    
    var user: User?
    
    private let loginUsecase: LoginUsecaseProtocol
    private(set) var token: String?
    
    init(loginUsecase: LoginUsecaseProtocol) {
        self.loginUsecase = loginUsecase
    }
    
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
        let moveToHome: Driver<Void>
    }
    
    func transform(input: Input) -> Output {
        let kakaoLoginResult = input.kakaoLoginTapped
            // Observable → Observable 연결
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWIthKakao()
            }
            // map 안으로 넣어도 되지만 부수효과 분리, 비즈니스로직 구분을 위해 do 처리
            .do(onNext: { [weak self] result in
                if case .success(let token) = result {
                    guard let self = self else { return }
                    self.token = token
                    self.user = User.empty(uid: token, loginPlatform: .kakao)
                }
            })
            .map { $0.mapToVoid() }

        let appleLoginResult = input.appleLoginTapped
            // Observable → Observable 연결
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWIthKakao()
            }
            // map 안으로 넣어도 되지만 부수효과 분리, 비즈니스로직 구분을 위해 do 처리
            .do(onNext: { [weak self] result in
                if case .success(let token) = result {
                    guard let self = self else { return }
                    self.token = token
                    self.user = User.empty(uid: token, loginPlatform: .kakao)
                }
            })
            .map { $0.mapToVoid() }
        
        let mergedLoginResult = Observable
            .merge(kakaoLoginResult, appleLoginResult)
            .asDriver(onErrorJustReturn: .failure(.signUpError)) // ✅ Driver는 에러 허용 X → 기본값 처리 필요
        
        // MARK: - 닉네임 입력 후 다음 버튼 탭 → 생일 뷰로 이동
        let nicknameNext = input.nicknameNextBtnTapped
            .withLatestFrom(input.nicknameText)
            .do(onNext: { [weak self] nickname in
                self?.user?.nickname = nickname
            })
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        let birthdayNext = input.birthdayNextTapped
            .withLatestFrom(input.birthdayDate)
            .do(onNext: { [weak self] birthdate in
                self?.user?.birthdayDate = birthdate
            })
            .map { _ in () }
            .asDriver(onErrorDriveWith: .empty())
        
        let isNicknameValid = input.nicknameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출

        return Output(loginResult: mergedLoginResult, moveToBirthday: nicknameNext, isNicknameValid: isNicknameValid, moveToHome: birthdayNext)
    }
}

final class StubLoginViewModel {
    
}

extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
