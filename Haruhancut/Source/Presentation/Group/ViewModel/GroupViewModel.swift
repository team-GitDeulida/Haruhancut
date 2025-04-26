//
//  GroupViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/24/25.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseDatabase

enum GroupError: Error {
    case makeHostError
}

final class GroupViewModel {
    
    private let groupUsecase: GroupUsecaseProtocol
    
    private let disposeBag = DisposeBag()
    
    let userId: String
    
    var groupName = BehaviorRelay<String>(value: "")
    
    init(userId: String, groupUsecase: GroupUsecaseProtocol) {
        self.userId = userId
        self.groupUsecase = groupUsecase
    }
    
    struct GroupHostInput {
        let groupNameText: Observable<String>
        let endButtonTapped: Observable<Void>
    }
    
    struct GroupHostOutput {
        /// 그룹 ID 반환
        let hostResult: Driver<Result<String, GroupError>>
        let isGroupnameVaild: Driver<Bool>
    }
    
    func transform(input: GroupHostInput) -> GroupHostOutput {
        let hostResult = input.endButtonTapped
            .withLatestFrom(input.groupNameText)
            .flatMapLatest { [weak self] groupName -> Observable<Result<String, GroupError>> in
                guard let self = self else {
                    return Observable.just(.failure(.makeHostError)) // ✅ Driver.just로 수정
                }
                self.groupName.accept(groupName)
                
                /// 그룹 만들기
                return groupUsecase.createGroup(groupName: groupName)
                    .flatMapLatest { result -> Observable<Result<String, GroupError>> in
                        switch result {
                        case .success(let groupId):
                            /// 그룹 만들기 성공 -> 유저 업데이트 시도
                            return self.groupUsecase.updateUserGroupId(groupId: groupId)
                                .map { updateResult in
                                    switch updateResult {
                                    case .success:
                                        return .success(groupId) /// 둘 다 성공했으면 최종 성공
                                    case .failure(_):
                                        return .failure(.makeHostError) /// 업데이트 실패
                                    }
                                }
                        case .failure:
                            /// 그룹 만들기 실패
                            return Observable.just(.failure(.makeHostError))
                        }
                    }
            }.asDriver(onErrorJustReturn: .failure(.makeHostError))
        
        let isGroupnameVaild = input.groupNameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출
        
        return GroupHostOutput(hostResult: hostResult, isGroupnameVaild: isGroupnameVaild)
    }
}
