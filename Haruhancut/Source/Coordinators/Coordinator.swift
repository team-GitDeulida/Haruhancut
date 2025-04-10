//
//  Coordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 3/29/25.
//

import Foundation

/// 모든 Coordinator는 start()랄 호출하면 흐름이 시작됨
/// childCoordinators는 내가 띄운 하위 흐름을 보관하는 배열
protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    
    func start()
    func finish()
    func addChildCoordinator(_ coordinator: Coordinator)
    func removeChildCoordinator(_ coordinator: Coordinator)
}

extension Coordinator {
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        // 같은 인스턴스인지 비교 (클래스, 참조 타입 비교)
        childCoordinators.removeAll { $0 === coordinator }
    }
}
