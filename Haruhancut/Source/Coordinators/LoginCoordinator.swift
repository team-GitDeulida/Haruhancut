//
//  LoginCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 3/29/25.
//

import UIKit

final class LoginCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let loginVC = LoginViewController()
        loginVC.coordinator = self
        navigationController.setViewControllers([loginVC], animated: true)
    }

    func finish() {
        parentCoordinator?.removeChildCoordinator(self)
    }

    // 로그인 성공 시 실행 (회원가입 완료 후에도 호출)
    func didLoginSuccess() {
        finish()

        if let appCoordinator = parentCoordinator as? AppCoordinator {
            appCoordinator.showHomeFlow()
        }
    }
    
    // 회원가입 흐름 시작
    func showSignUp() {
        let signUpCoordinator = SignUpCoordinator(navigationController: navigationController)
        signUpCoordinator.parentCoordinator = self
        addChildCoordinator(signUpCoordinator)
        signUpCoordinator.start()
    }
}
