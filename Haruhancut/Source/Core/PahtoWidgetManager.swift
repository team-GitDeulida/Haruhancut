//
//  PahtoWidgetManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/10/25.
//

import UIKit

// 1) DateFormatter 확장: 파일명용 (날짜+시간)
extension DateFormatter {
    /// "yyyy-MM-dd-HH-mm-ss" 포맷의 타임스탬프
    static let widgetFilenameFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()
}

// 2) PhotoWidgetManager 수정
final class PhotoWidgetManager {
    static let shared = PhotoWidgetManager()
    let appGroupID = "group.com.indextrown.Haruhancut.WidgetExtension"

    /// 오늘 사진을 "yyyy-MM-dd-HH-mm-ss-<UUID>.jpg" 로 저장
    func saveTodayImage(_ image: UIImage, identifier: String) {
        let dateKey    = Date().toDateKey()  // "2025-06-10"
        let timestamp  = DateFormatter.widgetFilenameFormatter
                            .string(from: Date()) // "2025-06-10-14-23-08"
        let fileName   = "\(timestamp)-\(identifier).jpg"
        
        guard let data = image.jpegData(compressionQuality: 0.8),
              let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateKey, isDirectory: true)
        else {
            print("❌ 컨테이너 URL 생성 실패")
            return
        }
        
        // 디렉토리 생성
        do {
            try FileManager.default.createDirectory(at: containerURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            print("❌ 폴더 생성 실패:", error)
        }
        
        // 파일 저장
        let fileURL = containerURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
            print("▶️ 오늘 사진 저장:", fileURL.lastPathComponent)
        } catch {
            print("❌ 사진 저장 실패:", error)
        }
    }
    
    /// dateKey 폴더 안에서 identifier(=postId)가 포함된 파일을 모두 삭제
    func deleteImage(dateKey: String, identifier: String) {
        let appGroupID = self.appGroupID
        guard let folder = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateKey, isDirectory: true)
        else { return }

        if let files = try? FileManager.default.contentsOfDirectory(at: folder,
                                                                    includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.contains(identifier) {
                do {
                    try FileManager.default.removeItem(at: file)
                    print("▶️ 위젯 컨테이너에서 삭제:", file.lastPathComponent)
                } catch {
                    print("❌ 위젯 컨테이너 삭제 실패:", error)
                }
            }
        }
    }
}

extension PhotoWidgetManager {
    
}

/*


//
//import UIKit
//
//class PhotoWidgetManager {
//    static let shared = PhotoWidgetManager()
//    private let appGroupId = "group.com.indextrown.Haruhancut.WidgetExtension"
//
//    /// 오늘 올린 사진을 App Group 컨테이너의 Photos/YYYY-MM-dd 폴더에 저장
//    func saveTodayImage(_ image: UIImage) {
//        guard let data = image.jpegData(compressionQuality: 0.8),
//              let containerURL = FileManager.default
//                .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
//        else {
//            print("⚠️ 공유 컨테이너 접근 실패 또는 JPEG 변환 실패")
//            return
//        }
//
//        let photosRoot = containerURL.appendingPathComponent("Photos", isDirectory: true)
//        // 루트 폴더 생성
//        if !FileManager.default.fileExists(atPath: photosRoot.path) {
//            try? FileManager.default.createDirectory(at: photosRoot,
//                                                     withIntermediateDirectories: true)
//        }
//
//        // 1) 이전 날짜 폴더 삭제
//        if let subdirs = try? FileManager.default.contentsOfDirectory(at: photosRoot,
//                                                                      includingPropertiesForKeys: nil) {
//            for url in subdirs where url.hasDirectoryPath {
//                try? FileManager.default.removeItem(at: url)
//            }
//        }
//
//        // 2) 오늘 날짜 폴더 생성
//        let todayString = DateFormatter.photoFilenameFormatter.string(from: Date())
//        let todayFolder = photosRoot.appendingPathComponent(todayString, isDirectory: true)
//        if !FileManager.default.fileExists(atPath: todayFolder.path) {
//            try? FileManager.default.createDirectory(at: todayFolder,
//                                                     withIntermediateDirectories: true)
//        }
//
//        // 3) 타임스탬프 파일명 생성
//        let timeString = DateFormatter.photoTimeFormatter.string(from: Date())
//        let fileURL = todayFolder.appendingPathComponent("\(timeString).jpg")
//
//        // 4) 파일 쓰기
//        do {
//            try data.write(to: fileURL, options: .atomic)
//            print("✅ 사진 저장 완료: \(fileURL.path)")
//        } catch {
//            print("❌ 사진 저장 실패:", error)
//        }
//    }
//}
//// MARK: - DateFormatter 확장
//extension DateFormatter {
//    /// "yyyy-MM-dd" (날짜별 폴더 명)
//    static let photoFilenameFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.calendar = .init(identifier: .gregorian)
//        df.locale = .init(identifier: "en_US_POSIX")
//        df.timeZone = .current
//        df.dateFormat = "yyyy-MM-dd"
//        return df
//    }()
//
//    /// "HH-mm-ss" (파일 타임스탬프 명)
//    static let photoTimeFormatter: DateFormatter = {
//        let df = DateFormatter()
//        df.calendar = .init(identifier: .gregorian)
//        df.locale = .init(identifier: "en_US_POSIX")
//        df.timeZone = .current
//        df.dateFormat = "HH-mm-ss"
//        return df
//    }()
//}
*/
