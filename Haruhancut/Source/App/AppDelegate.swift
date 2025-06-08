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

import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var disposeBag = DisposeBag()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 파이어베이스 설정
        FirebaseApp.configure()
        
        // 앱 실행 시 사용자에게 알림 허용 권한 받기
        UNUserNotificationCenter.current().delegate = self
        
        // 파이어베이스 Meesaging 설정
        Messaging.messaging().delegate = self
        
        // 알림 권한 호출
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // print("✅ 알림 권한: \(granted)")
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
        
        // 1) Data → 16진수 문자열 변환
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        print("APNS token: \(tokenString)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // 포그라운드(앱 켜진 상태)에서도 알림 오는 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 받은 FCM 토큰: \(String(describing: fcmToken))")
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "localFCMToken")
        }
    }
}


//extension AppDelegate: MessagingDelegate {
//    // 파이어베이스 MessagingDelegate 설정
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//        print("Firebase registration token: \(String(describing: fcmToken))")
//
////        let dataDict: [String: String] = ["token": fcmToken ?? ""]
////        NotificationCenter.default.post(
////            name: Notification.Name("FCMToken"),
////            object: nil,
////            userInfo: dataDict
////        )
//    }
//}


/*
extension AppDelegate: MessagingDelegate {
    // MARK: 바뀐 방식 - DIContainer로 직접 UseCase 호출하여 저장
    // Firebase에서 새로운 FCM 토큰을 발급받았을 때 호출됨
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM 토큰 수신: \(String(describing: fcmToken))")
        
        // 👉 UserDefaults에 저장된 현재 유저 정보를 불러옴
        guard var user = UserDefaultsManager.shared.loadUser(),
              let token = fcmToken else { return }

        // 👉 이미 저장된 토큰과 같으면 저장 생략
        if user.fcmToken == token {
            print("✅ 기존과 동일한 토큰 → 저장 생략")
            return
        }

        // ✅ 토큰을 user 모델에 반영
        user.fcmToken = token

        // 👉 DIContainer에서 UseCase를 가져와 updateUser 호출
        // 서버(DB)에 FCM 토큰을 저장하는 용도
        DIContainer.shared.resolve(LoginUsecase.self)
            .updateUser(user)
            .subscribe(onNext: { result in
                switch result {
                case .success(let updated):
                    // ✅ 업데이트된 유저 정보도 캐시에 반영 (UserDefaults)
                    UserDefaultsManager.shared.saveUser(updated)
                    print("✅ FCM 토큰 저장 완료 (업데이트된 유저: \(updated.nickname))")
                case .failure(let error):
                    print("❌ FCM 토큰 저장 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
}
*/





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
//
//extension AppDelegate {
//    
//    // MARK: - FCM 토큰 생성 함수
//    func generateFCMToken() {
//        Messaging.messaging().token() { token, error in
//            if let error = error {
//                print("FCM 토큰 생성 중 오류 발생: \(error.localizedDescription)")
//            }
//            
//            /// 로직
//        }
//    }
//    
//    // MARK: - 토큰을 기기에서 삭제
//    func deleteFCMToken() {
//        Messaging.messaging().deleteToken { error in
//            if let error = error {
//                print("FCM 토큰 삭제 중 오류 발생: \(error.localizedDescription)")
//            }
//        }
//    }
//}
