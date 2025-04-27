//
//  LoginRepositoryProtocol.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift

protocol LoginRepositoryProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
    func fetchUserInfo() -> Observable<User?>
}
