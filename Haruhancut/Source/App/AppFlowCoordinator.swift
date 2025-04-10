//
//  AppFlowCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 3/28/25.
//

import UIKit

final class AppCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showLoginFlow()
    }
    
    func finish() {
        
    }
    
    func showLoginFlow() {
        
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        loginCoordinator.parentCoordinator = self
        addChildCoordinator(loginCoordinator)
        loginCoordinator.start()
         
    }
    
    func showHomeFlow() { // ✅ 반드시 있어야 함!
          let homeCoordinator = HomeCoordinator(navigationController: navigationController)
          homeCoordinator.parentCoordinator = self
          addChildCoordinator(homeCoordinator)
          homeCoordinator.start()
      }
     
    
    
}
