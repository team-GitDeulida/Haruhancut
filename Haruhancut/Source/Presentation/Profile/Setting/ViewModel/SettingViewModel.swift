//  SettingViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import FirebaseAuth
import RxSwift
import RxCocoa

final class SettingViewModel {
    
    // Rx 리소스 해제를 위한 DisposeBag
    private let disposeBag = DisposeBag()
    
    // View로부터 전달받을 사용자 이벤트 정의
    struct Input {
        // 로그아웃 버튼 탭이벤트
        let logoutTapped: Observable<Void>
    }
    
    // View에 전달할 출력 데이터 정의
    struct Output {
        // 로그아웃 성공 또는 실패에 대한 결과 스트림
        // Driver를 사용하여 메인스레드에서 UI 바인딩에 안전하게 처리
        let logoutResult: Driver<Result<Void, LoginError>>
    }
    
    /// Input을 받아 내부 로직을 수행 후 Output을 반환하는 함수
    /// - Parameter input: View에서 발생한 이벤트
    /// - Returns: 로그아웃 결과를 포함하는 Output
    func transform(input: Input) -> Output {
        
        // 로그아웃 버튼 탭시 로직을 수행하고 결과를 result로 반환
        let result = input.logoutTapped
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
        
        // View에서 사용할 Output rntjd
        return Output(logoutResult: result)
    }
}

