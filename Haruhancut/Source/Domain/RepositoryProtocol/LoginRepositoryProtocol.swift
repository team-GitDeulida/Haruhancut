//
//  LoginRepositoryProtocol.swift
//  Haruhancut
//
//  Created by 김동현 on 4/10/25.
//

import Foundation
import RxSwift

protocol LoginRepositoryProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
}
