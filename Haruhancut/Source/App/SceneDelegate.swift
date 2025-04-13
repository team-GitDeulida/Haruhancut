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

/*
 https://jiwift.tistory.com/m/entry/iOSSwift-Firebase-Auth-로그인-여부-확인-코드?category=1154048
 */

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        // guard let _ = (scene as? UIWindowScene) else { return }
        
        // 1. scene 캡처
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // 2. window scene을 가져오는 windowScene을 생성자를 사용해서 UIWindow를 생성
        let window = UIWindow(windowScene: windowScene)
        
        // 3. view 계층을 프로그래밍 방식으로 만들기
        let usecase = DIContainer.shared.resolve(LoginUsecase.self)
        let viewModel = LoginViewModel(loginUsecase: usecase)
        let rootVC = LoginViewController(loginViewModel: viewModel)
        let homeVC = HomeViewController()
        let navController: UINavigationController?
        
        if let _ = Auth.auth().currentUser {
            // 3.1 UINavigationController로 감싸서 루트뷰컨트롤러 설정
            navController = UINavigationController(rootViewController: homeVC)
            print("로그인완료")
        } else {
            // 3.1 UINavigationController로 감싸서 루트뷰컨트롤러 설정
            navController = UINavigationController(rootViewController: rootVC)
            print("로그인이 필요합니다")
        }
        
        // 3.1 UINavigationController로 감싸서 루트뷰컨트롤러 설정
        // let navController = UINavigationController(rootViewController: rootVC)
        
        // 4. viewController로 window의 root view controller를 설정
        window.rootViewController = navController
        
        // 5. window를 설정하고 makeKeyAndVisible()
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
        let viewModel = LoginViewModel(loginUsecase: usecase)
        let loginVC = LoginViewController(loginViewModel: viewModel)
        let nav = UINavigationController(rootViewController: loginVC)
        changeRootView(to: nav)
    }
}

