//
//  SignUpCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 3/29/25.
//

import UIKit

final class SignUpCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let signUpVC = SignUpViewController()
        signUpVC.coordinator = self
        // 회원가입은 기존 로그인 스택 위에 push할 수 있음
        navigationController.pushViewController(signUpVC, animated: true)
    }

    func finish() {
        parentCoordinator?.removeChildCoordinator(self)
    }

    // 회원가입 완료 시 실행: 부모인 LoginCoordinator에게 알림
    func didCompleteSignUp() {
        finish()

        // 부모인 LoginCoordinator에게 회원가입 완료 알림
        if let loginCoordinator = parentCoordinator as? LoginCoordinator {
            loginCoordinator.didLoginSuccess()
        }
    }
}
