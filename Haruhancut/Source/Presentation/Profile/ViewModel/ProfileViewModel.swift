//  ProfileViewModel.swift
//  Haruhancut
//
//  Created by 김동현 on 4/27/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol ProfileViewModelType {
    func uploadImage(image: UIImage) -> Observable<Bool>
}

final class ProfileViewModel: ProfileViewModelType {
    private let loginUsecase: LoginUsecaseProtocol
    private let disposeBag = DisposeBag()
    
    let userRelay: BehaviorRelay<User?>
    var user: Driver<User?> { userRelay.asDriver(onErrorJustReturn: nil) }
    
    init(
        loginUsecase: LoginUsecaseProtocol,
         userRelay: BehaviorRelay<User?>
    ) {
        self.loginUsecase = loginUsecase
        self.userRelay = userRelay
        // print(userRelay.value)
    }
    
    func uploadImage(image: UIImage) -> Observable<Bool> {
        guard let user = userRelay.value else { return .just(false)}
        return loginUsecase.uploadImage(user: user, image: image)
            .flatMap { result -> Observable<Bool> in
                switch result {
                case .success(let url):
                    var updatedUser = user
                    updatedUser.profileImageURL = url.absoluteString
                    self.userRelay.accept(updatedUser)
                    UserDefaultsManager.shared.saveUser(updatedUser)
                    return self.loginUsecase.updateUser(updatedUser)
                        .map { updateResult in
                            if case .success = updateResult {
                                return true
                            } else {
                                return false
                            }
                        }
                case .failure:
                    return .just(false)
                }
            }
    }
}

final class StubProfileViewModel: ProfileViewModelType {
    func uploadImage(image: UIImage) -> Observable<Bool> {
        return .just(true)
    }
}
