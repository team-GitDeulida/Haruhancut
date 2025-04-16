//
//  FirebaseError.swift
//  Haruhancut
//
//  Created by 김동현 on 4/13/25.
//

import Foundation

enum LoginError: Error {
    
    // MARK: - kakao
    case noTokenKakao
    case sdkKakao(Error)
    
    // MARK: - Auth
    case authError
    case signUpError
    case noUser
    
    var description: String {
        switch self {
        case .noTokenKakao:
            "⚠️ 카카오 로그인 token이 없습니다"
        case .sdkKakao(let error):
            "⚠️ 카카오 SDK 오류: \(error)"
        case .authError:
            "⚠️ 파이어베이스 인증 실패"
        case .signUpError:
            "⚠️ 파이어베이스 가입 실패"
        case .noUser:
            "⚠️ 유저가 존재하지 않음"
        }
    }
}
    
