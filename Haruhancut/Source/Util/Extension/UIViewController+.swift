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

extension ViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
           selector: #selector(keyboardWillShow),
           name: UIResponder.keyboardWillShowNotification,
           object: nil)
        NotificationCenter.default.addObserver(self,
           selector: #selector(keyboardWillHide),
           name: UIResponder.keyboardWillHideNotification,
           object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        // 버튼이 키보드에 가려질 정도일 경우만 올리기
        let bottomInset = keyboardFrame.height - view.safeAreaInsets.bottom
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -bottomInset + 10)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.view.transform = .identity
        }
    }
}
