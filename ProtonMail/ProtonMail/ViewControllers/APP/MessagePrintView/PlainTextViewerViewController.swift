//
//  PlainTextViewerViewController.swift
//  Proton Mail - Created on 5/7/21.
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

class PlainTextViewerViewController: UIViewController {
    enum ViewerSubType {
        case headers
        case html
        case cypher

        var title: String {
            switch self {
            case .headers:
                return LocalString._message_headers
            case .html:
                return LocalString._message_html
            case .cypher:
                return LocalString._message_body
            }
        }
    }
    private let text: String
    private let subType: ViewerSubType
    private let textView = UITextView()
    private let dropShadowView = UIView()

    init(text: String, subType: ViewerSubType) {
        self.text = text
        self.subType = subType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, please use init(text:) instead")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        navigationItem.title = subType.title
        dropShadowView.backgroundColor = ColorProvider.IconWeak.withAlphaComponent(0.2)
        buildLayout()
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.attributedText = text.apply(style: FontManager.Default)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: IconProvider.arrowUpFromSquare, style: .plain, target: self, action: #selector(share))
        textView.textContainerInset = .init(top: 44, left: 0, bottom: 0, right: 0)
    }

    private func buildLayout() {
        view.addSubview(textView)
        view.addSubview(dropShadowView)
        [
            dropShadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dropShadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropShadowView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dropShadowView.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
        [
            textView.topAnchor.constraint(equalTo: dropShadowView.bottomAnchor, constant: 0),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ].activate()
    }

    @objc private func share() {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true, completion: nil)
    }
}
