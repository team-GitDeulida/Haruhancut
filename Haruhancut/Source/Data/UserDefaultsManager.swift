//
//  UserDefaultsManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/17/25.
//

import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    private let userKey = "cachedUser"
    private let signupKey = "isSignupCompleted"

    // MARK: - 유저
    // 저장
    func saveUser(_ user: User) {
        let dto = user.toDTO()
        guard let data = try? JSONEncoder().encode(dto) else { return }
        UserDefaults.standard.set(data, forKey: userKey)
    }

    func loadUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        guard let dto = try? JSONDecoder().decode(UserDTO.self, from: data) else { return nil }
        return dto.toModel()
    }

//    func saveUser(_ user: User) {
//        guard let data = user.toData() else { return }
//        UserDefaults.standard.set(data, forKey: userKey)
//    }
//
//    // 불러오기
//    func loadUser() -> User? {
//        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
//        return User.from(data: data)
//    }

    // 삭제
    func removeUser() {
        UserDefaults.standard.removeObject(forKey: userKey)
        print("캐시 유저 삭제: \(String(describing: self.loadUser()))")
    }
    
    // MARK: - Sign up
    
    // 회원가입 완료 여부
//    func isSignupCompleted() -> Bool {
//        return UserDefaults.standard.bool(forKey: signupKey)
//    }
    
    // 회원가입 완료
//    func markSignupCompleted() {
//        UserDefaults.standard.set(true, forKey: signupKey)
//    }
    
    // 회원가입 초기화(탈퇴시)
//    func clearSignupStatus() {
//        UserDefaults.standard.removeObject(forKey: signupKey)
//    }
}
