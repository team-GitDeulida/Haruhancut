//
//  LoginRepositoryProtocol.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift
import UIKit

protocol LoginRepositoryProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
    func loginWithApple() -> Observable<Result<(String, String), LoginError>>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
    func fetchUserInfo() -> Observable<User?>
    func fetchUser(uid: String) -> Observable<User?>
    func updateUser(_ user: User) -> Observable<Result<User, LoginError>>
    func deleteUser(uid: String) -> Observable<Bool>
    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>>
}
