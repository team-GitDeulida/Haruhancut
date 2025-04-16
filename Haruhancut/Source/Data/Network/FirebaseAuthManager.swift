//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/13/25.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift

enum ProviderID: String {
    case kakao
    case apple
    
    var authProviderID: AuthProviderID {
        switch self {
        case .kakao: return .custom("oidc.kakao")
        case .apple: return .apple
        }
    }
    
    /*
    var rawNonce: String {
        switch self {
        case .apple: return NonceGenerator.generate()
        default: return ""
        }
    }
     */
}

protocol FirebaseAuthManagerProtocol {
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
}

// firebaseAuthManager.signIn(providerID: "kakao", idToken: kakaoToken)
// firebaseAuthManager.signIn(providerID: "apple", idToken: appleToken)
final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
    
    static let shared = FirebaseAuthManager()
    private init() {}
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    func authenticateUser(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>> {
        // 비동기 이벤트를 하나의 흐름(Observable)으로 처리하기 위해 클로저 기반 esaping 비동기함수 -> Rx로 래핑
        
        guard let provider = ProviderID(rawValue: prividerID) else {
            print("여기 에러: \(prividerID)")
            return Observable.just(.failure(LoginError.signUpError))
        }
        
        let credential = OAuthProvider.credential(
            providerID: provider.authProviderID,
            idToken: idToken,
            rawNonce: "")
        
        return Observable.create { observer in
            Auth.auth().signIn(with: credential) { _, error in
                
                if let _ = error {
                    observer.onNext(.failure(LoginError.signUpError))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>> {
        
        return Observable.create { observer in
            // 1. Firebase UID확인
            guard let firebaseUID = Auth.auth().currentUser?.uid else {
                observer.onNext(.failure(.authError))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 2. UID 주입
            var userEntity = user
            userEntity.uid = firebaseUID
            
            // 3. Entity -> Dto
            let userDto = userEntity.toDTO()
            
            // 4. Dto -> Dictionary
            do {
                let data = try JSONEncoder().encode(userDto)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                guard let userDict = dict else {
                    observer.onNext(.failure(.authError))
                    observer.onCompleted()
                    return Disposables.create()
                }
                
                // 5. Firebase Realtime DB에 저장
                let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
                let userRef = ref.child("users").child(firebaseUID)
                
                userRef.setValue(userDict) { error, _ in
                    if let error = error {
                        print("🔥 Realtime DB 저장 실패: \(error.localizedDescription)")
                        observer.onNext(.failure(.signUpError))
                    } else {
                        observer.onNext(.success(userEntity))
                    }
                    observer.onCompleted()
                }
            } catch {
                print("❌ JSON 변환 에러: \(error.localizedDescription)")
                observer.onNext(.failure(.signUpError))
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
