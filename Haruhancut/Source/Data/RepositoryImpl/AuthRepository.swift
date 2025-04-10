//
//  AuthRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift

final class AuthRepository: AuthRepositoryProtocol {
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    
    init(kakaoLoginManager: KakaoLoginManagerProtocol) {
        self.kakaoLoginManager = kakaoLoginManager
    }
    
    func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return kakaoLoginManager.login()
    }
}
