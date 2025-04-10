//
//  HomeCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 3/29/25.
//

import UIKit

// HomeCoordinator.swift
final class HomeCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let homeVC = HomeViewController()
        homeVC.coordinator = self
        navigationController.setViewControllers([homeVC], animated: true)
    }

    func finish() {
        parentCoordinator?.removeChildCoordinator(self)
    }
}
