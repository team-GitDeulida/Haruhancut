//  SettingViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 5/28/25.
//

import UIKit
import FirebaseAuth
import RxSwift
import UserNotifications

final class SettingViewController: UIViewController {
    
    // MARK: - Event
    private let notificationToggleSubject = PublishSubject<Bool>()
    private let cellSelectedSubject     = PublishSubject<IndexPath>()
    
    // 1. 섹션별 데이터
    private var sections = [
        SettingSection(header: "앱 설정", options: [
            .toggle(title: "알림 설정", isOn: UserDefaultsManager.shared.loadNotificationEnabled()),
        ]),
          SettingSection(header: "정보", options: [
            .version(title: "버전 정보", detail: "1.2.3"),
            .privacyPolicy(title: "개인정보처리방침")
          ]),
          SettingSection(header: "계정 관리", options: [
            .withdraw(title: "회원 탈퇴")
          ])
    ]
    
    private let disposeBag = DisposeBag()
    weak var coordinator: HomeCoordinator?

    private let homeViewModel: HomeViewModelType
    private let settingViewModel: SettingViewModelType
    init(homeViewModel: HomeViewModelType, settingViewModel: SettingViewModelType) {
        self.homeViewModel = homeViewModel
        self.settingViewModel = settingViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .background
        tv.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        tv.dataSource = self
        tv.delegate = self
        tv.rowHeight = 50
        tv.separatorStyle = .none
        return tv
    }()
    
    private let logoutButton: UIButton = {
        let button = HCNextButton(title: "로그아웃")
        return button
    }()

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        makeUI()
        constraints()
        bindViewModel()
    }
    
    // MARK: - UI Setting
    private func makeUI() {
        view.backgroundColor = .background
        
        [tableView, logoutButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            logoutButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func bindViewModel() {
        let input = SettingViewModel.Input(
            logoutTapped: logoutButton.rx.tap.asObservable(),
            notificationToggled: notificationToggleSubject.asObservable(),
            cellSelected: cellSelectedSubject.asObservable())
        
        let output = settingViewModel.transform(input: input)
        output.logoutResult
            .drive(onNext: { [weak self] logoutResult in
                guard let self = self else { return }
                switch logoutResult {
                case .success:
                    self.coordinator?.showLogin()
                case .failure:
                    print("로그아웃 실패")
                }
            })
            .disposed(by: disposeBag)
        
        // 2) 토글
        output.notificationResult
            .drive(onNext: { isOn in
                if isOn {
                    self.checkNotificationAuthorization { isAuthorized in
                        DispatchQueue.main.async {
                            if isAuthorized {
                                // ✅ 알림 권한이 있는 경우만 저장 및 on 처리
                                UserDefaultsManager.shared.setNotificationEnabled(enabled: true)
                                self.settingViewModel.alertOn()
                            } else {
                                // ❌ 꺼진 경우: 알림 off 유지 + UI 토글 원래대로 되돌리기
                                self.showNotificationPermissionAlert()
                                
                                // ✅ 강제로 토글 false로 되돌림
                                UserDefaultsManager.shared.setNotificationEnabled(enabled: false)
                                self.resetNotificationToggleToOff()
                            }
                        }
                    }
                } else {
                    // ✅ off일 땐 그대로 처리
                    UserDefaultsManager.shared.setNotificationEnabled(enabled: false)
                    self.settingViewModel.alertOff()
                }
            })
            .disposed(by: disposeBag)


        // 3) 셀 선택
        output.selectionResult
            .drive(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                let option = self.sections[indexPath.section].options[indexPath.row]
                switch option {
                case .toggle:
                    break
                case .version:
                    print("버전 정보 보기")
                case .privacyPolicy:
                    print("개인정보처리방침 보기")
                case .logout:
                    print("로그아웃 클릭됨")
                case .withdraw:
                    print("회원 탈퇴 클릭됨")
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 토글 원래대로 되돌리는 함수
    private func resetNotificationToggleToOff() {
        // tableView 다시 그려서 toggle false 상태 반영
        self.sections[0].options[0] = .toggle(title: "알림 설정", isOn: false)
        self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }

    
    // MARK: - 현재 앱의 알림 권한 상태를 확인
    func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }

    // MARK: - 설정 앱으로 이동 함수
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - 사용자에게 설정으로 유도하는 알림창
    func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "알림이 비활성화되어 있어요",
            message: "알림을 받으려면 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default, handler: { _ in
            self.openAppSettings()
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension SettingViewController: UITableViewDataSource {
    
    // 섹션 개수(섹션에서만 사용)
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    // 헤더 타이틀(섹션에서만 사용)
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    // 헤더가 화면에 나타나기 직전에 호출(섹션에서만 사용)
    func tableView(_ tableView: UITableView,
                   willDisplayHeaderView view: UIView,
                   forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        // 배경 색
        // header.contentView.backgroundColor = UIColor.systemGray6
        // 텍스트 색
        header.textLabel?.textColor = .hcColor
        // 폰트 변경 (원하면)
        // header.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }
    
    // 섹션별 행 개수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].options.count
    }
    
    // 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let option = sections[indexPath.section].options[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as? SettingCell else {
            return UITableViewCell()
        }
        cell.bindeCell(option: option)
        cell.selectionStyle = .none
        
        
        // MARK: - 토글 스위치 변경 시 Subject로 전송
        if option.toggleValue != nil {
            cell.toggleSwitch.rx.isOn
                .skip(1)
                .bind(to: notificationToggleSubject)
                .disposed(by: disposeBag)
        }
        return cell
    }
}

extension SettingViewController: UITableViewDelegate {
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        // let option = sections[indexPath.section].options[indexPath.row]
        tv.deselectRow(at: indexPath, animated: true)
        
        // MARK: - 셀 선택 시 Subject 으로 전송
        cellSelectedSubject.onNext(indexPath)
        
        /*
        switch option {
        case .toggle:
            // 토글 행은 셀 선택으로 토글하지 않음
            break
        case .info:
            break
            
        case .none(let title):
            switch title {
            case "개인정보처리방침":
                // TODO: ViewModel.logout() 호출
                print("개인정보처리방침")
            case "로그아웃":
                // TODO: ViewModel.logout() 호출
                print("로그아웃")
                
            case "회원 탈퇴":
                // TODO: ViewModel.withdraw() 호출
                print("회원 탈퇴")
                
            default:
                break
            }
        }
         */
    }
}

#Preview {
    SettingViewController(homeViewModel: StubHomeViewModel(previewPost: .samplePosts[0]), settingViewModel: StubSettingViewModel())
}

