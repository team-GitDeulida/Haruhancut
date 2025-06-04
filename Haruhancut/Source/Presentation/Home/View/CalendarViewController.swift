//
//  CalendarViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/4/25.
//
// https://velog.io/@s_sub/새싹-iOS-11주차

import UIKit
import FSCalendar
import Kingfisher
import RxSwift

final class CalendarViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private var calendarViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Callback
    var onPresent: ((UIViewController) -> Void)?
    
    // MARK: - dependency
    private let homeViewModel: HomeViewModelType
    
    init(homeViewModel: HomeViewModelType) {
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        // calendar.placeholderType = .none
        
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
        bindingViewModel()
        
        /*
        for (date, posts) in homeViewModel.group.value!.postsByDate {
            print("key: \(date)")
            print("value: ")
            for post in posts {
                print(post.imageURL)
            }
            print("\n\n\n")
        }
         */
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        view.addSubview(calendarView)
        calendarView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        calendarViewHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: 500)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // calendarView.heightAnchor.constraint(equalToConstant: 500)
            calendarViewHeightConstraint
        ])
    }
    
    // MARK: - Bindig
    private func bindingViewModel() {
        /// 새로운 그룹 정보를 방출할 때 마다 캘린더 새로고침
        homeViewModel.group
            .bind(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.calendarView.reloadData()
            })
            .disposed(by: disposeBag)
    }
    
    /// 캘린더 뷰 생성 클로저 안에서 개별적으로 지정 달 이동/캘린더 리로드 등 상태 변경 시 다시 흰색으로 돌아옴 -> viewDidLayoutSubviews에서 요일색상 설정하자
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let labels = calendarView.calendarWeekdayView.weekdayLabels
        
        /// 아래는 7개일때만 실행 보장
        guard labels.count == 7 else { return }
        labels[5].textColor = .systemBlue
        labels[6].textColor = .systemRed
        for i in 0..<5 {
            labels[i].textColor = .mainWhite
        }
    }
}

// MARK: - FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance
extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    // 달력 뷰 높이 등 크기 변화 감지(UI 동적 레이아웃 맞출 때 활용)

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarViewHeightConstraint.constant = bounds.height
        view.layoutIfNeeded()
    }

    
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
    
    // 현재 월이 아닌 날짜는 블러처리
    /*
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let calendarSystem = Calendar.current
        
        // 현재 캘린더가 보여주는 월
        let cucrrentPageMonth = calendarSystem.component(.month, from: calendar.currentPage)
        let currentPageYear = calendarSystem.component(.year, from: calendar.currentPage)
        
        // 각 셀의 날짜 월
        let dateMonth = calendarSystem.component(.month, from: date)
        let dateYear = calendarSystem.component(.year, from: date)
        
        if cucrrentPageMonth == dateMonth && currentPageYear == dateYear {
            return .mainWhite
        } else {
            return UIColor.mainWhite.withAlphaComponent(0.2) // 다른달: 흐리게
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
        cell.isCurrentMonth = (position == .current)
        
        // 날짜 -> String(key) 변환
        let dateString = date.toDateKey()
        
        if position == .current {
            if let posts = homeViewModel.group.value?.postsByDate[dateString], let firstPost = posts.first {
                // 해당 날짜에 이미지가 있다면첫 이미지만 표시
                cell.setImage(url: firstPost.imageURL)
            } else {
                cell.setGrayBox()
                // cell.setImage(image: UIImage(named: "Jito")?.resized(to: CGSize(width: 40, height: 40), cornerRadius: 8))
            }
        } else {
            cell.setDarkGrayBox()
        }
        return cell
    }
    
    // 셀 터치 감지
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let dateString = date.toDateKey()
        
        guard let posts = homeViewModel.group.value?.postsByDate[dateString], !posts.isEmpty else { return }
        let imageUrls = posts.map { $0.imageURL }
        let viewer = CalendarImageViewerViewController(imageUrls: imageUrls)
        viewer.modalPresentationStyle = .fullScreen
        
        /// onPresent 콜백 호출
        onPresent?(viewer)
    }
}

#Preview {
    CalendarViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0]))
}

final class RectangleCalendarCell: FSCalendarCell {
    
    var isToday: Bool = false
    var isCurrentMonth: Bool = false
    
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
        
        // 4. 오늘 && 현재월이면 테두리 Stroke 추가
        if isToday && isCurrentMonth {
            cellImageView.layer.borderWidth = 3
            cellImageView.layer.borderColor = UIColor.hcColor.cgColor
        } else {
            cellImageView.layer.borderWidth = 0
        }
    }

    /// 기본 이미지 설정 방식
    func setImage(image: UIImage?) {
        self.cellImageView.image = image
    }
    
    /// kingfisher 이미지 설정 방식
    func setImage(url: String) {
        guard let url = URL(string: url) else { return }
        cellImageView.kf.setImage(with: url)
    }
    
    /// 기본 이미지
    func setGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .Gray500
    }
    
    /// 기본 이미지
    func setDarkGrayBox() {
        cellImageView.image = nil
        cellImageView.backgroundColor = .Gray700
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


final class CalendarImageViewerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private let imageUrls: [String]
    private let collectionView: UICollectionView

    // 닫기 버튼
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("닫기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 20)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 20
        return btn
    }()

    init(imageUrls: [String]) {
        self.imageUrls = imageUrls
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .black
        collectionView.register(CalendarImageCell.self, forCellWithReuseIdentifier: "CalendarImageCell")
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        view.addSubview(closeButton)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarImageCell", for: indexPath) as! CalendarImageCell
        cell.setKFImage(url: imageUrls[indexPath.item])
        return cell
    }
}

final class CalendarImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.clipsToBounds = true
        return iv
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    func setKFImage(url: String) {
        if let u = URL(string: url) {
            imageView.kf.setImage(with: u)
        }
    }
}


/*

final class ImageViewerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private let imageUrls: [String]
    private let collectionView: UICollectionView
    let horizontalInset: CGFloat = 20
    let itemSpacing: CGFloat = 16

    // 닫기 버튼
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("닫기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 20)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 20
        return btn
    }()

    init(imageUrls: [String]) {
        self.imageUrls = imageUrls

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true

        super.init(nibName: nil, bundle: nil)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.register(ImageViewerCell.self, forCellWithReuseIdentifier: "ImageViewerCell")
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        view.addSubview(collectionView)
        view.addSubview(closeButton)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewerCell", for: indexPath) as! ImageViewerCell
        cell.setKFImage(url: imageUrls[indexPath.item])
        return cell
    }

    // 셀 크기 동적으로 (세로 중앙, 가로 20여백, 정사각형)
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = collectionView.bounds.width - 40
//        let height = width // 정사각형
//        return CGSize(width: width, height: height)
//    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = (horizontalInset * 2) + (itemSpacing * CGFloat(imageUrls.count - 1))
        let width = collectionView.bounds.width - (horizontalInset * 2)
        // 필요에 따라 width 더 줄이기(예: 여러 장 보이게)
        return CGSize(width: width, height: width) // 정사각형
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        // 상하 여백, 좌우 20
        let verticalMargin = (collectionView.bounds.height - (collectionView.bounds.width - 40)) / 2
        return UIEdgeInsets(top: max(20, verticalMargin), left: 20, bottom: max(20, verticalMargin), right: 20)
    }
}

final class ImageViewerCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 15
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func setKFImage(url: String) {
        if let u = URL(string: url) {
            imageView.kf.setImage(with: u)
        }
    }
}
*/
