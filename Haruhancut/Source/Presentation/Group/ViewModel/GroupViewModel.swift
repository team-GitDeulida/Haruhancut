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
    
    private let disposeBag = DisposeBag()
    
    let userId: String
    
    var groupName = BehaviorRelay<String>(value: "")
    
    init(userId: String) {
        self.userId = userId
    }
    
    struct GroupHostInput {
        let groupNameText: Observable<String>
        let endButtonTapped: Observable<Void>
    }
    
    struct GroupHostOutput {
        /// 그룹 ID 반환
        let hostResult: Driver<Result<String, GroupError>>
    }
    
    func transform(input: GroupHostInput) -> GroupHostOutput {
        let hostResult = input.endButtonTapped
            .withLatestFrom(input.groupNameText)
            .flatMapLatest { [weak self] groupName -> Driver<Result<String, GroupError>> in
                guard let self = self else {
                    return Driver.just(.failure(.makeHostError)) // ✅ Driver.just로 수정
                }
                self.groupName.accept(groupName)
                return self.createGroupInFirebase(groupName: groupName)
            }.asDriver(onErrorJustReturn: .failure(.makeHostError))
        return GroupHostOutput(hostResult: hostResult)
    }
    
    // MARK: - Firebase에 그룹 생성
    private func createGroupInFirebase(groupName: String) -> Driver<Result<String, GroupError>> {
        return Single.create { single in
            let ref = Database.database(url: "https://haruhancut-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
            let newGroupRef = ref.child("groups").childByAutoId()
            
            let groupData: [String: Any] = [
                "groupId": newGroupRef.key ?? "",
                "groupName": groupName,
                "createdAt": ISO8601DateFormatter().string(from: Date()),
                "hostUserId": self.userId
            ]
            
            newGroupRef.setValue(groupData) { error, _ in
                if let error = error {
                    print("❌ 그룹 생성 실패: \(error.localizedDescription)")
                    single(.success(.failure(.makeHostError)))
                } else {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    single(.success(.success(newGroupRef.key ?? "")))
                }
            }
            return Disposables.create()
        }
        .asDriver(onErrorJustReturn: .failure(.makeHostError))
    }
}
