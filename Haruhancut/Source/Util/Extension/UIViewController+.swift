//
//  UIViewController+Extension.swift
//  Haruhancut
//
//  Created by 김동현 on 4/14/25.
//
/*
 https://peppo.tistory.com/62
 */

import UIKit

// MARK: - 외부 터치하면 키보드 내려가는이벤트 - 외부 버튼누르면 키보드는 내려가지만 버튼 동작 안하는 현상 발생.
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension UIViewController {
    func registerKeyboardNotifications(
        bottomConstraint: NSLayoutConstraint,
        defaultOffset: CGFloat = -10,
        animationDuration: TimeInterval = 0.3
    ) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            
            let bottomInset = keyboardFrame.height - self.view.safeAreaInsets.bottom
            bottomConstraint.constant = -bottomInset - 10
            
            UIView.animate(withDuration: animationDuration) {
                self.view.layoutIfNeeded()
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            bottomConstraint.constant = defaultOffset
            
            UIView.animate(withDuration: animationDuration) {
                self?.view.layoutIfNeeded()
            }
        }
    }
}
