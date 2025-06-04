//
//  CalendarViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/4/25.
//
// https://velog.io/@s_sub/새싹-iOS-11주차

import UIKit
import FSCalendar

final class CalendarViewController: UIViewController {
    
    // MARK: - UI Component
    private lazy var calendarView: FSCalendar = {
        let calendar = FSCalendar()
        
        // 프로토콜 연결
        calendar.dataSource = self
        calendar.delegate = self
        
        // 셀 모양 사각형 설정
        // calendar.appearance.borderRadius = 0.3
        
        // 첫 열을 월요일로 설정
        calendar.firstWeekday = 2
        
        // week 또는 month 가능
        calendar.scope = .month
        
        calendar.scrollEnabled = true
        calendar.locale = Locale(identifier: "ko_KR")
        
        // 현재 달의 날짜들만 표기하도록 설정
        calendar.placeholderType = .none
        
        // 헤더뷰 설정
        calendar.headerHeight = 55
        calendar.appearance.headerDateFormat = "MM월"
        calendar.appearance.headerTitleColor = .mainWhite
        
        // 요일 UI 설정
        calendar.appearance.weekdayFont = UIFont.hcFont(.regular, size: 12.scaled)
        calendar.appearance.weekdayTextColor = .mainWhite
        
        // 날짜별 UI 설정
        calendar.appearance.titleDefaultColor = .mainWhite
        calendar.appearance.titleTodayColor = .mainWhite
        calendar.appearance.titleFont = UIFont.hcFont(.bold, size: 18.scaled)
        calendar.appearance.subtitleFont = UIFont.hcFont(.medium, size: 10.scaled)
        calendar.appearance.subtitleTodayColor = .kakao
        calendar.appearance.todayColor = .clear
        
        // 일요일 라벨의 textColor는 red로 설정
        calendar.calendarWeekdayView.weekdayLabels.last!.textColor = .red
        
        // 선택 배경 사라지게
        calendar.appearance.selectionColor = .clear
        
        return calendar
    }()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
        calendarView.register(RectangleCalendarCell.self, forCellReuseIdentifier: "RectangleCalendarCell")
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        view.addSubview(calendarView)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarView.heightAnchor.constraint(equalToConstant: 500)
        ])
    }
    
    /// 캘린더 뷰 생성 클로저 안에서 개별적으로 지정 달 이동/캘린더 리로드 등 상태 변경 시 다시 흰색으로 돌아옴 -> viewDidLayoutSubviews에서 요일색상 설정하자
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let labels = calendarView.calendarWeekdayView.weekdayLabels
        
        /// 아래는 7개일때만 실행 보장
        guard labels.count == 7 else { return }
        labels[5].textColor = .systemRed
        labels[6].textColor = .systemBlue
        for i in 0..<5 {
            labels[i].textColor = .mainWhite
        }
    }
}

// MARK: - FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance
extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    // 달력 뷰 높이 등 크기 변화 감지(UI 동적 레이아웃 맞출 때 활용)
    /*
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {

    }
     */
    
    // 오늘 cell에 subtitle 생성
    /*
    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(abbreviation: "KST")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        switch dateFormatter.string(from: date) {
        case dateFormatter.string(from: Date()):
            return "오늘"
            
        default:
            return nil
            
        }
    }
     */
    
    // 특정 요일에 해당되는 날짜의 색상 설정
    /*
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return .systemRed      // 일요일
        case 7: return .systemBlue     // 토요일
        default: return .mainWhite     // 평일
        }
    }
     */
    
    // 선택된 날짜의 배경 색상 변경
    /*
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        return .hcColor
    }
     */
    
    // 선택된 날짜의 숫자 색상 변경
    /*
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor? {
        return .mainBlack // 원하는 색상으로!
    }
     */
    
    // 기본 셀 이미지 표시
    /*
    func calendar(_ calendar: FSCalendar, imageFor date: Date) -> UIImage? {
        // return UIImage(named: "Jito")
        guard let image = UIImage(named: "Jito") else { return nil }
        return image.resized(to: CGSize(width: 30, height: 30), cornerRadius: 10) // 원하는 크기로
    }
     */

    // 커스텀 셀 이미지 표시
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: "RectangleCalendarCell", for: date, at: position) as! RectangleCalendarCell
        
        // 오늘 날짜인지 비교해서 전달
        let calendar = Calendar.current
        cell.isToday = calendar.isDateInToday(date)

        // 원하는 조건대로 이미지 넣기 (테스트용 전체에)
        cell.setImage(image: UIImage(named: "Jito")?.resized(to: CGSize(width: 40, height: 40), cornerRadius: 8))
        
        // cell.backImageView.image = UIImage(named: "Jito")?.resized(to: CGSize(width: 40, height: 40), cornerRadius: 8)
        return cell
    }
}

#Preview {
    CalendarViewController()
}

final class RectangleCalendarCell: FSCalendarCell {
    
    var isToday: Bool = false
    
    private let cellImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let selectedOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    override init!(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
    }

    required init!(coder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeUI() {
        contentView.insertSubview(cellImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: cellImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 1. cellImageView와 selectedOverlay 똑같이 배치 (정중앙 정사각형)
        let minSide = min(contentView.bounds.width, contentView.bounds.height) - 6
        let frame = CGRect(
            x: (contentView.bounds.width - minSide) / 2,
            y: (contentView.bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        cellImageView.frame = frame
        cellImageView.layer.cornerRadius = minSide / 4
        
        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 4
        
        // 2. 숫자(타이틀) 완전 정중앙!
        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
    
        // 3. 선택시 오버레이만 반투명 빨간색, 아니면 투명
        selectedOverlay.backgroundColor = isSelected
            ? UIColor.hcColor.withAlphaComponent(0.4)
            : .clear

        // titleLabel.font = .hcFont(.bold, size: 15.scaled)
        
        // 4. 오늘이면 테두리 Stroke 추가
        if isToday {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }
    }

    func setImage(image: UIImage?) {
        self.cellImageView.image = image
    }
}

final class CircleCalendarCell: FSCalendarCell {
    let backImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    // 선택 시 반투명 빨간색 오버레이
    let selectedOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.insertSubview(backImageView, at: 0)
        contentView.insertSubview(selectedOverlay, aboveSubview: backImageView)
    }
    
    required init(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let minSide = min(contentView.bounds.width, contentView.bounds.height) - 6
        let frame = CGRect(
            x: (contentView.bounds.width - minSide) / 2,
            y: (contentView.bounds.height - minSide) / 2,
            width: minSide,
            height: minSide
        )
        backImageView.frame = frame
        backImageView.layer.cornerRadius = minSide / 2
        
        // 오버레이도 동일한 프레임과 둥글기
        selectedOverlay.frame = frame
        selectedOverlay.layer.cornerRadius = minSide / 2
        
        let labelSize = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(
            x: (contentView.bounds.width - labelSize.width) / 2,
            y: (contentView.bounds.height - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        
        // 선택시 오버레이만 반투명 빨간색, 아니면 투명
        selectedOverlay.backgroundColor = isSelected
            ? UIColor.red.withAlphaComponent(0.4) // ← 적당히 조절
            : .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backImageView.image = nil
        selectedOverlay.backgroundColor = .clear
    }
}

