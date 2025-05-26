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

import Foundation

// 알람 관련
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        UNUserNotificationCenter.current().delegate = self
        
        // 파이어베이스 Meesaging 설정
        Messaging.messaging().delegate = self
        
        // 알림 권한 호출
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("✅ 알림 권한: \(granted)")
            guard granted else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        
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

// MARK: - 알람관련
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 백그라운드에서 푸시 알림을 탭했을 때 실행
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNS token: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 포그라운드(앱 켜진 상태)에서도 알림 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    // 파이어베이스 MessagingDelegate 설정
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}


/*
 - DIContainer는 프로젝트 전반에서 객체를 주입받을 수 있도록 관리하는 싱글톤이다
 - UseCase 구현체를 등록한다
 */
extension AppDelegate {
    private func registerDependencies() {
        let kakaoLoginManager = KakaoLoginManager.shared
        let appleLoginManager = AppleLoginManager.shared
        let firebaseAuthManager = FirebaseAuthManager.shared
        let firebaseStorageManager = FirebaseStorageManager.shared
        
        let authRepository = LoginRepository(kakaoLoginManager: kakaoLoginManager, appleLoginManager: appleLoginManager, firebaseAuthManager: firebaseAuthManager, firebaseStorageManager: firebaseStorageManager)
        let loginUsecase = LoginUsecase(repository: authRepository)
        DIContainer.shared.register(LoginUsecase.self, dependency: loginUsecase)
        
        let groupRepository = GroupRepository(firebaseAuthManager: firebaseAuthManager)
        let groupUsecase = GroupUsecase(repository: groupRepository)
        DIContainer.shared.register(GroupUsecase.self, dependency: groupUsecase)
    }
}
