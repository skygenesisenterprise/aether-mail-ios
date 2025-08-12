// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCoreUIFoundations
import UIKit

protocol PMDatePickerDelegate: AnyObject {
    func save(date: Date)
    func cancel()
    func datePickerWillAppear()
    func datePickerWillDisappear()
    func datePickerDidDisappear()
    func showSendInTheFutureAlert()
}

extension PMDatePickerDelegate {
    func datePickerWillAppear() {}
    func datePickerWillDisappear() {}
    func datePickerDidDisappear() {}
}

extension PMDatePicker {
    enum PickerType {
        case scheduleSend, snooze
    }
}

final class PMDatePicker: UIView {
    private var backgroundView: UIView
    private var container: UIView!
    private var containerBottom: NSLayoutConstraint!
    private let pickerScrollView = UIScrollView(frame: .zero)
    private var datePicker: UIDatePicker
    private let hiddenConstant: CGFloat = 450
    private let cancelTitle: String
    private let saveTitle: String
    private let pickerType: PickerType
    private weak var delegate: PMDatePickerDelegate?

    init(
        delegate: PMDatePickerDelegate,
        cancelTitle: String,
        saveTitle: String,
        pickerType: PickerType = .scheduleSend
    ) {
        self.delegate = delegate
        self.backgroundView = UIView(frame: .zero)
        self.datePicker = UIDatePicker(frame: .zero)
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        self.pickerType = pickerType
        super.init(frame: .zero)
        self.setUpView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(on parentView: UIView) {
        parentView.addSubview(self)
        self.fillSuperview()
        parentView.layoutIfNeeded()

        self.delegate?.datePickerWillAppear()
        self.containerBottom.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        if #unavailable(iOS 15) {
            NotificationCenter.default.addKeyboardObserver(self)
        }
    }
}

// MARK: Actions
extension PMDatePicker {
    @objc
    private func clickSaveButton() {
        guard Date(timeInterval: Constants.ScheduleSend.minNumberOfSeconds, since: Date()) < self.datePicker.date else {
            delegate?.showSendInTheFutureAlert()
            return
        }
        self.delegate?.save(date: self.datePicker.date)
        self.dismiss(isCancelled: false)
    }

    @objc
    private func clickCancelButton() {
        self.dismiss(isCancelled: true)
    }

    private func dismiss(isCancelled: Bool) {
        if isCancelled {
            self.delegate?.cancel()
        }
        self.delegate?.datePickerWillDisappear()
        self.containerBottom.constant = hiddenConstant
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.removeFromSuperview()
                self.delegate?.datePickerDidDisappear()
            }
        )
    }
}

// MARK: View set up
extension PMDatePicker {
    private func setUpView() {
        self.setUpBackgroundView()
        let container = self.setUpContainer()
        let toolBar = self.setUpToolBar(in: container)
        setUpPickerScrollView(toolBar: toolBar)
        setUpDatePicker(in: pickerScrollView)
    }

    private func setUpBackgroundView() {
        self.backgroundView.backgroundColor = ColorProvider.BlenderNorm
        self.addSubview(self.backgroundView)
        self.backgroundView.fillSuperview()
    }

    private func setUpContainer() -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = ColorProvider.BackgroundNorm
        self.addSubview(container)

