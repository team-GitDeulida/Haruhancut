//
//  Date+.swift
//  Haruhancut
//
//  Created by 김동현 on 4/16/25.
//
// 상대적인 시간 구하기 https://minwoostory.tistory.com/117

import Foundation

extension Date {
    // MARK: - instance 함수 -> 날짜 포맷팅할 때
    /// Date -> String 포매팅
    /// - Returns: String
    func toKoreanDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: self)
    }
    
    /// Date -> String 포매팅
    /// - Returns: String
    func toDateKey() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
    
    func toRelativeString() -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.locale = Locale(identifier: "ko_KR")
        relativeFormatter.unitsStyle = .short // → "5분 전", "2시간 전", "3일 전"
        return relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: self)
    }

    // MARK: - static 함수 -> 날짜를 만들 때
    /// 한국 시간 기준 특정 날짜 생성 (00:00:00)
    /// - Parameters:
    ///   - year: 연
    ///   - month: 월
    ///   - day: 일
    /// - Returns: Date
    static func koreanDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date()
    }
}

