//
//  User.swift
//  Haruhancut
//
//  Created by 김동현 on 4/15/25.
//

import Foundation

enum Gender: String, Codable {
    case male = "남자"
    case female = "여자"
    case other = "비공개"
}

enum LoginPlatform: String, Codable {
    case kakao = "kakao"
    case apple = "apple"
}

// MARK: - Model
struct User: Codable {
    var uid: String
    let registerDate: Date
    let loginPlatform: LoginPlatform
    
    var nickname: String
    var profileImageURL: String?
    var birthdayDate: Date
    var gender: Gender
    var isPushEnabled: Bool
    var groupId: String? // 그룹 참여 유무를 비즈니스 로직 분기에서 유용
}

extension User {
    func toDTO() -> UserDTO {
        let formatter = ISO8601DateFormatter()
        
        return UserDTO(
            uid: uid,
            registerDate: formatter.string(from: registerDate),
            loginPlatform: loginPlatform.rawValue,
            nickname: nickname,
            profileImageURL: profileImageURL,
            birthdayDate: formatter.string(from: birthdayDate),
            gender: gender.rawValue,
            isPushEnabled: isPushEnabled,
            groudId: groupId
        )
    }
    
    // ✅ Empty Object 패턴 생성자
    // 필수 속성이 많은 Non-Optional 모델(User)을 "기본값으로라도 먼저 생성하고, 이후 점진적으로 값만 채워나가는 패턴"
    static func empty(loginPlatform: LoginPlatform) -> User {
        return User(
            uid: "",
            registerDate: Date(),                 // 현재 시간
            loginPlatform: loginPlatform,
            nickname: "",                         // 아직 입력 안 됨
            profileImageURL: nil,
            birthdayDate: Date.distantPast,       // 의미 없는 과거 값
            gender: .other,                       // 기본값 (비공개)
            isPushEnabled: true,                  // 기본값
            groupId: nil
        )
    }
}

// User를 캐싱 가능한 형태로 만들기
extension User {
    func toData() -> Data? {
        try? JSONEncoder().encode(self)
    }

    static func from(data: Data) -> User? {
        try? JSONDecoder().decode(User.self, from: data)
    }
}



// MARK: - DTO
struct UserDTO: Codable {
    let uid: String?
    let registerDate: String?
    let loginPlatform: String?
    let nickname: String?
    let profileImageURL: String?
    let birthdayDate: String?
    let gender: String?
    let isPushEnabled: Bool?
    let groudId: String?
}

extension UserDTO {
    func toModel() -> User? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let uid = uid,
            let registerDateStr = registerDate,
            let registerDate = formatter.date(from: registerDateStr),
            let loginPlatformStr = loginPlatform,
            let loginPlatform = LoginPlatform(rawValue: loginPlatformStr),
            let nickname = nickname,
            let birthdayDateStr = birthdayDate,
            let birthdayDate = formatter.date(from: birthdayDateStr),
            let genderStr = gender,
            let gender = Gender(rawValue: genderStr),
            let isPushEnabled = isPushEnabled
        else {
            return nil
        }
        
        return User(
            uid: uid,
            registerDate: registerDate,
            loginPlatform: loginPlatform,
            nickname: nickname,
            profileImageURL: profileImageURL,
            birthdayDate: birthdayDate,
            gender: gender,
            isPushEnabled: isPushEnabled,
            groupId: groudId
        )
    }
}

