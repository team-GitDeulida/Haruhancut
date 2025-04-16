//
//  LoginUsecase.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

import Foundation
import RxSwift

protocol LoginUsecaseProtocol {
    func loginWIthKakao() -> Observable<Result<String, LoginError>>
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
}

final class LoginUsecase: LoginUsecaseProtocol {
    
    private let repository: LoginRepository
    init(repository: LoginRepository) {
        self.repository = repository
    }
    
    /// 카카오 로그인
    /// - Returns: 카카오 로그인 토큰
    func loginWIthKakao() -> Observable<Result<String, LoginError>>  {
        return repository.loginWithKakao()
    }
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>> {
        return repository.authenticateUser(prividerID: prividerID, idToken: idToken)
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        return repository.registerUserToRealtimeDatabase(user: user)
    }
}

final class StubLoginUsecase: LoginUsecaseProtocol {
    func loginWIthKakao() -> RxSwift.Observable<Result<String, LoginError>> {
        return .just(.success("stub-token"))
    }
    
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>> {
        return .just(.success(()))
    }
    
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        return .just(.success(User(
            uid: "testUser",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "관리자",
            birthdayDate: .now, gender: .male,
            isPushEnabled: true)))
    }
}
