//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/13/25.
//

import FirebaseAuth
import RxSwift

enum ProviderID: String {
    case kakao
    case apple
    
    var authProviderID: AuthProviderID {
        switch self {
        case .kakao: return .custom("oidc.kakao")
        case .apple: return .apple
        }
    }
    
    /*
    var rawNonce: String {
        switch self {
        case .apple: return NonceGenerator.generate()
        default: return ""
        }
    }
     */
}

protocol FirebaseAuthManagerProtocol {
    func signIn(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>>
}

// firebaseAuthManager.signIn(providerID: "kakao", idToken: kakaoToken)
// firebaseAuthManager.signIn(providerID: "apple", idToken: appleToken)
final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
    
    static let shared = FirebaseAuthManager()
    private init() {}
    
    // escaping -> Rx로 래핑
    func signIn(prividerID: String, idToken: String) -> Observable<Result<Void, LoginError>> {
        
        guard let provider = ProviderID(rawValue: prividerID) else {
            return Observable.just(.failure(LoginError.signUpError))
        }
        
        let credential = OAuthProvider.credential(
            providerID: provider.authProviderID,
            idToken: idToken,
            rawNonce: "")
        
        return Observable.create { observer in
            Auth.auth().signIn(with: credential) { _, error in
                
                if let _ = error {
                    observer.onNext(.failure(LoginError.signUpError))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
