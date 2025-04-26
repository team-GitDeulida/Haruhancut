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
        let isGroupnameVaild: Driver<Bool>
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
        
        let isGroupnameVaild = input.groupNameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }
            .distinctUntilChanged() // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출
        
        return GroupHostOutput(hostResult: hostResult, isGroupnameVaild: isGroupnameVaild)
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
