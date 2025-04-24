//
//  GroupViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/24/25.
//

import Foundation
import RxSwift
import RxCocoa

final class GroupViewModel {
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    struct Input {
        let enterViewTapped: Observable<Void>
        let hostViewTapped: Observable<Void>
    }
    
    struct Output {
        
    }
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
