//
//  DIContainer.swift
//  Haruhancut
//
//  Created by 김동현 on 4/1/25.
//
// https://github.com/boostcampwm-2024/iOS08-Shook/blob/develop/Projects/App/Sources/DIContainer.swift

import Foundation

final class DIContainer {
    static let shared = DIContainer()
    private init() {}
    private var dependencies: [String: Any] = [:]
    
    // 메서드로 의존성을 등록
    func register<T>(_ type: T.Type, dependency: T) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }
    
    // 메서드로 등록된 의존성을 가져오기
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let dependency = dependencies[key] as? T else {
            preconditionFailure("⚠️ \(key)는 register되지 않았습니다. resolve호출 전에 register 해주세요.")
        }
        return dependency
    }
}
