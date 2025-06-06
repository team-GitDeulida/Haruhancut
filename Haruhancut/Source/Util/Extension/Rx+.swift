//
//  Rx+.swift
//  Haruhancut
//
//  Created by 김동현 on 5/27/25.
//

import RxSwift
import RxCocoa

/*
서버에서 데이터를 받아오기 전까지는 nil이지만,
뷰에서는 무조건 Non-Optional로 바인딩해서 쓰고 싶을 때.
 */

extension BehaviorRelay where Element: ExpressibleByNilLiteral {
    /// Optional 타입의 BehaviorRelay를 Non-Optional 타입으로 변환 (초기값이 nil이 아니어야 함)
    func compactMapToNonOptional<Wrapped>() -> BehaviorRelay<Wrapped> where Element == Wrapped? {
        let nonOptionalRelay = BehaviorRelay<Wrapped>(value: self.value!)
        self
            .compactMap { $0 }
            .bind(to: nonOptionalRelay)
            .disposed(by: DisposeBag())
        return nonOptionalRelay
    }
}

//extension BehaviorRelay where Element == User? {
//    func compactMapToNonOptional() -> BehaviorRelay<User> {
//        let nonOptionalRelay = BehaviorRelay<User>(value: self.value!) // 강제 언래핑은 초기화 보장 시 가능
//        self
//            .compactMap { $0 }
//            .bind(to: nonOptionalRelay)
//            .disposed(by: DisposeBag())
//        return nonOptionalRelay
//    }
//}
//
//extension BehaviorRelay where Element == HCGroup? {
//    func compactMapToNonOptional() -> BehaviorRelay<HCGroup> {
//        let nonOptionalRelay = BehaviorRelay<HCGroup>(value: self.value!) // 강제 언래핑은 초기화 보장 시 가능
//        self
//            .compactMap { $0 }
//            .bind(to: nonOptionalRelay)
//            .disposed(by: DisposeBag())
//        return nonOptionalRelay
//    }
//}


//// MARK: - BehaviorRelay<User?>를 → BehaviorRelay<User>로 바꾸는 함수
//extension BehaviorRelay where Element == User? {
//    func compactMapToNonOptional(sharedRelay: BehaviorRelay<User>) -> BehaviorRelay<User> {
//        guard let unwrapped = self.value else {
//            fatalError("❌ compactMapToNonOptional: BehaviorRelay<User?>.value is nil")
//        }
//
//        // 초기 값 주입
//        sharedRelay.accept(unwrapped)
//
//        // 1. User? → User
//        self
//            .compactMap { $0 }
//            .bind(to: sharedRelay)
//            .disposed(by: DisposeBag())
//
//        // 2. User → User?
//        sharedRelay
//            .map { Optional($0) }
//            .bind(to: self)
//            .disposed(by: DisposeBag())
//
//        return sharedRelay
//    }
//}
//



//extension BehaviorRelay where Element == User? {
//    /// BehaviorRelay<User?> → BehaviorRelay<User> 변환 (초기값이 반드시 있어야 함)
//    func compactMapToNonOptional() -> BehaviorRelay<User> {
//        guard let unwrapped = self.value else {
//            fatalError("❌ compactMapToNonOptional: BehaviorRelay<User?>.value is nil")
//        }
//        let relay = BehaviorRelay<User>(value: unwrapped)
//
//        // ✅ userRelay 값이 갱신될 때마다 non-optional relay에도 반영
//        self
//            .compactMap { $0 }
//            .bind(to: relay)
//            .disposed(by: DisposeBag()) // 강한 참조 방지 주의: 재사용 가능하게 만들면 DI로 풀어야 함
//
//        return relay
//    }
//}
