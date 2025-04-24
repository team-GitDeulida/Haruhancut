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
}

protocol FirebaseAuthManagerProtocol {
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: User) -> Observable<Result<User, LoginError>>
}

// firebaseAuthManager.signIn(providerID: "kakao", idToken: kakaoToken)
// firebaseAuthManager.signIn(providerID: "apple", idToken: appleToken)
final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
    
    static let shared = FirebaseAuthManager()
    private init() {}
    
    private var databaseRef: DatabaseReference {
        Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    }
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        // 비동기 이벤트를 하나의 흐름(Observable)으로 처리하기 위해 클로저 기반 esaping 비동기함수 -> Rx로 래핑
        
        guard let provider = ProviderID(rawValue: prividerID) else {
            return Observable.just(.failure(LoginError.signUpError))
        }
        
        let credential = OAuthProvider.credential(
            providerID: provider.authProviderID,
            idToken: idToken,
            rawNonce: rawNonce ?? "")
        
        return Observable.create { observer in
            Auth.auth().signIn(with: credential) { _, error in
                
                if let error = error {
                    print("❌ Firebase 인증 실패: \(error.localizedDescription)")
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
//                let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
                let userRef = self.databaseRef.child("users").child(firebaseUID)
                
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

extension FirebaseAuthManager {
    
    
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            do {
                let data = try JSONEncoder().encode(value)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                self.databaseRef.child(path).setValue(dict) { error, _ in
                    if let error = error {
                        print("🔥 setValue 실패: \(error.localizedDescription)")
                        observer.onNext(false)
                    } else {
                        observer.onNext(true)
                    }
                    observer.onCompleted()
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    
    /// Read
    /// - Parameters:
    ///   - path: 경로
    ///   - type: 값
    /// - Returns: Observable<T>
    func observeValue<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 존재하지 않음"]))
                    return
                }
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(decoded)
                } catch {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
