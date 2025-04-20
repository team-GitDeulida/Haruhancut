//
//  FontSystem.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//

import UIKit

extension UIFont {
    enum HCFont: String {
        case black = "Pretendard-Black"
        case bold = "Pretendard-Bold"
        case extraBold = "Pretendard-ExtraBold"
        case extraLight = "Pretendard-ExtraLight"
        case light = "Pretendard-Light"
        case medium = "Pretendard-Medium"
        case regular = "Pretendard-Regular"
        case semiBold = "Pretendard-SemiBold"
        case thin = "Pretendard-Thin"
    }
}

extension UIFont {
    static func hcFont(_ font: HCFont, size: CGFloat) -> UIFont {
        return UIFont(name: font.rawValue, size: size.scaled) ?? UIFont.systemFont(ofSize: DynamicSize.scaledSize(size))
    }
}


/*
 [사용 예시]
 titleLabel.font = HCFont.mainTitle.value
 subtitleLabel.font = HCFont.subTitle.value
 label.font = HCFont.mainLabel.value
 button.titleLabel?.font = HCFont.button.value
 logoLabel.font = HCFont.logo.value
 */

/*
enum HCFont {
    case logo
    case mainTitle
    case subTitle
    case mainLabel
    case subLabel
    case button
}

extension HCFont {
    
    /// 최종 스타일
    ///
    ///  - 폰트 + 크기 가져옴
    ///  - 폰트가 없으면 systemFont로 fallback 처리
    var value: UIFont {
        UIFont(name: fontName, size: DynamicSize.scaledSize(fontSize))
        ?? UIFont.systemFont(ofSize: DynamicSize.scaledSize(fontSize), weight: fallbackWeight)
    }

    /// 줄 간격 비율
    ///
    /// - 줄간격 설정에 사용
    ///
    var lineHeightMultiple: CGFloat {
        switch self {
        case .logo: return 1.1
        case .mainLabel, .subLabel: return 1.6
        case .mainTitle, .subTitle, .button: return 1.35
        }
    }

    /// 커스텀 폰트 이름
    private var fontName: String {
        switch self {
        case .logo:
            return "RacingSansOne-Regular"
        case .mainTitle, .subTitle, .button:
            return "Pretendard-SemiBold"
        case .mainLabel, .subLabel:
            return "Pretendard-Regular"
        }
    }

    /// 기준 크기 (point 단위)
    private var fontSize: CGFloat {
        switch self {
        case .logo: return 44
        case .mainTitle: return 24
        case .subTitle: return 20
        case .mainLabel: return 16
        case .subLabel: return 14
        case .button: return 16
        }
    }

    /// 커스텀 폰트 로드 실패 시 fallback 시스템 폰트 굵기
    private var fallbackWeight: UIFont.Weight {
        switch self {
        case .mainLabel, .subLabel: return .regular
        default: return .semibold
        }
    }
}
*/




/*
enum HCFont {
    /// - 폰트 스타일
    case logo1
    case logo2
    case splashSubTitle

    case heading1
    case heading2
    case heading3
    case heading4

    case headline1
    case headline2

    case title
    case mainTitle
    case detailTitle

    case body1
    case body2

    case label1
    case label2
    case label3

    case button
    case buttonBig

    case segment1
    case segment2
}

extension HCFont {
    
    /// 최종 적용 폰트
    ///
    /// - HCFont.title.value
    var value: UIFont {
        UIFont(name: fontName, size: DynamicSize.scaledSize(fontSize))
        ?? UIFont.systemFont(ofSize: DynamicSize.scaledSize(fontSize), weight: fallbackWeight)
    }

    /// 라인 높이 비율
    var lineHeightMultiple: CGFloat {
        switch self {
        case .logo1, .logo2: return 1.10
        case .label1, .label2: return 1.60
        case .body1, .body2: return 1.50
        case .headline1, .headline2, .label3: return 1.45
        case .heading2: return 1.40
        case .splashSubTitle, .heading1, .heading3, .heading4,
             .title, .mainTitle, .detailTitle, .button, .buttonBig: return 1.35
        case .segment1, .segment2: return 1.20
        }
    }

    /// 폰트 이름
    private var fontName: String {
        switch self {
        case .logo1, .logo2:
            return "RacingSansOne-Regular"
        case .splashSubTitle:
            return "NanumMyeongjo-Regular"
        case .heading1, .heading2, .heading3, .heading4,
             .headline1, .title, .mainTitle, .detailTitle,
             .button, .buttonBig, .segment1:
            return "Pretendard-SemiBold"
        case .headline2, .body1, .body2, .label2, .segment2:
            return "Pretendard-Regular"
        case .label1:
            return "Pretendard-Bold"
        case .label3:
            return "Pretendard-SemiBold"
        }
    }

    /// 기본 폰트 크기
    private var fontSize: CGFloat {
        switch self {
        case .logo1: return 44
        case .logo2: return 28
        case .splashSubTitle: return 16

        case .heading1: return 22
        case .heading2: return 20
        case .heading3: return 22
        case .heading4: return 36

        case .headline1: return 18
        case .headline2: return 18

        case .title: return 24
        case .mainTitle: return 26
        case .detailTitle: return 32

        case .body1: return 16
        case .body2: return 14

        case .label1, .label2, .label3: return 14

        case .button: return 24
        case .buttonBig: return 24

        case .segment1, .segment2: return 16
        }
    }

    /// 시스템 폰트 fallback weight
    private var fallbackWeight: UIFont.Weight {
        switch self {
        case .label1: return .bold
        case .label2, .headline2, .body1, .body2, .segment2:
            return .regular
        default:
            return .semibold
        }
    }
}
*/
