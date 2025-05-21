//
//  FirebaseStorageManager.swift
//  Haruhancut
//
//  Created by 김동현 on 5/21/25.
//

import UIKit
import FirebaseStorage
import RxSwift

// https://cloud.google.com/storage/pricing?hl=ko

final class FirebaseStorageManager {
    static let shared = FirebaseStorageManager()
    private init() {}
}

extension FirebaseStorageManager {
    func uploadImage(image: UIImage, path: String) -> Observable<URL?> {
        return Observable.create { observer in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("❌ JPEG 변환 실패")
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            
            let ref = Storage.storage().reference().child(path)
            
            // 업로드 시작
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                // 업로드 성공 후 다운로드 uri 요청
                ref.downloadURL { url, error in
                    if let error = error {
                        print("❌ downloadURL 실패: \(error.localizedDescription)")
                        observer.onNext(nil)
                    } else if let url = url {
                        print("✅ 이미지 업로드 및 URL 확보 성공: \(url.absoluteString)")
                        observer.onNext(url)
                    } else {
                        print("❌ URL 없음 (downloadURL nil)")
                        observer.onNext(nil)
                    }
                }
            }
            return Disposables.create()
        }
    }
}
