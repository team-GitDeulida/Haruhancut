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
import UIKit

final class LoginRepository: LoginRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManagerProtocol
    private let appleLoginManager: AppleLoginManagerProtocol
    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    
    init(
        kakaoLoginManager: KakaoLoginManagerProtocol,
        appleLoginManager: AppleLoginManagerProtocol,
        firebaseAuthManager: FirebaseAuthManagerProtocol,
        firebaseStorageManager: FirebaseStorageManagerProtocol
    ) {
        self.kakaoLoginManager = kakaoLoginManager
        self.firebaseAuthManager = firebaseAuthManager
        self.appleLoginManager = appleLoginManager
        self.firebaseStorageManager = firebaseStorageManager
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
    
    func fetchUserInfo() -> Observable<User?> {
        return firebaseAuthManager.fetchUserInfo()
    }
    
    func updateUser(_ user: User) -> Observable<Result<Void, LoginError>> {
        let path = "users/\(user.uid)"
        let dto = user.toDTO()
        
        return firebaseAuthManager.updateValue(path: path, value: dto)
            .map { success -> Result<Void, LoginError> in
                if success {
                    UserDefaultsManager.shared.saveUser(user)
                    return .success(())
                } else {
                    return .failure(.signUpError)
                }
            }
    }
    

    func uploadImage(user: User, image: UIImage) -> Observable<Result<URL, LoginError>> {
        let path = "users/\(user.uid)/profile.jpg"
        
        return firebaseStorageManager.uploadImage(image: image, path: path)
            .map { url in
                if let url = url {
                    return .success(url)
                } else {
                    return .failure(.signUpError)
                }
            }
    }
}
