//
//  HomeViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/18/25.
//

import Foundation
import RxSwift

final class HomeViewModel {
    
    private let disposeBaag = DisposeBag()
    
    func bindButtonTap(tap: Observable<Void>) {
        tap.subscribe(onNext: {
            print("hello world")
        })
        .disposed(by: disposeBaag)
    }
}