        [
            container.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            container.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ].activate()
        self.containerBottom = container.bottomAnchor.constraint(
            equalTo: self.bottomAnchor,
            constant: hiddenConstant
        )
        self.containerBottom.isActive = true
        self.container = container
        return container
    }

    private func setUpToolBar(in container: UIView) -> UIToolbar {
        let screenWidth = UIScreen.main.bounds.width
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))

        let saveItem = UIBarButtonItem(title: self.saveTitle,
                                       style: .plain,
                                       target: self,
                                       action: #selector(self.clickSaveButton))
        saveItem.tintColor = ColorProvider.InteractionNorm
        let cancelItem = UIBarButtonItem(title: self.cancelTitle,
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.clickCancelButton))
        cancelItem.tintColor = ColorProvider.InteractionNorm
        let flexItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelItem, flexItem, saveItem], animated: false)

        container.addSubview(toolBar)
        [
            toolBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolBar.topAnchor.constraint(equalTo: container.topAnchor),
            toolBar.heightAnchor.constraint(equalToConstant: 44)
        ].activate()
        toolBar.setContentCompressionResistancePriority(.required, for: .vertical)
        return toolBar
    }

    private func setUpPickerScrollView(toolBar: UIToolbar) {
        container.addSubview(pickerScrollView)
        [
            pickerScrollView.topAnchor.constraint(equalTo: toolBar.bottomAnchor),
            pickerScrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pickerScrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pickerScrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            pickerScrollView.widthAnchor.constraint(equalTo: container.widthAnchor),
            pickerScrollView.heightAnchor.constraint(lessThanOrEqualTo: container.heightAnchor, constant: -44)
        ].activate()
    }

    private func setUpDatePicker(in container: UIScrollView) {
        self.delegate?.datePickerWillAppear()
        self.datePicker.datePickerMode = .dateAndTime

        let minMinutes = pickerType == .scheduleSend ?
        Constants.ScheduleSend.minNumberOfMinutes : Constants.Snooze.minNumberOfMinutes
        self.datePicker.minuteInterval = minMinutes

        let baseDate = PMDatePicker.referenceDate(pickerType: pickerType)

        if pickerType == .scheduleSend {
            let minimumDate = Date(timeInterval: Constants.ScheduleSend.minNumberOfSeconds, since: baseDate)
            self.datePicker.date = minimumDate
            self.datePicker.minimumDate = minimumDate
        } else {
            datePicker.date = baseDate
            datePicker.minimumDate = baseDate
        }

        let maxDate: TimeInterval
        if pickerType == .scheduleSend {
            maxDate = Constants.ScheduleSend.maxNumberOfSeconds
        } else {
            maxDate = Constants.Snooze.maxNumberOfSeconds
        }
        self.datePicker.maximumDate = Date(timeInterval: maxDate, since: Date())

        self.datePicker.tintColor = ColorProvider.BrandNorm
        datePicker.addTarget(self, action: #selector(self.pickerDateIsChanged), for: .valueChanged)

        self.datePicker.preferredDatePickerStyle = .inline

        container.addSubview(self.datePicker)
        [
            datePicker.leadingAnchor.constraint(equalTo: container.contentLayoutGuide.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: container.contentLayoutGuide.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: container.contentLayoutGuide.bottomAnchor),
            datePicker.topAnchor.constraint(equalTo: container.contentLayoutGuide.topAnchor),
            datePicker.widthAnchor.constraint(equalTo: container.widthAnchor),
            container.heightAnchor.constraint(equalTo: datePicker.heightAnchor).setPriority(as: .defaultLow)
        ].activate()
    }

    static func referenceDate(from date: Date = Date(), pickerType: PickerType) -> Date {
        let minNumberOfSeconds = pickerType == .scheduleSend ?
        Constants.ScheduleSend.minNumberOfSeconds : Constants.Snooze.minNumberOfSeconds
        let seconds = (date.timeIntervalSince1970 / minNumberOfSeconds).rounded(.up) * minNumberOfSeconds
        let date = Date(timeIntervalSince1970: seconds)
        return date
    }

    @objc
    func pickerDateIsChanged() {
        // Let's say you only change day and not touch hour time
        // if the new date is over maximumDate
        // datePicker.date will update by itself to fit maximumDate, that is great
        // but the UI won't update...
        // this function is to update the confused UI
        var date = datePicker.date
        if date == datePicker.maximumDate && date.minute % 5 == 0 {
            // If the minute is multiple of 5, needs to minus 1 to show correct UI
            date = date.add(.minute, value: -1) ?? date
        }
        datePicker.setDate(date, animated: false)
    }
}

extension PMDatePicker: NSNotificationCenterKeyboardObserverProtocol {
    @objc
    func keyboardWillHideNotification(_ notification: Notification) {
        containerBottom.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    @objc
    func keyboardWillShowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardInfo = userInfo["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
            return
        }
        containerBottom.constant = -(keyboardInfo.height - 57)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
