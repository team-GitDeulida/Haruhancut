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
    
    func fetchUser(uid: String) -> Observable<User?> {
        return firebaseAuthManager.fetchUser(uid: uid)
    }
    
    func updateUser(_ user: User) -> Observable<Result<User, LoginError>> {
        let path = "users/\(user.uid)"
        let dto = user.toDTO()
        
        return firebaseAuthManager.updateValue(path: path, value: dto)
            .map { success -> Result<User, LoginError> in
                if success {
                    return .success(user)
                } else {
                    return .failure(.signUpError)
                }
            }
    }
    
    func deleteUser(uid: String) -> Observable<Bool> {
        // 1. 유저 정보 읽기(groudId 확보용)
        return firebaseAuthManager.fetchUser(uid: uid)
            .flatMap { (user: User!) -> Observable<Bool> in
                guard let groudId = user.groupId else {
                    // 그룹이 없으면 곧바로 성공
                    return .just(true)
                }
                // 2. 그룹 멤버 경로에서 삭제
                let memberPath = "groups/\(groudId)/members/\(uid)"
                return self.firebaseAuthManager.deleteValue(path: memberPath)
            }
            .flatMap { (groupRemovalSuccess: Bool) -> Observable<Bool> in
                guard groupRemovalSuccess else {
                    // 그룹에서 제거 실패
                    return .just(false)
                }
                // 3 users/{uid} 데이터 삭제
                let userPath = "users/\(uid)"
                return self.firebaseAuthManager.deleteValue(path: userPath)
            }
            .flatMap { (userRemoved: Bool) -> Observable<Bool> in
                guard userRemoved else {
                    // 유저 데이터 삭제 실패
                    return .just(false)
                }
                // 4. Firebase Auth 계정 삭제
                guard let currentUser = Auth.auth().currentUser,
                      currentUser.uid == uid else {
                    return .just(false)
                }
                return Observable<Bool>.create { observer in
                    currentUser.delete { error in
                        observer.onNext(error == nil)
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
    }
    
//    func deleteUser(uid: String) -> Observable<Bool> {
//        let path = "users/\(uid)"
//        return firebaseAuthManager.deleteValue(path: path)
//            .flatMap { (success: Bool) -> Observable<Bool> in
//                if !success {
//                    // DB 삭제 실패시 false 반환
//                    return Observable.just(false)
//                }
//                return Observable<Bool>.create { obs in
//                    Auth.auth().currentUser?.delete { error in
//                        obs.onNext(error == nil)
//                        obs.onCompleted()
//                    }
//                    return Disposables.create()
//                }
//            }
//    }
    
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
