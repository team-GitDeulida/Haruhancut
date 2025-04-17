//
//  LoginRepository.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift
import FirebaseAuth
import FirebaseDatabase

final class LoginRepository: LoginRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let appleLoginManager: AppleLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    
    init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        appleLoginManager: AppleLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManagerProtocol
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.firebaseAuthManager = firebaseAuthManager
        self.appleLoginManager = appleLoginManager
    }
    
    func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return kakaoLoginManager.login()
    }
    
    func loginWithApple() -> Observable<Result<(String, String), LoginError>> {
        return appleLoginManager.login()
    }
    
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        return firebaseAuthManager.authenticateUser(prividerID: prividerID, idToken: idToken, rawNonce: rawNonce)
    }
    
    func registerUserToRealtimeDatabase(user: User) -> RxSwift.Observable<Result<User, LoginError>> {
        return firebaseAuthManager.registerUserToRealtimeDatabase(user: user)
    }
    
    func fetchUserFromDatabase() -> Observable<User?> {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .just(nil)
        }

        return Observable.create { observer in
            let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
            let userRef = ref.child("users").child(uid)

            userRef.observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value as? [String: Any] else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }

                do {
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let dto = try JSONDecoder().decode(UserDTO.self, from: data)
                    observer.onNext(dto.toModel())
                } catch {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
