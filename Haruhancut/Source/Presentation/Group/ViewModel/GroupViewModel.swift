//
//  GroupViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/24/25.
//

import Foundation
import RxSwift
import RxCocoa

enum GroupError: Error {
    case makeHostError
}

final class GroupViewModel {
    
    private let disposeBag = DisposeBag()
    
    let userId: String
    
    var groupName = BehaviorRelay<String>(value: "")
    
    init(userId: String) {
        self.userId = userId
    }
    
    struct groupHostInput {
        let groupNameText: Observable<String>
        let endButtonTapped: Observable<Void>
    }
    
    struct groupHostOutput {
        let hostResult: Driver<Result<Void, GroupError>>
    }
    
    func transform(input: groupHostInput) -> groupHostOutput {
        let endButtonTapped = input.endButtonTapped
            .withLatestFrom(input.groupNameText)
            .map { [weak self] groupName -> Result<Void, GroupError> in
                self?.groupName.accept(groupName)
                return .success(())
            }
            .asDriver(onErrorJustReturn: .failure(.makeHostError))
//            .bind(onNext: { [weak self] groupName in
//                guard let self = self else { return }
//                self.groupName.accept(groupName)
//            })

            
                    
        return groupHostOutput(hostResult: endButtonTapped)
    }
}
