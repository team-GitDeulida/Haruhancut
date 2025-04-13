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
    
    private let loginUsecase: LoginUsecaseProtocol
    
    private(set) var token: String?
    
    init(loginUsecase: LoginUsecase) {
        self.loginUsecase = loginUsecase
    }
    
    struct Input {
        // ViewModel 외부에서 전달받는 입력(Input)을 정의한 구조체
        // - Observable을 사용하는 이유는 ViewModel 내부 로직을 숨기고 단방향으로 이벤트만 전달받기 위함
        // - Subject(PublishSubject, Relay 등)를 외부에 노출하면 ViewController에서 onNext 등을 직접 호출할 수 있어 사이드 이펙트 위험이 존재함
        let kakaoLoginTapped: Observable<Void> // 버튼 탭 이벤트 (읽기 전용 스트림)
    }
    
    struct Output {
        // ViewModel 외부로 전달하는 출력(Output)을 정의한 구조체
        // - 내부에서 Subject 등을 사용하더라도 외부에는 Observable만 노출함으로써
        //   ViewModel의 내부 로직을 캡슐화하고 단방향 데이터 흐름을 유지
        let loginResult: Observable<Result<Void, LoginError>> // 로그인 결과 스트림 (읽기 전용)
    }
    
    func transform(input: Input) -> Output {
        let result = input.kakaoLoginTapped
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.loginWIthKakao()
            }
            // map 안으로 넣어도 되지만 부수효과 분리, 비즈니스로직 구분을 위해 do 처리
            .do(onNext: { [weak self] result in
                if case .success(let token) = result {
                    self?.token = token
                }
            })
            .map { $0.mapToVoid() }
            .observe(on: MainScheduler.instance)
            .share() // 중복 요청 방지
        return Output(loginResult: result)
    }
    
    //    func transform(input: Input) -> Output {
    //        let result = input.kakaoLoginTapped
    //            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
    //                guard let self = self else { return .empty() }
    //                return self.loginUsecase.loginWIthKakao()
    //            }
    //            .flatMapLatest { [weak self] result -> Observable<Result<Void, LoginError>> in
    //                guard let self = self else { return .empty() }
    //
    //                switch result {
    //                case .success(let token):
    //                    self.token = token
    //                    return self.firebaseSignIn(idToken: token)
    //                case .failure(let error):
    //                    return .just(.failure(error))
    //                }
    //            }
    //            .observe(on: MainScheduler.instance)
    //            .share() // 중복 요청 방지
    //        return Output(loginResult: result)
    //    }
        
//    // escaping -> Rx로 래핑
//    private func firebaseSignIn(idToken: String) -> Observable<Result<Void, LoginError>> {
//        let credential = OAuthProvider.credential(
//            providerID: .custom("oidc.kakao"),
//            idToken: idToken,
//            rawNonce: "")
//        
//        return Observable.create { observer in
//            Auth.auth().signIn(with: credential) { _, error in
//                
//                if let _ = error {
//                    observer.onNext(.failure(.loginFailed))
//                } else {
//                    observer.onNext(.success(()))
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//        }
//    }
}


/*
 .map { result in
     // ✅ token은 저장했으니 외부에는 보여주지 않음
     result.map { _ in () }
 }
 
 .map { $0.mapToVoid() }
 */
extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
