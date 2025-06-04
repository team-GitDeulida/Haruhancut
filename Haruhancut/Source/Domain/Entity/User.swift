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
struct User: Encodable { /// Swift객체 -> Json(서버로 보낼때)
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
            groupId: groupId
        )
    }
    
    // ✅ Empty Object 패턴 생성자
    // 필수 속성이 많은 Non-Optional 모델(User)을 "기본값으로라도 먼저 생성하고, 이후 점진적으로 값만 채워나가는 패턴"
    static func empty(loginPlatform: LoginPlatform) -> User {
        return User(
            uid: "uid테스트",
            registerDate: Date(),                 // 현재 시간
            loginPlatform: loginPlatform,
            nickname: "관리자",                     // 아직 입력 안 됨
            profileImageURL: nil,
            birthdayDate: Date.distantPast,       // 의미 없는 과거 값
            gender: .other,                       // 기본값 (비공개)
            isPushEnabled: true,                  // 기본값
            groupId: nil
        )
    }
    
    static func empty2(loginPlatform: LoginPlatform) -> User {
        return User(
            uid: "uid테스트",
            registerDate: Date(),                 // 현재 시간
            loginPlatform: loginPlatform,
            nickname: "관리자",                     // 아직 입력 안 됨
            profileImageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
            birthdayDate: Date.distantPast,       // 의미 없는 과거 값
            gender: .other,                       // 기본값 (비공개)
            isPushEnabled: true,                  // 기본값
            groupId: nil
        )
    }
}

extension User {
    func toData() -> Data? {
        do {
            let data = try JSONEncoder().encode(self)
            return data
        } catch {
            print("❌ User toData() 실패: \(error.localizedDescription)")
            return nil
        }
    }

    static func from(data: Data) -> User? {
        do {
            let dto = try JSONDecoder().decode(UserDTO.self, from: data)
            return dto.toModel()
        } catch {
            print("❌ User from(data:) 실패: \(error.localizedDescription)")
            return nil
        }
    }
}


struct HCGroup: Encodable {
    let groupId: String
    let groupName: String
    let createdAt: Date
    let hostUserId: String
    let inviteCode: String
    var members: [String: String] // [uid: joinedAt]
    // var posts: [Post]
    var postsByDate: [String: [Post]]
}

extension HCGroup {
    static var emptyGroup: HCGroup {
        return HCGroup(
            groupId: "",
            groupName: "",
            createdAt: .now,
            hostUserId: "",
            inviteCode: "",
            members: [:],
            postsByDate: [:])
    }
    static var sampleGroup: HCGroup {
        let posts = Post.samplePosts+Post.samplePosts2
        let grouped = posts.groupedByDate()
        return HCGroup(groupId: "testGroupId",
                 groupName: "테스트 가족바",
                 createdAt: .koreanDate(year: 2025, month: 5, day: 1),
                       hostUserId: "index",
                       inviteCode: "1234",
                 members: [
                    "123": "1"
                 ],
                 postsByDate: grouped)
        
    }
}

struct Post: Encodable {
    let postId: String
    let userId: String           // 작성자 ID
    let nickname: String         // 작성자 닉네임
    let profileImageURL: String? // 작성자 프로필 사진
    let imageURL: String
    let createdAt: Date
    let likeCount: Int
    var comments: [String: Comment]
}

extension Post {
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
}

extension Array where Element == Post {
    func groupedByDate() -> [String: [Post]] {
        return Dictionary(grouping: self) { $0.createdAt.toKoreanDateString() }
    }
}

extension Post {
    static var samplePosts = [
        Post(postId: "postId1",
             userId: "index",
             nickname: "동현",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c1": Comment(
                     commentId: "c1",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "귀여운 사진이네요!",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId2",
             userId: "anotherUser",
             nickname: "동현1",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c2": Comment(
                     commentId: "c2",
                     userId: "index",
                     nickname: "동현",
                     profileImageURL: nil,
                     text: "고양이 너무 사랑스럽다!",
                     createdAt: .now),
                 "c3": Comment(
                     commentId: "c3",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "진짜 귀엽다 ㅠㅠ",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId3",
             userId: "index",
             nickname: "동현2",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 16),
             likeCount: 10,
             comments: [
                 "c4": Comment(
                     commentId: "c4",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "사진 너무 잘 나왔어요!",
                     createdAt: .now)
             ])
    ]
    
    static var samplePosts2 = [
        Post(postId: "postId1",
             userId: "index",
             nickname: "동현",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/en/5/5f/Original_Doge_meme.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c1": Comment(
                     commentId: "c1",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "귀여운 사진이네요!",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId2",
             userId: "anotherUser",
             nickname: "동현1",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c2": Comment(
                     commentId: "c2",
                     userId: "index",
                     nickname: "동현",
                     profileImageURL: nil,
                     text: "고양이 너무 사랑스럽다!",
                     createdAt: .now),
                 "c3": Comment(
                     commentId: "c3",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "진짜 귀엽다 ㅠㅠ",
                     createdAt: .now)
             ]),
        
        Post(postId: "postId3",
             userId: "index",
             nickname: "동현2",
             profileImageURL: nil,
             imageURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Gatto_europeo4.jpg/500px-Gatto_europeo4.jpg",
             createdAt: .koreanDate(year: 2025, month: 5, day: 17),
             likeCount: 10,
             comments: [
                 "c4": Comment(
                     commentId: "c4",
                     userId: "anotherUser",
                     nickname: "영선",
                     profileImageURL: nil,
                     text: "사진 너무 잘 나왔어요!",
                     createdAt: .now)
             ])
    ]
}

