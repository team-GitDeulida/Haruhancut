//
//  AlarmManager.swift
//  Haruhancut
//
//  Created by 김동현 on 5/22/25.
//

import UIKit

/*
 알림 기존 방식
 1. 확인 알림
 let alert = UIAlertController(title: "사진 저장",
                               message: "사진이 앨범에 저장되었습니다.",
                               preferredStyle: .alert)
 alert.addAction(UIAlertAction(title: "확인", style: .default))
 present(alert, animated: true)
 
 2. 삭제/취소 알림
 let alert = UIAlertController(title: "삭제 확인",
                               message: "이 사진을 삭제하시겠습니까?",
                               preferredStyle: .alert)
 alert.addAction(UIAlertAction(title: "취소", style: .cancel))
 alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { [weak self] _ in
     self?.homeViewModel.deletePost(post)
 }))
 present(alert, animated: true)
 */

final class AlertManager {
    
    static func showAlert(
        on viewController: UIViewController,
        title: String,
        message: String,
        actions: [UIAlertAction] = [UIAlertAction(title: "확인", style: .default)]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        viewController.present(alert, animated: true)
    }
    
    static func showError(on vc: UIViewController, message: String) {
        showAlert(on: vc, title: "에러", message: message)
    }

    static func showConfirmation(
        on vc: UIViewController,
        title: String,
        message: String,
        confirmTitle: String = "확인",
        cancelTitle: String = "취소",
        confirmHandler: (() -> Void)? = nil
    ) {
        let confirm = UIAlertAction(title: confirmTitle, style: .default) { _ in confirmHandler?() }
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel)
        showAlert(on: vc, title: title, message: message, actions: [confirm, cancel])
    }
}
