//
//  UITableView+Extension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

extension UITableView {

    struct Constant {
        static let animationDuration: TimeInterval = 1
    }

    func hideLoadingFooter(replaceWithView view: UIView? = UIView(frame: CGRect.zero)) {
        UIView.animate(
            withDuration: Constant.animationDuration,
            animations: {
                self.tableFooterView?.alpha = 0
            }, completion: { _ in
                UIView.animate(withDuration: Constant.animationDuration, animations: {
                    self.tableFooterView = view
                })
            }
        )
    }

    func noSeparatorsAboveFirstCell() {
        tableHeaderView = UIView()
    }

    func noSeparatorsBelowFooter() {
        tableFooterView = UIView(frame: CGRect.zero)
    }

    func showLoadingFooter() {
        tableFooterView = makeLoadingFooterView()
    }

    func makeLoadingFooterView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 72))
        let loadingActivityView = UIActivityIndicatorView(style: .medium)
        loadingActivityView.color = ColorProvider.BrandNorm
        view.addSubview(loadingActivityView)

        [
            loadingActivityView.heightAnchor.constraint(equalToConstant: 32),
            loadingActivityView.widthAnchor.constraint(equalToConstant: 32),
            loadingActivityView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            loadingActivityView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            loadingActivityView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ].activate()
        loadingActivityView.startAnimating()
        return view
    }

    /**
     reset table view inset and margins to .zero
     **/
    func zeroMargin() {
        if self.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            self.separatorInset = .zero
        }

        if self.responds(to: #selector(setter: UIView.layoutMargins)) {
            self.layoutMargins = .zero
        }
    }

    func indexPathExists(_ indexPath: IndexPath) -> Bool {
        if indexPath.section >= self.numberOfSections {
            return false
        }
        if indexPath.row >= self.numberOfRows(inSection: indexPath.section) {
            return false
        }
        return true
    }
}

extension UITableView {

    func registerCell(_ cellID: String) {
        self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }

    func dequeue<T: UITableViewCell>(cellType: T.Type) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: cellType.reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with reuse identifier: \(cellType.reuseIdentifier)")
        }

        return cell
    }

    func register<T: UITableViewCell>(cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

}
