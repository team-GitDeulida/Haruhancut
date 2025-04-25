//
//  SceneDelegate.swift
//  Haruhancut
//
//  Created by 김동현 on 3/17/25.
//

import UIKit
import RxKakaoSDKAuth
import KakaoSDKAuth
import FirebaseAuth
import ScaleKit

/*
 https://jiwift.tistory.com/m/entry/iOSSwift-Firebase-Auth-로그인-여부-확인-코드?category=1154048
 */

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // 1. scene 캡처
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 1.1 화면 사이즈를 저장하는 커스텀 함수, 기기 해상도에 따라 레이아웃 사이즈 조절
        DynamicSize.setScreenSize(windowScene.screen.bounds)
        
        // 2. window scene을 가져오는 windowScene을 생성자를 사용해서 UIWindow를 생성
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()
        
        // 3. view 계층을 프로그래밍 방식으로 만들기
        // ✅ AppCoordinator 생성 및 시작
        let coordinator = AppCoordinator(navigationController: navigationController, isLoggedIn: false)
        coordinator.start()
        appCoordinator = coordinator

        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        
        // 카카오 로그인
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.rx.handleOpenUrl(url: url)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

extension SceneDelegate {
    
    func changeRootView(to viewController: UIViewController, animated: Bool = true) {
        guard let window = self.window else { return }
        window.rootViewController = viewController
        if animated {
            UIView.transition(with: window, duration: 0.4, options: .transitionFlipFromLeft, animations: nil)
        }
        window.makeKeyAndVisible()
    }
    
    /// 로그인 화면을 루트로 바꾸는 함수 (로그아웃 등에서 호출)
    func makeLoginRoot() {
        let usecase = DIContainer.shared.resolve(LoginUsecase.self)
        let loginVM = LoginViewModel(loginUsecase: usecase)
        let loginVC = LoginViewController(loginViewModel: loginVM)
        let nav = UINavigationController(rootViewController: loginVC)
        changeRootView(to: nav)
    }
}