struct SettingSection {
    let header: String?
    var options: [SettingOption]
}

enum SettingOption {
    case toggle(title: String, isOn: Bool)        // 알림 설정 같은 토글
    case version(title: String, detail: String)   // 버전 정보
    case privacyPolicy(title: String)             // 개인정보처리방침
    case logout(title: String)                    // 로그아웃
    case withdraw(title: String)                  // 회원 탈퇴

    // MARK: – 표시할 왼쪽 텍스트
    var title: String {
        switch self {
        case let .toggle(title, _),
             let .version(title, _),
             let .privacyPolicy(title),
             let .logout(title),
             let .withdraw(title):
            return title
        }
    }

    // MARK: – 상세 텍스트: version 케이스에서만 사용
    var detailText: String? {
        switch self {
        case let .version(_, detail):
            return detail
        default:
            return nil
        }
    }

    // MARK: – 토글 값: toggle 케이스에서만 사용
    var toggleValue: Bool? {
        switch self {
        case let .toggle(_, isOn):
            return isOn
        default:
            return nil
        }
    }
}


final class SettingCell: UITableViewCell {
    
    // MARK: - UI
    private let leftLabel: UILabel = {
        let label = UILabel()
        label.text = "왼쪽"
        label.textColor = .mainWhite
        label.numberOfLines = 1
        label.font = .hcFont(.semiBold, size: 18)
        return label
    }()
    
    private let rightLabel: UILabel = {
        let label = UILabel()
        label.text = "오른쪽"
        label.textColor = .mainWhite
        label.numberOfLines = 1
        label.font = .hcFont(.extraBold, size: 16)
        return label
    }()
    
    let toggleSwitch: UISwitch = {
        let sw = UISwitch()
        sw.tintColor = .systemBlue
        return sw
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        makeUI()
        constraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindeCell(option: SettingOption) {
        self.leftLabel.text = option.title
        
        // detailText가 있으면 rightLabel 표시
        if let detail = option.detailText {
            rightLabel.text = detail
            rightLabel.isHidden = false
        } else {
            rightLabel.isHidden = true
        }
        
        if let isOn = option.toggleValue {
            toggleSwitch.isHidden = false
            toggleSwitch.isOn = isOn
        } else {
            toggleSwitch.isHidden = true
        }
        
        // 2) '회원 탈퇴'만 빨간색, 나머지 기본 색
        if case .withdraw = option {
            leftLabel.textColor = .systemRed
        } else {
            leftLabel.textColor = .mainWhite
        }
    }
    
    private func makeUI() {
        self.backgroundColor = .clear
        [leftLabel, toggleSwitch, rightLabel].forEach {
            self.contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func constraints() {
        NSLayoutConstraint.activate([
            leftLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            rightLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        ])
    }
}
