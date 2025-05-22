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
    func fetchUserInfo() -> Observable<User?>
    
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
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
    
    
    /// 현재 유저 정보 가죠오기
    /// - Returns: Observable<User?>
    func fetchUserInfo() -> Observable<User?> {
        return Observable.create { observer in
            guard let uid = Auth.auth().currentUser?.uid else {
                print("🔸 로그인된 유저 없음")
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }

            let userRef = self.databaseRef.child("users").child(uid)
            
            userRef.observeSingleEvent(of: .value) { snapshot in
                // 🔥 추가: value가 nil이면 (애초에 아예 없음)
                guard snapshot.exists() else {
                    print("🔸 유저 데이터 없음 (snapshot 없음)")
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                // 🔥 추가: value 타입 확인
                guard let dict = snapshot.value as? [String: Any] else {
                    print("❌ 유저 데이터가 Dictionary가 아님. 타입: \(type(of: snapshot.value))")
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                do {
                    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let dto = try JSONDecoder().decode(UserDTO.self, from: data)
                    let user = dto.toModel()
                    observer.onNext(user)
                } catch {
                    print("❌ 유저 디코딩 실패: \(error.localizedDescription)")
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }

}

// MARK: - 제네릭 함수
extension FirebaseAuthManager {
    
    /// Firebase Realtime Database의 해당 경로에 값을 저장합니다.
    /// - 해당 경로에 데이터가 존재하지 않으면 **새로 추가**
    /// - 해당 경로에 데이터가 존재하면 **기존 데이터를 덮어쓰기(Overwrite)**
    ///
    /// 예: path = "groups/{groupId}/postsByDate/{date}/{postId}/comments/{commentId}"
    /// - 이미 같은 commentId가 있으면, 해당 댓글을 새로 덮어씀 (기존 내용 삭제 후 새로 저장)
    ///
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
    
    
    /// Delete
    /// - Parameter path: 삭제할 Firebase realtime 데이터 경로
    /// - Returns: 삭제 성공 여부 방출하는 Observable<Bool>
    func deleteValue(path: String) -> Observable<Bool> {
        return Observable.create { observer in
            self.databaseRef.child(path).removeValue { error, _ in
                if let error = error {
                    print("❌ deleteValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    print("✅ deleteValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// Read - 1회 요청
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
                print("🔥 observeValue snapshot.value = \(value)")
                
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

    
    /// Firebase Realtime Database의 해당 경로에 있는 데이터를 일부 필드만 병합 업데이트합니다.
    /// - 기존 데이터는 유지하면서, 전달한 값의 필드만 갱신됩니다.
    ///
    /// 예: 댓글에 'text'만 수정할 때 유용
    ///
    /// - Parameters:
    ///   - path: 업데이트할 Firebase 경로
    ///   - value: 업데이트할 일부 필드를 가진 값 (Encodable → Dictionary로 변환됨)
    /// - Returns: 업데이트 성공 여부를 방출하는 Observable<Bool>
    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            guard let dict = value.toDictionary() else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.databaseRef.child(path).updateChildValues(dict) { error, _ in
                if let error = error {
                    print("❌ updateValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    print("✅ updateValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
   

}

// MARK: - 그룹 관련
extension FirebaseAuthManager {
    
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        let newGroupRef = self.databaseRef.child("groups").childByAutoId()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return Observable.just(.failure(.makeHostError))
        }
        
        let inviteCode = self.generateInviteCode()
        let joinedAt = Date().toISO8601String()
        
        let groupData = HCGroup(
            groupId: newGroupRef.key ?? "",
            groupName: groupName,
            createdAt: Date(),
            hostUserId: currentUserId,
            inviteCode: inviteCode,
            members: [currentUserId: joinedAt],
            postsByDate: [:]
        )
        
        /// 이미 Observable이 있다면 .map { }으로 변환 후 바로 리턴
        /// 직접 데이터를 방출해야 한다면 Observable.create { observer in ... } 안에서 onNext 후 리턴
        return setValue(path: "groups/\(newGroupRef.key ?? "")", value: groupData.toDTO())
        /// Observable → 다른 Observable 로 바꿔야 하면 flatMap
        /// Observable → 값을 가공(변환)만 하면 map
            .map { success -> Result<(groupId: String, inviteCode: String), GroupError> in
                if success {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    return .success((groupId: newGroupRef.key ?? "", inviteCode: inviteCode))
                } else {
                    print("❌ 그룹 생성 실패")
                    return .failure(.makeHostError)
                }
            }
    }
    
    /// 그룹 Creaate
    /// - Parameter groupName: 그룹 이름
    /// - Returns: Observable<Result<그룹Id, GroupError>>
    /*
    func createGroup_save(groupName: String) -> Observable<Result<String, GroupError>> {
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
            members: [],
            postsByDate: [:]
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
     */
    
    
    /// 그룹 Create후 유저속성에 추가
    /// - Parameter groupId: 그룹 Id
    /// - Returns: Observable<Result<Void, GroupError>>
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
    
    /// 그룹 Fetch
    /// - Parameter groupId: 그룹 ID
    /// - Returns: Observable<Result<HCGroup, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        return observeValue(path: "groups/\(groupId)", type: HCGroupDTO.self)
            .map { dto in
                if let group = dto.toModel() {
                    return .success(group)
                } else {
                    return .failure(.fetchGroupError)
                }
            }
            .catch { error in
                print("❌ 그룹 정보 가져오기 실패: \(error.localizedDescription)")
                return Observable.just(.failure(.fetchGroupError))
            }
    }
    
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return observeValue(path: "groups", type: [String: HCGroupDTO].self)
            .flatMap { groupDict -> Observable<Result<HCGroup, GroupError>> in
                let groups = groupDict.compactMapValues { $0.toModel() }
                
                guard let matched = groups.values.first(where: { $0.inviteCode == inviteCode }) else {
                    print("❌ 초대코드로 일치하는 그룹 없음")
                    return Observable.just(.failure(.fetchGroupError))
                }
                
                guard let currentUID = Auth.auth().currentUser?.uid else {
                    return Observable.just(.failure(.makeHostError))
                }
                
                let groupId = matched.groupId
                let membersPath = "groups/\(groupId)/members"
                let groupPath = "groups/\(groupId)"
                
                // ✅ [uid: joinedAt] 형태로 불러오기
                return self.observeValue(path: membersPath, type: [String: String].self)
                    .catchAndReturn([:]) // 멤버가 없을 수도 있으므로 안전하게
                    .flatMap { existingMembers in
                        var newMembers = existingMembers
                        let joinedAt = Date().toISO8601String()
                        
                        newMembers[currentUID] = joinedAt
                        
                        // ✅ members 업데이트
                        let membersDict: [String: Any] = ["members": newMembers]
                        
                        return Observable.create { observer in
                            self.databaseRef.child(groupPath).updateChildValues(membersDict) { error, _ in
                                if let error = error {
                                    print("❌ members 업데이트 실패: \(error.localizedDescription)")
                                    observer.onNext(false)
                                } else {
                                    print("✅ members 업데이트 성공")
                                    observer.onNext(true)
                                }
                                observer.onCompleted()
                            }
                            return Disposables.create()
                        }
                    }
                    .flatMap { success in
                        if success {
                            return self.updateUserGroupId(groupId: groupId)
                                .map { updateResult in
                                    switch updateResult {
                                    case .success:
                                        return Result<HCGroup, GroupError>.success(matched)
                                    case .failure:
                                        return Result<HCGroup, GroupError>.failure(.makeHostError)
                                    }
                                }
                        } else {
                            return .just(.failure(.makeHostError))
                        }
                    }
            }
            .catch { error in
                print("❌ 그룹 조회 실패: \(error)")
                return Observable.just(.failure(.fetchGroupError))
            }
    }

    
    /*
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return observeValue(path: "groups", type: [String: HCGroupDTO].self)
            .flatMap { groupDict -> Observable<Result<HCGroup, GroupError>> in
                let groups = groupDict.compactMapValues { $0.toModel() }
                guard let matched = groups.values.first(where: { $0.inviteCode == inviteCode }) else {
                    print("❌ 초대코드로 일치하는 그룹 없음")
                    return Observable.just(.failure(.fetchGroupError))
                }
                
                guard let currentUID = Auth.auth().currentUser?.uid else {
                    return Observable.just(.failure(.makeHostError))
                }

                let groupId = matched.groupId
                let membersPath = "groups/\(groupId)/members"
                let groupPath = "groups/\(groupId)"

                // 현재 members 가져오기
                return self.observeValue(path: membersPath, type: [String].self)
                    .catchAndReturn([]) // 멤버가 없을 수도 있으므로 안전하게
                    .flatMap { existingMembers in
                        var newMembers = existingMembers
                        if !newMembers.contains(currentUID) {
                            newMembers.append(currentUID)
                        }

                        // 🔥 members 필드만 업데이트
                        let membersDict: [String: Any] = ["members": newMembers]
                        return Observable.create { observer in
                            self.databaseRef.child(groupPath).updateChildValues(membersDict) { error, _ in
                                if let error = error {
                                    print("❌ members 업데이트 실패: \(error.localizedDescription)")
                                    observer.onNext(false)
                                } else {
                                    print("✅ members 업데이트 성공")
                                    observer.onNext(true)
                                }
                                observer.onCompleted()
                            }
                            return Disposables.create()
                        }
                    }
                    .flatMap { success in
                        if success {
                            return self.updateUserGroupId(groupId: groupId)
                                .map { updateResult in
                                    switch updateResult {
                                    case .success:
                                        return Result<HCGroup, GroupError>.success(matched)
                                    case .failure:
                                        return Result<HCGroup, GroupError>.failure(.makeHostError)
                                    }
                                }
                        } else {
                            return .just(.failure(.makeHostError))
                        }
                    }
            }
            .catch { error in
                print("❌ 그룹 조회 실패: \(error)")
                return Observable.just(.failure(.fetchGroupError))
            }
    }
     */


}

// MARK: - 실시간 스냅샷 관련
extension FirebaseAuthManager {
    
    /// 실시간 스냅샷 감지
    /// Firebase Realtime Database에서 특정 경로(path)의 데이터를 **실시간으로 관찰**합니다.
    /// 해당 경로의 데이터가 변경될 때마다 최신 데이터를 가져와 스트림으로 방출합니다.
    /// - Parameters:
    ///   - path: Firebase Realtime Database 내에서 데이터를 관찰할 경로 문자열
    ///   - type: 디코딩할 모델 타입 (`Decodable`을 준수하는 타입)
    /// - Returns: 실시간으로 감지된 데이터를 방출하는 `Observable<T>`
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            let ref = self.databaseRef.child(path)
            let handle = ref.observe(.value) { snapshot in
                guard let value = snapshot.value else {
                    print("📛 실시간 observe: value 없음")
                    return
                }
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(decoded)
                } catch {
                    print("❌ observeValueStream 디코딩 실패: \(error.localizedDescription)")
                }
            }

            return Disposables.create {
                ref.removeObserver(withHandle: handle)
            }
        }
    }

}




// MARK: - 초대 코드 생성
extension FirebaseAuthManager {
    private func generateInviteCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
}






/*

func fetchUserInfo_보류() -> Observable<User?> {
    return Observable.create { observer in
        guard let uid = Auth.auth().currentUser?.uid else {
            print("🔸 로그인된 유저 없음")
            observer.onNext(nil)
            observer.onCompleted()
            return Disposables.create()
        }

        let userRef = self.databaseRef.child("users").child(uid)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                observer.onNext(nil)
                observer.onCompleted()
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let dto = try JSONDecoder().decode(UserDTO.self, from: data)
                let user = dto.toModel()
                observer.onNext(user)
            } catch {
                print("❌ 유저 디코딩 실패: \(error.localizedDescription)")
                observer.onNext(nil)
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
            
            /*
             guard let dict = value.toDictionary() else {
             observer.onNext(false)
             observer.onCompleted()
             return Disposables.create()
             }
             */
            
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
*/
