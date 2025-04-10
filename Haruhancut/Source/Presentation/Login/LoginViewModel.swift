//
//  LoginViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/8/25.
//

import Foundation
import RxSwift
import RxCocoa
import KakaoSDKUser
import RxKakaoSDKUser
import RxKakaoSDKAuth
import KakaoSDKAuth

final class LoginViewModel {
    
    private let loginUsecase: LoginUsecaseProtocol
    
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
        let loginResult: Observable<Result<String, LoginError>> // 로그인 결과 스트림 (읽기 전용)
    }
    
    func transform(input: Input) -> Output {
        let result = input.kakaoLoginTapped
            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
                guard let self = self else { return .empty() }
                return self.loginUsecase.execute()
            }
            .observe(on: MainScheduler.instance)
            .share() // 중복 요청 방지
        return Output(loginResult: result)
    }
}
