//
//  AppCoordinator.swift
//  Haruhancut
//
//  Created by 김동현 on 4/21/25.
//

import UIKit
import RxSwift

protocol Coordinator: AnyObject {
    var parentCoordinator: Coordinator? { get set }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

/// 모든 Coordinator가 제공 받는 기능
extension Coordinator {
    
    /// 자식 코디네이터가 자신의 플로우를 마쳤을 때, 부모가 자기 배열에서 제거하는 역할
    /// - Parameter child: 자식 코디네이터
    /// -    /// parentCoordinator?.childDidFinish(self)
    func childDidFinish(_ child: Coordinator?) {
        guard let child = child else { return }
        childCoordinators.removeAll() { $0 === child }
    }
}

final class AppCoordinator: Coordinator {
    
    private let disposeBag = DisposeBag()
    
    /// protocol
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    let navigationController: UINavigationController
    var isLoggedIn: Bool = false
    
    // MARK: - 공유가 필요하기 때문에 AppCoordinator에 만들기
    private let loginViewModel = LoginViewModel(loginUsecase: DIContainer.shared.resolve(LoginUsecase.self))
    
    init(navigationController: UINavigationController, isLoggedIn: Bool) {
        print("AppCoordinator - 생성")
        self.navigationController = navigationController
        self.isLoggedIn = isLoggedIn
    }
    
    /// protocol
    func start() {
        print("AppCoordinator - start()")
        if isLoggedIn {
            startHomeCoordinator()
        } else {
            startLoginFlowCoordinator()
        }
    }
    
    func startLoginFlowCoordinator() {
        let coordinator = LoginFlowCoordinator(navigationController: navigationController,
                                               loginViewModel: loginViewModel)
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }

    func startHomeCoordinator() {
        let homeViewModel = HomeViewModel(
            loginUsecase: DIContainer.shared.resolve(LoginUsecase.self),
            groupUsecase: DIContainer.shared.resolve(GroupUsecase.self),
            userRelay: loginViewModel.user
        )
        
        let coordinator = HomeCoordinator(
            navigationController: navigationController,
            loginViewModel: loginViewModel,
            homeViewModel: homeViewModel
        )
        coordinator.parentCoordinator = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
}

final class LoginFlowCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let loginViewModel: LoginViewModel
    
    init(navigationController: UINavigationController, loginViewModel: LoginViewModel) {
        print("LoginFlowCoordinator - 생성")
        self.navigationController = navigationController
        self.loginViewModel = loginViewModel
    }
    
    deinit {
        print("LoginCoordinator - 해제")
    }
    
    func start() {
        print("LoginCoordinator - start()")
        showLogin()
    }
    
    func showLogin() {
        let loginViewController = LoginViewController(loginViewModel: loginViewModel)
        loginViewController.coordinator = self
        navigationController.setViewControllers([loginViewController], animated: true)
    }
    
    func showNickname() {
        let nickNameSettingViewController = NicknameSettingViewController(loginViewModel: loginViewModel)
        nickNameSettingViewController.coordinator = self
        navigationController.setViewControllers([nickNameSettingViewController], animated: true)
    }
    
    func showBirthday() {
        let birthdaySettingViewController = BirthdaySettingViewController(loginViewModel: loginViewModel)
        birthdaySettingViewController.coordinator = self
        navigationController.setViewControllers([birthdaySettingViewController], animated: true)
    }
    
    func showHome() {
        finishFlow() // 현재 흐름 종료(자신을 부모에서 제거
        if let appCoordinator = parentCoordinator as? AppCoordinator {
            // ✅ AppCoordinator가 홈 코디네이터 시작
            appCoordinator.startHomeCoordinator()
        }
    }
    
    func finishFlow() {
        parentCoordinator?.childDidFinish(self)
    }
}

final class HomeCoordinator: Coordinator {
    var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController
    
