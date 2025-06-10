//
//  PhotoWIdget.swift
//  WidgetExtensionExtension
//
//  Created by 김동현 on 6/10/25.
//
// https://iosangbong.tistory.com/26

import WidgetKit
import SwiftUI

// 1) Entry 모델: Widget에 표시할 데이터
struct PhotoEntry: TimelineEntry {
    let date: Date
    let imageData: Data?
}

// 2) Provider: 타임라인 데이터를 공급하는 타입
struct PhotoProvider: TimelineProvider {
    let appGroupID = "group.com.indextrown.Haruhancut.WidgetExtension"
    
    // 2-1) 위젯 갤러리나 로드 중에 보여줄 플레이스 홀더
    func placeholder(in context: Context) -> PhotoEntry {
        PhotoEntry(date: Date(), imageData: nil)
    }
    
    // 2-2) 위젯 편집 화면 미리보기(스냅샷)
    func getSnapshot(in context: Context, completion: @escaping @Sendable (PhotoEntry) -> Void) {
        let entry = PhotoEntry(date: Date(), imageData: nil)
        completion(entry)
    }
    
    // 2-3) 실제 타임라인: 매일 자정(오전 0시 00분 05초)에 업데이트
    func getTimeline(in context: Context, completion: @escaping (Timeline<PhotoEntry>) -> Void) {
        let now = Date()
        
        // 1) 오늘 폴더에서 jpg 파일만 가져와서
        let allFiles = fetchImageFiles(date: now)
        
        // 2) 파일명 내림차순(가장 최신 타임스탬프가 먼저) → 첫 번째 URL만 Data로 변환
        let latestData = allFiles
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .first
            .flatMap { try? Data(contentsOf: $0) }
        
        // 3) 어제 폴더 삭제 (오늘 날짜 기준 이전 폴더들)
        deleteOldPhotoFolders(before: now)
        
        let entry = PhotoEntry(date: now, imageData: latestData)
        
        // 4) 다음 자정에 갱신
        let nextMidnight = computeNextMidnight(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
    
    // ────────────────────────────────────────────────────────────
    // 3) Helper 함수들
    // 3-1) 해당 날짜의 사진 데이터를 가져오는 함수
    private func fetchImageFiles(date: Date) -> [URL] {
        let dateString = DateFormatter.photoFilenameFormatter.string(from: date)
        guard
            let folder = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent("Photos", isDirectory: true)
                .appendingPathComponent(dateString, isDirectory: true),
            let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        else {
            return []
        }
        
        return files.filter { $0.pathExtension.lowercased() == "jpg" }
    }

    // 3-2) 다음 자정(00:00:05) 시각을 계산하는 함수
    private func computeNextMidnight(after date: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        // 오늘 날짜 기준으로, 내일 00시 00분 05초
        comps.day! += 1
        comps.hour = 0
        comps.minute = 0
        comps.second = 5
        return Calendar.current.date(from: comps)!
    }
    
    // 3-3) 사진 삭제
    private func deleteOldPhotoFolders(before date: Date) {
        guard let photoBaseFolder = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("Photos", isDirectory: true)
        else { return }

        guard let folderContents = try? FileManager.default.contentsOfDirectory(at: photoBaseFolder, includingPropertiesForKeys: nil) else { return }

        let todayString = DateFormatter.photoFilenameFormatter.string(from: date)

        for folderURL in folderContents {
            guard folderURL.hasDirectoryPath else { continue }

            let folderName = folderURL.lastPathComponent
            if folderName < todayString {
                // 오늘 이전 날짜의 폴더는 삭제
                try? FileManager.default.removeItem(at: folderURL)
            }
        }
    }

}

// 4) EntryView: 실제 화면 그리는 SwiftUI View
struct PhotoWIdgetView: View {
    let entry: PhotoEntry
    
    // 2열 그리드 정의
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        if let data = entry.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .widgetURL(URL(string: "myapp://photo/\(entry.date.timeIntervalSince1970)"))
                .widgetBackground(.clear)
        } else {
            // 사진이 없으면 플레이스홀더
            Image("placeholder")
                .resizable()
                .scaledToFill()
                .widgetBackground(.black)
        }
    }

}

// 5) @main 진입점: StaticConfiguration으로 선언
@main
struct PhotoWidgets: Widget {
    let kind: String = "PhotoWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PhotoProvider()) { entry in
                PhotoWIdgetView(entry: entry)
            }
            .supportedFamilies([
                .systemSmall,
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline
           ]) // systemMedium, systemLarge
            .configurationDisplayName("하루한컷")
            .description("앱 공유 컨테이너에 저장된 오늘의 사진을 하루 한 장씩 보여줍니다.")
            .contentMarginsDisabled()
    }
}

// MARK: - iOS17 이상일 경우 containerBackground를 17 미만일 경우에는 Background가 return
extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                color
            }
        } else {
            return background(color)
        }
    }
}


// 6) DateFormatter 확장: 파일 이름 생성용
extension DateFormatter {
    static let photoFilenameFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
