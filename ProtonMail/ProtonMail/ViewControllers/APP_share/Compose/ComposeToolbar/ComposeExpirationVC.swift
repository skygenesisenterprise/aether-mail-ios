//
//  ComposeExpirationVC.swift
//  Proton Mail -
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreUIFoundations
import UIKit

protocol ComposeExpirationDelegate: AnyObject {
    func update(expiration: TimeInterval)
}

final class ComposeExpirationVC: UIViewController {
    private static let expirationTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.weekOfMonth, .day, .hour]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter
    }()

    enum ExpirationType: CaseIterable {
        case none
        case oneHour
        case oneDay
        case threeDays
        case oneWeek
        case custom

        var interval: TimeInterval {
            switch self {
            case .none:
                return 0
            case .oneHour:
                return 60 * 60
            case .oneDay:
                return 24 * 60 * 60
            case .threeDays:
                return 3 * 24 * 60 * 60
            case .oneWeek:
                return 7 * 24 * 60 * 60
            case .custom:
                return -1
            }
        }

        var title: String {
            var dateComponents = DateComponents()

            switch self {
            case .none:
                return LocalString._none
            case .oneHour:
                dateComponents.hour = 1
            case .oneDay:
                dateComponents.day = 1
            case .threeDays:
                dateComponents.day = 3
            case .oneWeek:
                dateComponents.weekOfMonth = 1
            case .custom:
                return LocalString._composer_expiration_custom
            }

            return ComposeExpirationVC.expirationTimeFormatter.string(from: dateComponents) ?? ""
        }
    }

    private var tableView: UITableView?
    private var timePicker: UIPickerView?
    private let rows = ExpirationType.allCases
    private var selectedType: ExpirationType = .none
    private let cellID = "ExpirationCell"
    private let cellHeight: CGFloat = 48
    private var expiration: TimeInterval = 0
    private var originalExpiration: TimeInterval = 0
    private weak var delegate: ComposeExpirationDelegate?

    convenience init(expiration: TimeInterval,
                     delegate: ComposeExpirationDelegate?) {
        self.init(nibName: nil, bundle: nil)
        self.expiration = expiration
        self.originalExpiration = expiration
        self.delegate = delegate
            self.isModalInPresentation = true
    }

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
}

extension ComposeExpirationVC {
    private func setup() {
        self.setupNavigation()
        self.setupTableView()

        self.selectedType = self.getSelectType()
        self.tableView?.reloadData()
        if self.selectedType == .custom {
            self.showTimePicker()
        }
    }

    private func setupNavigation() {
        self.title = LocalString._composer_expiration_title

        let setButton = UIBarButtonItem(title: LocalString._general_set,
                                        style: .plain,
                                        target: self,
                                        action: #selector(self.clickSetButton))

        let attr = FontManager
            .HeadlineSmall
            .foregroundColor(ColorProvider.InteractionNorm)
        setButton.setTitleTextAttributes(attr, for: .normal)
        self.navigationItem.rightBarButtonItem = setButton

        let backButtonItem = UIBarButtonItem.backBarButtonItem(target: self,
                                                               action: #selector(self.clickBackButton))
        self.navigationItem.leftBarButtonItem = backButtonItem
    }

    private func setupTableView() {
        let table = UITableView()
        self.view.addSubview(table)

        [
            table.topAnchor.constraint(equalTo: self.view.topAnchor),
            table.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            table.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            table.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ].activate()

        table.register(UITableViewCell.self, forCellReuseIdentifier: self.cellID)
        table.tableFooterView = UIView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        self.tableView = table
    }

    private func showTimePicker() {
        guard self.timePicker == nil else { return }

        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        let topConstraint = self.cellHeight * CGFloat(self.rows.count)
        self.view.addSubview(picker)
        [
            picker.topAnchor.constraint(equalTo: self.view.topAnchor, constant: topConstraint),
            picker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            picker.heightAnchor.constraint(equalToConstant: 223)
        ].activate()
        picker.reloadAllComponents()
        let selected = self.getPickerSelectedValue()
        picker.selectRow(selected.days, inComponent: 0, animated: false)
        picker.selectRow(selected.hours, inComponent: 1, animated: false)
        self.timePicker = picker
    }

    private func hideTimePicker() {
        self.timePicker?.removeFromSuperview()
        self.timePicker = nil
    }

    private func getPickerSelectedValue() -> (days: Int, hours: Int) {
        guard self.expiration > 0 else {
            return (days: 0, hours: 0)
        }
        let days = self.expiration / (24 * 60 * 60)
        var hours = self.expiration.truncatingRemainder(dividingBy: 24 * 60 * 60)
        hours /= (60 * 60)
        return (days: Int(days), hours: Int(hours))
    }

    private func getSelectType() -> ExpirationType {
        guard let type = self.rows.first(where: { $0.interval == self.expiration }) else {
            return .custom
        }
        return type
    }

    private func showDiscardAlert() {
        let title = LocalString._warning
        let message = LocalString._discard_warning
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let discardBtn = UIAlertAction(title: LocalString._general_discard, style: .destructive) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        let cancelBtn = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [discardBtn, cancelBtn].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    @objc
    private func clickSetButton() {
        self.expiration = max(0, self.expiration)
        self.delegate?.update(expiration: self.expiration)
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    private func clickBackButton() {
        guard self.expiration == self.originalExpiration else {
            self.showDiscardAlert()
            return
        }
        self.navigationController?.popViewController(animated: true)
    }
}

extension ComposeExpirationVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellID, for: indexPath)
        let item = self.rows[indexPath.row]
        cell.selectionStyle = .none
        cell.tintColor = ColorProvider.BrandNorm
        if self.selectedType == item {
            cell.textLabel?.set(text: item.title, preferredFont: .subheadline)
            let image = UIImageView(image: IconProvider.checkmark)
            cell.accessoryView = image
        } else {
            cell.textLabel?.set(text: item.title,
                                preferredFont: .subheadline,
                                textColor: ColorProvider.TextWeak)
            cell.accessoryView = nil
        }

        cell.addSeparator(padding: 0)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.rows[indexPath.row]
        self.expiration = item.interval
        self.selectedType = item
        self.tableView?.reloadData()

        if item == .custom {
            showTimePicker()
        } else {
            hideTimePicker()
        }
    }
}

extension ComposeExpirationVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? 29 : 24
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.set(text: nil, preferredFont: .subheadline)
            pickerLabel?.textAlignment = .center
        }
        var dateComponents = DateComponents()
        let keyPath: WritableKeyPath<DateComponents, Int?> = [\.day, \.hour][component]
        dateComponents[keyPath: keyPath] = row
        pickerLabel?.text = Self.expirationTimeFormatter.string(from: dateComponents)

        return pickerLabel ?? UILabel()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let days = Double(pickerView.selectedRow(inComponent: 0))
        let hours = Double(pickerView.selectedRow(inComponent: 1))
        self.expiration = days * 24 * 60 * 60 + hours * 60 * 60
    }
}
