//
//  KakaoLoginManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift
import KakaoSDKUser
import RxKakaoSDKUser

protocol KakaoLoginManagerProtocol {
    func login() -> Observable<Result<String, LoginError>>
}

final class KakaoLoginManager: KakaoLoginManagerProtocol {
    
    // MARK: - SingleTon
    static let shared = KakaoLoginManager()
    
    /// 카카오 로그인
    /// - Returns: Id 토큰을 방출하는 스트림
    func login() -> Observable<Result<String, LoginError>>  {
        let loginObservable = UserApi.isKakaoTalkLoginAvailable() ?
        UserApi.shared.rx.loginWithKakaoTalk() : UserApi.shared.rx.loginWithKakaoAccount()
        
        return loginObservable
            .map { token in
                guard let idToken = token.idToken else {
                    return .failure(.noTokenKakao)
                }
                return .success(idToken)
            }
            .catch { error in
                return .just(.failure(.sdkKakao(error)))
            }
    }
    
    func loginSave() -> Observable<Result<String, LoginError>> {
        
        if UserApi.isKakaoTalkLoginAvailable() {
            return UserApi.shared.rx.loginWithKakaoTalk()
                .map {
                    guard let idToken = $0.idToken else {
                        return .failure(LoginError.noTokenKakao)
                    }
                    return .success(idToken)
                }
        } else {
            return UserApi.shared.rx.loginWithKakaoAccount()
                .map {
                    guard let idToken = $0.idToken else {
                        return .failure(LoginError.noTokenKakao)
                    }
                    return .success(idToken)
                }
        }
    }
}
