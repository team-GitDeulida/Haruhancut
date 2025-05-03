//
//  Date+.swift
//  Haruhancut
//
//  Created by 김동현 on 4/16/25.
//

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
