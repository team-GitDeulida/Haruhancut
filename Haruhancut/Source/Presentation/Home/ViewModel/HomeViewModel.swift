//
//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel {
    
    private let disposeBaag = DisposeBag()
    
    let group = BehaviorRelay<HCGroup?>(value: nil)
    
    func bindButtonTap(tap: Observable<Void>) {
        tap.subscribe(onNext: {
            print("hello world")
        })
        .disposed(by: disposeBaag)
    }
}
