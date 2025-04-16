//
//  LoginRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift

final class LoginRepository: LoginRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManager
    
    init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManager
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.firebaseAuthManager = firebaseAuthManager
    }
    
    func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return kakaoLoginManager.login()
    }
    
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID, idToken: idToken)
    }
    
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.registerUserToRealtimeDatabase(user: user)
    }

}
