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
        
        // 현재 월이 아니면 return
        guard monthPosition == .current else { return }
        
        let dateString = date.toDateKey()
        
        guard let posts = homeViewModel.group.value?.postsByDate[dateString], !posts.isEmpty else { return }
        // let imageUrls = posts.map { $0.imageURL }
        // let viewer = ImageScrollViewController(imageUrls: imageUrls, homeViewModel: homeViewModel)
        let viewer = ImageScrollViewController(posts: posts, homeViewModel: homeViewModel, selectedDate: dateString)
        viewer.modalPresentationStyle = .fullScreen
        
        /// onPresent 콜백 호출
        onPresent?(viewer)
    }
}

#Preview {
    CalendarViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0]))
}

final class ImageScrollViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModelType
    private var posts: [Post]
    private var currentIndex: Int = 0
    private let selectedDate: String
    
    // MARK: - UI Component
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 40
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        return button
    }()
    
    init(posts: [Post], homeViewModel: HomeViewModelType, selectedDate: String) {
        self.posts = posts
        self.homeViewModel = homeViewModel
        self.selectedDate = selectedDate
        super.init(nibName: nil, bundle: nil)
        // self.commentButton.setCount(posts[currentIndex].comments.count)
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        makeUI()
        constraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        [collectionView, closeButton, commentButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            
            // MARK: - 캘린더
            // 위치
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            // 크기
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor),
            
            // MARK: - 닫기
            // 위치
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // 크기
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // MARK: - 댓글
            commentButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            commentButton.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        // print("[DEBUG] 선택된 날짜 posts:", self.posts)
        commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // print("[DEBUG] 댓글 버튼 클릭, 현재 index의 post:", self.posts[self.currentIndex])
                let commentVC = PostCommentViewController(homeViewModel: homeViewModel, post: posts[self.currentIndex])
                commentVC.modalPresentationStyle = .pageSheet
                self.present(commentVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        homeViewModel.group
            .compactMap { $0?.postsByDate[self.selectedDate] }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] latestPosts in
                guard let self = self else { return }
                self.posts = latestPosts
                // print("[DEBUG] latestPosts 확인: ", latestPosts)
                self.collectionView.reloadData()
                if self.posts.indices.contains(self.currentIndex) {
                    let post = self.posts[self.currentIndex]
                    self.commentButton.setCount(post.comments.count)
                }
            })
            .disposed(by: disposeBag)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeTapped() {
        dismiss(animated: true)
    }
}

/*
final class ImageScrollViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let homeViewModel: HomeViewModelType
    private var posts: [Post]
    private var currentIndex: Int = 0
    // private let imageUrls: [String]
    
    // MARK: - UI Component
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 40
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("닫기", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var commentButton: HCCommentButton = {
        let button = HCCommentButton(image: UIImage(systemName: "message")!, count: 0)
        return button
    }()
    
//    init(imageUrls: [String], homeViewModel: HomeViewModelType) {
//        self.imageUrls = imageUrls
//        self.homeViewModel = homeViewModel
//        super.init(nibName: nil, bundle: nil)
//    }
    init(posts: [Post], homeViewModel: HomeViewModelType) {
        self.posts = posts
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        makeUI()
        constraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        [collectionView, closeButton, commentButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            
            // MARK: - 캘린더
            // 위치
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            
            // 크기
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.heightAnchor.constraint(equalTo: collectionView.widthAnchor),
            
            // MARK: - 닫기
            // 위치
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // 크기
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // MARK: - 댓글
            commentButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            commentButton.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -20)
        ])
    }
    
    private func bindViewModel() {
        commentButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let commentVC = PostCommentViewController(homeViewModel: homeViewModel, post: posts[currentIndex])
                commentVC.modalPresentationStyle = .pageSheet
                self.present(commentVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 게시물 업데이트 감지 후 댓글 수 반영 및 이미지 갱신
        homeViewModel.posts
            .compactMap { [weak self] (posts: [Post]) -> Post? in
                guard let self = self else { return nil }
                let currentIndex = self.currentIndex
                // 현재 인덱스 범위 체크 (Crash 방지)
                guard self.posts.indices.contains(currentIndex) else { return nil }
                let targetPostId = self.posts[currentIndex].postId
                // posts에서 해당 postId를 가진 post 찾기
                return posts.first(where: { $0.postId == targetPostId })
            }
            .distinctUntilChanged { $0.comments.count == $1.comments.count }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] updatedPost in
                guard let self = self else { return }
                self.posts[self.currentIndex] = updatedPost
                self.commentButton.setCount(updatedPost.comments.count)
            })
            .disposed(by: disposeBag)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeTapped() {
        dismiss(animated: true)
    }
}
*/
 
extension ImageScrollViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
       
        let post = posts[indexPath.item]
        cell.setKFImage(url: post.imageURL)
        
        // MARK: - 이미지 콜백
        cell.onImageTap = { [weak self] image in
            guard let self = self else { return }
            guard let image = image else { return }
            let previewVC = ImagePreviewViewController(image: image)
            previewVC.modalPresentationStyle = .fullScreen
            self.present(previewVC, animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40 // 좌우 20 여백
        return CGSize(width: width, height: width)
    }
    
    // 스크롤시 currentIndex 카운팅
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = collectionView.frame.width
        let offsetX = collectionView.contentOffset.x
        let index = Int(round(offsetX / pageWidth))
        currentIndex = index

        // ⭐️ 댓글 수 즉시 반영
        /// posts 배열에 현재 curidx가 포함되어 있는가 체크 (예: 사진이 3장인데 currentIndex가 0, 1, 2 중 하나인지)
        if posts.indices.contains(currentIndex) {
            /// 현재 보고 있는 사진 post객체를 가져옴
            let post = posts[currentIndex]
            commentButton.setCount(post.comments.count)
        }
    }
}

final class ImageCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 15
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()
    
    // MARK: - 이미지 터치 콟백
    var onImageTap: ((UIImage?) -> Void)?
    
    /// UIView(그리고 UICollectionViewCell, UITableViewCell 등) 생성자(Initializer) 중 하나
    /// UIKit의 거의 모든 View, Cell, Layout은 “프로그래밍으로” 만들 때 init(frame: CGRect)라는 생성자를 사용
    /// frame
    /// “이 View가 superview(상위 뷰)에서 어느 위치, 어느 크기로 들어갈지”를 의미
    /// 보통 코드로 View를 만들 때 직접 frame을 넘겨주거나, 오토레이아웃을 쓰면 frame: .zero로 두고, 제약조건(Constraints)으로 나중에 크기/위치를 결정
    /// 커스텀 셀을 만들 때 반드시 required init?(coder:)와 override init(frame: CGRect) 이 두 개를 구현해야 함
    /// override init(frame: CGRect)는 "코드로 뷰(혹은 셀)를 만들 때, 초기화(셋업) 하는 생성자"다!
    ///  frame: .zero로 넣고 오토레이아웃 쓰는 건 “처음엔 크기 0, 실제 사이즈는 나중에 constraints로 결정”이라는 의미
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
        constraints()
        imageCallback()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func imageCallback() {
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        imageView.addGestureRecognizer(tap)
    }
    
    private func makeUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func setKFImage(url: String) {
        if let url = URL(string: url) {
            imageView.kf.setImage(with: url)
        }
    }
    
    @objc private func handleTap() {
        onImageTap?(imageView.image)
    }
}