    private let loginViewModel: LoginViewModel
    private let homeViewModel:  HomeViewModel
    private var groupViewModel: GroupViewModel?

    
    init(navigationController: UINavigationController, loginViewModel: LoginViewModel, homeViewModel: HomeViewModel) {
        print("HomeCoordinator - 생성")
        self.navigationController = navigationController
        self.loginViewModel = loginViewModel
        self.homeViewModel = homeViewModel
    }
    
    func start() {
        // if let _ = loginViewModel.group.value {
        if let _ = loginViewModel.user.value?.groupId {
            /// 홈으로 이동
            startHome()
        } else {
            /// 그룹 생성
            startGroup()
        }
    }
    
    func startGroup() {
        groupViewModel = GroupViewModel(loginViewModel: loginViewModel, groupUsecase: DIContainer.shared.resolve(GroupUsecase.self), homeViewModel: homeViewModel)
        // groupViewModel = GroupViewModel(userId: loginViewModel.user.value?.uid ?? "", groupUsecase: DIContainer.shared.resolve(GroupUsecase.self), loginViewModel: loginViewModel)
        guard let groupViewModel = groupViewModel else { return }
        let vc = GroupViewController(groupViewModel: groupViewModel)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: true)
    }
    
    func startGroupEnter() {
        guard let groupViewModel = groupViewModel else { return }
        let vc = GroupEnterViewController(groupViewModel: groupViewModel)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func startGroupHost() {
        // let viewModel = GroupDetailViewModel()
        guard let groupViewModel = groupViewModel else { return }
        let vc = GroupHostViewController(groupViewModel: groupViewModel)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func startHome() {
        let vc = HomeViewController(loginViewModel: loginViewModel, homeViewModel: homeViewModel)
        vc.coordinator = self
        navigationController.setViewControllers([vc], animated: true)
    }
    
    func startProfile() {
        let profileViewController = ProfileViewController()
        profileViewController.coordinator = self
        navigationController.pushViewController(profileViewController, animated: true)
    }
    
    func startCamera() {
        let cameraViewController = CameraViewController()
        cameraViewController.coordinator = self
        navigationController.pushViewController(cameraViewController, animated: true)
    }
    
    func navigateToUpload(image: UIImage) {
        let uploadVC = ImageUploadViewController(image: image, homeViewModel: homeViewModel)
        uploadVC.coordinator = self
        navigationController.pushViewController(uploadVC, animated: true)
    }
    
    func backToHome() {
        // 쌓여있던 모든 화면 제거하고 루트인 homeVC로 이동
        navigationController.popToRootViewController(animated: true)
    }
    
    func startPostDetail(post: Post) {
        let postDetailViewController = PostDetailViewController(homeViewModel: homeViewModel, post: post)
        postDetailViewController.coordinator = self
        navigationController.pushViewController(postDetailViewController, animated: true)
    }
    
    func showLogin() {
        finishFlow() // 현재 흐름 종료(자신을 부모에서 제거
        if let appCoordinator = parentCoordinator as? AppCoordinator {
            
            UIView.transition(with: navigationController.view,
                              duration: 0.4,
                              options: .transitionFlipFromLeft,
                              animations: {
                // ✅ AppCoordinator가 로그인 코디네이터 시작
                appCoordinator.startLoginFlowCoordinator()
            })
        }
    }
    
    func finishFlow() {
        parentCoordinator?.childDidFinish(self)
    }
    
}

//final class CameraCoordinator: Coordinator {
//    
//    var parentCoordinator: Coordinator?
//    var childCoordinators: [Coordinator] = []
//    let navigationController: UINavigationController
//    private let homeViewModel:  HomeViewModel
//    
//    init(navigationController: UINavigationController, homeViewModel: HomeViewModel) {
//        print("CameraCoordinator - 생성")
//        self.navigationController = navigationController
//        self.homeViewModel = homeViewModel
//    }
//    
//    func start() {
//        print("CameraCoordinator - start()")
//        showCamera()
//    }
//    
//    func showCamera() {
//        
//    }
//    
//    func finishFlow() {
//        parentCoordinator?.childDidFinish(self)
//    }
//}
