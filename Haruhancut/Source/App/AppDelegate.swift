//
//  AppDelegate.swift
//  Haruhancut
//
//  Created by 김동현 on 3/17/25.
//

import UIKit

// 파이어베이스
import FirebaseCore
import FirebaseAuth

// 카카오톡
import RxKakaoSDKCommon
//import RxKakaoSDKAuth
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 카카오톡 설정
        if let nativeAppKey: String = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            RxKakaoSDK.initSDK(appKey: nativeAppKey, loggingEnable: false)
        }
 
        // 의존성 주입
        registerDependencies()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 카카오톡 로그인
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.rx.handleOpenUrl(url: url)
        }
        
        return false
    }
    
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

/*
 - DIContainer는 프로젝트 전반에서 객체를 주입받을 수 있도록 관리하는 싱글톤이다
 - UseCase 구현체를 등록한다
 */
extension AppDelegate {
    private func registerDependencies() {
        let kakaoLoginManager = KakaoLoginManager.shared
        let authRepository = AuthRepository(kakaoLoginManager: kakaoLoginManager)
        let loginUsecase = LoginUsecase(repository: authRepository)
        DIContainer.shared.register(LoginUsecase.self, dependency: loginUsecase)
    }
}
