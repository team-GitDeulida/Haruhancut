//
//  AppleLoginManager.swift
//  Haruhancut
//
//  Created by 김동현 on 4/17/25.
//

import Foundation
import RxSwift

// 애플 로그인
import CryptoKit
import AuthenticationServices

protocol AppleLoginManagerProtocol {
    func login() -> Observable<Result<(String, String), LoginError>>
}

final class AppleLoginManager: NSObject, AppleLoginManagerProtocol {
    
    static let shared = AppleLoginManager()
    private override init() {
        super.init()
    }

    // 애플 로그인 결과를 외부에 전달하기 위한 통로
    // ASAuthorizationControllerDelegate는 콜백 기반 -> Rx방식(Observable 스트림)으로 변환을 위함
    private var loginSubject: PublishSubject<Result<(String, String), LoginError>>?
    private var currentNonce: String?
    
    /// 무작위 nonce 문자열 생성
    /// - Parameter length: 생성할 nonce 길이 (기본값: 32)
    /// - Returns: 생성된 nonce 문자열
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// 입력 문자열을 SHA256 해시로 변환
    /// - Parameter input: 해싱할 입력 문자열
    /// - Returns: SHA256 해시 문자열
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// 애플 로그인 수행
    /// - Returns: 로그인 성공 시 AppleId 토큰 문자열, 실패 시 오류를 포함한 Observable
    func login() -> Observable<Result<(String, String), LoginError>> {
        // 항상 새로운 subject로 초기화
        let subject = PublishSubject<Result<(String, String), LoginError>>()
        self.loginSubject = subject

        let nonce = self.randomNonceString()
        self.currentNonce = nonce
        let hashedNonce = self.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()

        return subject.asObservable()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleLoginManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        let credential = authorization.credential as? ASAuthorizationAppleIDCredential
        let tokenData = credential?.identityToken
        let tokenString = tokenData.flatMap { String(data: $0, encoding: .utf8) }
        
        print("✅ Apple Credential: \(String(describing: credential))")
        print("✅ identityToken: \(String(describing: tokenData))")
        print("✅ tokenString: \(String(describing: tokenString))")
        print("✅ currentNonce: \(String(describing: currentNonce))")
        
        if let tokenString, let rawNonce = self.currentNonce {
            self.loginSubject?.onNext(.success((tokenString, rawNonce)))
        } else {
            self.loginSubject?.onNext(.failure(.invalidCredential))
        }
        self.loginSubject?.onCompleted()
        self.loginSubject = nil
    }

//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
//           let tokenData = appleIDCredential.identityToken,
//           let tokenString = String(data: tokenData, encoding: .utf8),
//           let rawNonce = self.currentNonce {
//               loginSubject.onNext(.success((tokenString, rawNonce))) // ✅ 튜플 전달
//        } else {
//            loginSubject.onNext(.failure(.invalidCredential))
//        }
//        loginSubject.onCompleted()
//    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.loginSubject?.onNext(.failure(.sdkApple(error)))
        self.loginSubject?.onCompleted()
        self.loginSubject = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleLoginManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }) ?? UIWindow()
    }
}


