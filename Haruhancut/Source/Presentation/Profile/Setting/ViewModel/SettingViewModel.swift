//  SettingViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import FirebaseAuth
import FirebaseMessaging
import RxSwift
import RxCocoa

protocol SettingViewModelType {
    var user: User { get }
    func transform(input: SettingViewModel.Input) -> SettingViewModel.Output
    func alertOn()
    func alertOff()
    func updateUser(user: User) -> Observable<Result<Void, LoginError>>
}

final class SettingViewModel: SettingViewModelType
{
    
    private let loginUsecase: LoginUsecaseProtocol
    var user: User
    
    init(user: User, loginUsecase: LoginUsecaseProtocol) {
        self.loginUsecase = loginUsecase
        self.user = user
    }
    
    // Rx 리소스 해제를 위한 DisposeBag
    private let disposeBag = DisposeBag()
    
    // View로부터 전달받을 사용자 이벤트 정의
    struct Input {
        // 로그아웃 버튼 이벤트
        let logoutTapped: Observable<Void>
        
        // 토글 스위치 이벤트
        let notificationToggled: Observable<Bool>
        
        // 셀 이벤트
        let cellSelected: Observable<IndexPath>
    }
    
    // View에 전달할 출력 데이터 정의
    struct Output {
        /// 로그아웃 성공 또는 실패에 대한 결과 스트림(Driver를 사용하여 메인스레드에서 UI 바인딩에 안전하게 처리)
        let logoutResult: Driver<Result<Void, LoginError>>
        
        let notificationResult: Driver<Bool>   // 토글 처리 결과
        let selectionResult: Driver<IndexPath> // 셀 선택 통보
    }
    
    /// Input을 받아 내부 로직을 수행 후 Output을 반환하는 함수
    /// - Parameter input: View에서 발생한 이벤트
    /// - Returns: 로그아웃 결과를 포함하는 Output
    func transform(input: Input) -> Output {
        
        // MARK: - 로그아웃
        let logoutResult = input.logoutTapped
            .map { _ -> Result<Void, LoginError> in
                do {
                    try Auth.auth().signOut()
                    UserDefaultsManager.shared.removeUser()
                    UserDefaultsManager.shared.removeGroup()
                    return .success(())
                } catch {
                    return .failure(.logoutError)
                }
                // 에러가 발생하더라도 UI가 멈추지 않고 기본 오류값으로 처리
            }.asDriver(onErrorJustReturn: .failure(.logoutError))
        
        // MARK: - 알림 토글
        let notificationResult = input.notificationToggled
            .do(onNext: { isOn in
                // print("VM: notification toggled →", isOn)
            })
            .asDriver(onErrorJustReturn: false)
        
        // MARK: - 셀 선택
        let selectionResult = input.cellSelected
            .do(onNext: { indexPath in
                // print("VM: cell selected → section:\(indexPath.section), row:\(indexPath.row)")
            })
            .asDriver(onErrorDriveWith: .empty())
        
        return Output(
            logoutResult: logoutResult,
            notificationResult: notificationResult,
            selectionResult: selectionResult)
    }
    
    /*
    // MARK: - FCM 토큰 생성 함수
    func generateFCMToken() {
        Messaging.messaging().token() { token, error in
            if let error = error {
                print("FCM 토큰 생성 중 오류 발생: \(error.localizedDescription)")
            }
            
            guard let token = token else {
                print("FCM 토큰이 nil 입니다.")
                return
            }

            /// 로직
            print("새 FCM 토큰: \(token)")
            
            // 모델에 반영
            var updatedUser = self.user
            updatedUser.fcmToken = token
            updatedUser.isPushEnabled = true
            
            // 서버/DB에도 반영
            self.updateUser(user: updatedUser)
               .subscribe(onNext: { result in
                   switch result {
                   case .success:
                       self.user = updatedUser
                       print("FCM 토큰으로 유저 업데이트 성공")
                   case .failure(let err):
                       print("유저 업데이트 실패:", err)
                   }
               })
               .disposed(by: self.disposeBag)
        }
    }
    
    // MARK: - FCM 토큰 삭제 함수
    func clearFCMToken() {
       Messaging.messaging().deleteToken { error in
           if let error = error {
               print("FCM 토큰 삭제 중 오류:", error.localizedDescription)
           } else {
               print("FCM 토큰 삭제 성공")
               
               // 모델에 반영
               var updatedUser = self.user
               updatedUser.fcmToken = ""
               updatedUser.isPushEnabled = false
               
               // 서버/DB에도 반영
               self.updateUser(user: updatedUser)
                   .subscribe(onNext: { result in
                       switch result {
                       case .success:
                           self.user = updatedUser
                           print("유저 FCM 토큰 삭제 반영 완료")
                       case .failure(let err):
                           print("유저 업데이트 실패:", err)
                       }
                   })
                   .disposed(by: self.disposeBag)
           }
       }
   }
     */
    
    
    func alertOn() {
        // 모델에 반영
        var updatedUser = self.user
        updatedUser.isPushEnabled = true
        
        // 서버/DB에도 반영
        self.updateUser(user: updatedUser)
           .subscribe(onNext: { result in
               switch result {
               case .success:
                   self.user = updatedUser
               case .failure(let err):
                   print("유저 업데이트 실패:", err)
               }
           })
           .disposed(by: disposeBag)
    }
    
    func alertOff() {
        // 모델에 반영
        var updatedUser = self.user
        updatedUser.isPushEnabled = false
        
        // 서버/DB에도 반영
        self.updateUser(user: updatedUser)
           .subscribe(onNext: { result in
               switch result {
               case .success:
                   self.user = updatedUser
               case .failure(let err):
                   print("유저 업데이트 실패:", err)
               }
           })
           .disposed(by: disposeBag)
    }
    
    func updateUser(user: User) -> Observable<Result<Void, LoginError>> {
        loginUsecase
            .updateUser(user)
            .map { [weak self] result -> Result<Void, LoginError> in
                if case .success(let user) = result {
                    self?.user = user
                    UserDefaultsManager.shared.saveUser(user)
                }
                return result.mapToVoid()
            }
    }
}

final class StubSettingViewModel: SettingViewModelType {
    var user: User = .empty(loginPlatform: .kakao)
    func transform(input: SettingViewModel.Input) -> SettingViewModel.Output {
        return .init(
            logoutResult: Driver.just(.success(())),
            notificationResult: Driver.just(false),
            selectionResult: Driver.just(IndexPath(row: 0, section: 0))
        )
    }
    
    func alertOn() {}
    func alertOff() {}
    
    func updateUser(user: User) -> Observable<Result<Void, LoginError>> {
        return .just(.success(()))
    }
}

