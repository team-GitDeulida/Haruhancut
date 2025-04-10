//
//  LoginError.swift
//  Haruhancut
//
//  Created by 김동현 on 4/11/25.
//

import Foundation

enum LoginError: Error {
    
    // MARK: - kakao
    case noTokenKakao
    case sdkKakao(Error)
    
    var description: String {
        switch self {
        case .noTokenKakao:
            "⚠️ 카카오 로그인 token이 없습니다"
        case .sdkKakao(let error):
            "카카오 SDK 오류: \(error)"
        }
    }
}
    
