//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by 김동현 on 6/10/25.
//

/*
import WidgetKit
import SwiftUI


/// 1)  Provider: 타임라인 데이터를 공급하는 타입
/// AppIntentTimelineProvider 프로토콜을 채택하여
/// 1) placeholder: 위젯 로딩 시 보여줄 기본 뷰
/// 2) snapshot: 위젯 갤러리(미리보기)에서 보여줄 스냅샷
/// 3) timeline: 실제 운영 시 시간별로 갱신할 데이터를 제공
struct Provider: AppIntentTimelineProvider {
    
    /// placeholder(in:)
    /// - Purpose: 위젯이 아직 로드되지 않았을 때(예: 위젯 추가 시) 보여줄 기본 Entry
    /// - Returns: 현재 시간과 기본 설정(ConfigurationAppIntent)으로 생성한 SimpleEntry
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    /// snapshot(for:in:)
    /// - Purpose: 위젯 갤러리(위젯 선택 화면)에서 미리보기용으로 빠르게 보여줄 단일 스냅샷
    /// - Parameters:
    ///   - configuration: 사용자가 선택한 인텐트 설정
    ///   - context: 위젯 환경 정보
    /// - Returns: 현재 시간과 전달받은 설정으로 만든 SimpleEntry
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    /// timeline(for:in:)
    /// - Purpose: 위젯이 운영 중일 때, 언제 어떤 데이터를 보여줄지 정의
    /// - 동작:
    ///   1. currentDate 기준 0~4시간 후까지 5개의 Entry 생성
    ///   2. 각각의 Entry에 configuration과 시간 정보를 담아 배열에 추가
    ///   3. `.atEnd` 정책: 마지막 타임라인이 끝나면 다시 provider를 호출하여 새 데이터를 요청
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        // 1) 현재 시각 가져오기
        let currentDate = Date()
        
        // 2) 0시작, 1시간씩 총 5번 반복
        for hourOffset in 0 ..< 5 {
            // Calendar를 사용해 currentDate에 hourOffset시간을 더한 Date 생성
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // 필요시 relevances() 구현 가능:
    // 위젯이 어떤 컨텍스트(예: 잠금 화면, 홈 화면)에서 우선순위 있게 표시될지 정의
//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

// MARK: - 2) Entry 모델: 위젯에 표시할 단일 스냅샷 데이터
/// TimelineEntry 프로토콜을 채택한 모델
/// - date: 해당 Entry가 보여질 시각
/// - configuration: 사용자가 선택한 인텐트(여기선 favoriteEmoji) 정보
struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

// MARK: - 3) EntryView: 실제 화면을 그리는 SwiftUI 뷰
/// WidgetExtensionEntryView는 SimpleEntry를 받아서
/// 1) 시간 표시
/// 2) 사용자가 선택한 이모지 표시
struct WidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Favorite Emoji:")
            Text(entry.configuration.favoriteEmoji)
        }
    }
}

// MARK: - 4) @main 진입점: iOS 17에서는 WidgetBundle 대신 단일 Widget 타입으로만 선언
/// Widget 프로토콜을 채택한 WidgetExtension 구조체
/// - kind: 위젯 식별자
/// - body: AppIntentConfiguration을 사용해 위젯 설정
// MARK: - @main 추가
@main
struct WidgetExtension: Widget {
    // 위젯 고유 식별자 (Info.plist나 code에서 사용)
    let kind: String = "WidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind,
                               intent: ConfigurationAppIntent.self,
                               provider: Provider()) { entry in
            // Provider가 반환한 Entry를 바탕으로 뷰를 생성
            WidgetExtensionEntryView(entry: entry)
            // 컨테이너 배경색 설정 (위젯 전체 배경)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        // 이 위젯이 지원하는 크기 (작은 크기만)
        .supportedFamilies([.systemSmall])
        // 위젯 갤러리에서 보여질 이름
        .configurationDisplayName("시간 & 이모지 위젯")
        // 갤러리 설명
        .description("현재 시간과 좋아하는 이모지를 보여줍니다.")
    }
}

// 5) 샘플 미리보기 옵션
extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    WidgetExtension()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}



*/
