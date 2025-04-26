//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/13/25.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import RxCocoa

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
    func createGroup(groupName: String) -> Observable<Result<String, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
}

final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
    
    static let shared = FirebaseAuthManager()
    private init() {}
    
    private var databaseRef: DatabaseReference {
        Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    }
}

// MARK: - 유저 관련
extension FirebaseAuthManager {
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

// MARK: - 제네릭 함수
extension FirebaseAuthManager {
    
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in

            guard let dict = value.toDictionary() else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.databaseRef.child(path).setValue(dict) { error, _ in
                if let error = error {
                    print("🔥 setValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
                
            return Disposables.create()
        }
    }
    
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    func setValue_save<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            do {
                 let data = try JSONEncoder().encode(value)
                 let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                /*
                guard let dict = value.toDictionary() else {
                    observer.onNext(false)
                    observer.onCompleted()
                    return Disposables.create()
                }
                 */
                
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
    func observeValue_save<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
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

// MARK: - 그룹 관련
extension FirebaseAuthManager {
    
    
    /// 그룹 Creaate
    /// - Parameter groupName: 그룹 이름
    /// - Returns: Observable<Result<그룹Id, GroupError>>
    func createGroup(groupName: String) -> Observable<Result<String, GroupError>> {
        let newGroupRef = self.databaseRef.child("groups").childByAutoId()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return Observable.just(.failure(.makeHostError))
        }
        
        let groupData = HCGroup(
            groupId: newGroupRef.key ?? "",
            groupName: groupName,
            createdAt: Date(),
            hostUserId: currentUserId,
            posts: []
        )
        
        /// 이미 Observable이 있다면 .map { }으로 변환 후 바로 리턴
        /// 직접 데이터를 방출해야 한다면 Observable.create { observer in ... } 안에서 onNext 후 리턴
        return setValue(path: "groups/\(newGroupRef.key ?? "")", value: groupData.toDTO())
        /// Observable → 다른 Observable 로 바꿔야 하면 flatMap
        /// Observable → 값을 가공(변환)만 하면 map
            .map { success -> Result<String, GroupError> in
                if success {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    return .success(newGroupRef.key ?? "")
                } else {
                    print("❌ 그룹 생성 실패")
                    return .failure(.makeHostError)
                }
            }
    }
    
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        return Observable.create { observer in
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                print("❌ 현재 로그인된 유저 없음")
                observer.onNext(.failure(.makeHostError))
                observer.onCompleted()
                return Disposables.create()
            }
            
            let userRef = self.databaseRef.child("users").child(currentUserId)
            userRef.updateChildValues(["groupId": groupId]) { error, _ in
                if let error = error {
                    print("❌ groupId 업데이트 실패: \(error.localizedDescription)")
                    observer.onNext(.failure(.makeHostError))
                } else {
                    print("✅ groupId 업데이트 성공!")
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /*
    private func createGroupInFirebase(groupName: String) -> Driver<Result<String, GroupError>> {
        return Single.create { single in
            let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
            
            let newGroupRef = ref.child("groups").childByAutoId()
            
            /*
             [기존 방식]
            let groupData: [String: Any] = [
                "groupId": newGroupRef.key ?? "",
                "groupName": groupName,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "hostUserId": self.userId
            ]
            
            newGroupRef.setValue(groupData) { error, _ in
                if let error = error {
                    print("❌ 그룹 생성 실패: \(error.localizedDescription)")
                    single(.success(.failure(.makeHostError)))
                } else {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    single(.success(.success(newGroupRef.key ?? "")))
                }
            }
             */
            
            // Model
            let groupData = HCGroup(
                groupId: newGroupRef.key ?? "",
                groupName: groupName,
                createdAt: Date(),
                hostUserId: self.userId,
                posts: [])
            
            // Model -> DTO -> Dictionary
            guard let groupDict = groupData.toDTO().toDictionary() else {
                single(.success(.failure(.makeHostError)))
                return Disposables.create()
            }
            
            newGroupRef.setValue(groupDict) { error, _ in
                if let error = error {
                    print("❌ 그룹 생성 실패: \(error.localizedDescription)")
                    single(.success(.failure(.makeHostError)))
                } else {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    single(.success(.success(newGroupRef.key ?? "")))
                }
            }
            return Disposables.create()
        }
        .asDriver(onErrorJustReturn: .failure(.makeHostError))
    }
    */
}
