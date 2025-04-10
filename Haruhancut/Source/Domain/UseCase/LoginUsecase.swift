//
//  LoginUsecase.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

import Foundation
import RxSwift

protocol LoginUsecaseProtocol {
    func execute() -> Observable<Result<String, LoginError>>
}

final class LoginUsecase: LoginUsecaseProtocol {
    private let repository: AuthRepository
    init(repository: AuthRepository) {
        self.repository = repository
    }
    
    func execute() -> Observable<Result<String, LoginError>>  {
        return repository.loginWithKakao()
    }
}
