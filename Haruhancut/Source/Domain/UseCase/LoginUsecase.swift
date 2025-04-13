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
}

final class LoginUsecase: LoginUsecaseProtocol {
    private let repository: LoginRepository
    init(repository: LoginRepository) {
        self.repository = repository
    }
    
    func loginWIthKakao() -> Observable<Result<String, LoginError>>  {
        return repository.loginWithKakao()
            .flatMap { [weak self] result in
                guard let self = self else {
                    return Observable.just(Result<String, LoginError>.failure(.noTokenKakao))
                }
                return self.handleLoginFlow(providerID: "kakao", result: result)
            }
    }
    
    func loginWIthKakao_save() -> Observable<Result<String, LoginError>>  {
        return repository.loginWithKakao()
            .flatMap { result in
                switch result {
                case .success(let idToken):
                    return FirebaseAuthManager.shared
                        .signIn(prividerID: "kakao", idToken: idToken)
                        .map { firebaseResult in
                            switch firebaseResult {
                            case .success:
                                return Result<String, LoginError>.success(idToken) // ✅ 명시
                            case .failure:
                                return Result<String, LoginError>.failure(LoginError.noTokenKakao)
                            }
                        }

                case .failure(let error):
                    return .just(.failure(error))
                }
            }
    }
    
    // MARK: - 공통 Firebase 처리 로직
    private func handleLoginFlow(providerID: String, result: Result<String, LoginError>) -> Observable<Result<String, LoginError>> {
        switch result {
        case .success(let idToken):
            return FirebaseAuthManager.shared
                .signIn(prividerID: providerID, idToken: idToken)
                .map { firebaseResult in
                    switch firebaseResult {
                    case .success:
                        return Result<String, LoginError>.success(idToken) // 🔧 타입 명시
                    case .failure:
                        return Result<String, LoginError>.failure(.noTokenKakao)
                    }
                }
        case .failure(let error):
            return .just(Result<String, LoginError>.failure(error)) // 🔧 타입 명시
        }
    }
}