struct Comment: Encodable {
    let commentId: String
    let userId: String
    let nickname: String
    let profileImageURL: String?
    let text: String
    let createdAt: Date
}

extension HCGroup {
    func toDTO() -> HCGroupDTO {
        let formatter = ISO8601DateFormatter()
        let postsDTO: [String: [String: PostDTO]] = postsByDate.mapValues { postList in
            Dictionary(uniqueKeysWithValues: postList.map { ($0.postId, $0.toDTO()) })
        }
        
        return HCGroupDTO(
            groupId: groupId,
            groupName: groupName,
            createdAt: formatter.string(from: createdAt),
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            //members: members.map { $0.toDTO() },
            postsByDate: postsDTO
        )
    }
}

extension Post {
    func toDTO() -> PostDTO {
        let formatter = ISO8601DateFormatter()
        let commentDTOs = Dictionary(uniqueKeysWithValues: comments.map { key, comment in
                    (key, comment.toDTO())
                })
        
        return PostDTO(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: formatter.string(from: createdAt),
            likeCount: likeCount,
            comments: commentDTOs
        )
    }
}

extension Comment {
    func toDTO() -> CommentDTO {
        let formatter = ISO8601DateFormatter()
        return CommentDTO(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: formatter.string(from: createdAt))
    }
}

// MARK: - DTO
struct UserDTO: Codable { /// Json -> Swift 객체(서버 응답용)
    let uid: String?
    let registerDate: String?
    let loginPlatform: String?
    let nickname: String?
    let profileImageURL: String?
    let birthdayDate: String?
    let gender: String?
    let isPushEnabled: Bool?
    let groupId: String?
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
            groupId: groupId
        )
    }
}

struct HCGroupDTO: Codable {
    let groupId: String?
    let groupName: String?
    let createdAt: String?
    let hostUserId: String?
    let inviteCode: String?
    let members: [String: String]?
    var postsByDate: [String: [String: PostDTO]]? // postId가 key인 딕셔너리
}

extension HCGroupDTO {
    func toModel() -> HCGroup? {
        let formatter = ISO8601DateFormatter()
                
        guard
            let groupId = groupId,
            let groupName = groupName,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let hostUserId = hostUserId,
            let inviteCode = inviteCode
        else {
            return nil
        }
        
        // let members = self.members?.compactMap { $0.toModel() } ?? []
        // let memberIds = members ?? []
        // let memberIds = members?.compactMap { $0 } ?? []
        let memberDict = members ?? [:]
        
        
        var postsByDate: [String: [Post]] = [:]
        postsByDate = postsByDate.merging(
            self.postsByDate?.compactMapValues { dict in
                dict.compactMap { $0.value.toModel() }
            } ?? [:],
            uniquingKeysWith: { $1 }
        )
        
        return HCGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: memberDict,
            postsByDate: postsByDate
        )
    }
}

struct PostDTO: Codable {
    let postId: String?
    let userId: String?
    let nickname: String?
    let profileImageURL: String?
    let imageURL: String?
    let createdAt: String?
    let likeCount: Int?
    let comments: [String: CommentDTO]?
}

extension PostDTO {
    func toModel() -> Post? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let postId = postId,
            let userId = userId,
            let nickname = nickname,
            let imageURL = imageURL,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let likeCount = likeCount
        else {
            return nil
        }
        
        // let comments = self.comments?.compactMap { $0.toModel() } ?? []
        let commentList = self.comments?.compactMapValues { $0.toModel() } ?? [:]

        return Post(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: createdAt,
            likeCount: likeCount,
            comments: commentList
        )
    }
}


struct CommentDTO: Codable {
    let commentId: String?
    let userId: String?
    let nickname: String?
    let profileImageURL: String?
    let text: String?
    let createdAt: String?
}

extension CommentDTO {
    func toModel() -> Comment? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let commentId = commentId,
            let userId = userId,
            let nickname = nickname,
            let text = text,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr)
        else {
            // ❌ 하나라도 없으면 이 댓글은 무시
            return nil
        }
        
        return Comment(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL, // 없어도 괜찮음
            text: text,
            createdAt: createdAt
        )
    }
}

extension Encodable {
    func toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return jsonObject as? [String: Any]
        } catch {
            print("❌ toDictionary 변환 실패: \(error)")
            return nil
        }
    }
}

extension Decodable {
    static func fromDictionary(_ dict: [String: Any]) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let decodedObject = try JSONDecoder().decode(Self.self, from: data)
            return decodedObject
        } catch {
            print("❌ fromDictionary 변환 실패: \(error)")
            return nil
        }
    }
}
