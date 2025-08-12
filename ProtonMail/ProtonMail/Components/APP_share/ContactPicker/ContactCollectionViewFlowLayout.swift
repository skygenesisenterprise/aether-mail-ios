//
//  ContactCollectionViewFlowLayout.swift
//  Proton Mail - Created on 4/27/18.
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

import UIKit

protocol ContactCollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView?, willChangeContentSizeTo newSize: CGSize)
}

class ContactCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)

        guard let collectionView = self.collectionView else {
            return nil
        }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            // Change new line
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            layoutAttribute.frame.origin.x = leftMargin

            // Update the width of entry cell
            if layoutAttribute.indexPath.row == collectionView.numberOfItems(inSection: 0) - 1 {
                let newWidth = collectionView.frame.width - sectionInset.left - sectionInset.right
                layoutAttribute.frame.size.width = max(max(50, newWidth.rounded(.up)),
                                                       collectionView.frame.width)
            }

            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY, maxY)

            if layoutAttribute.size.width < 0 || layoutAttribute.size.height < 0 {
                PMAssertionFailure("layoutAttributesForElements - invalid size: \(layoutAttribute.size)")
                layoutAttribute.size.width = max(layoutAttribute.size.width, 0)
                layoutAttribute.size.height = max(layoutAttribute.size.height, 0)
            }
        }

        return attributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func finalizeCollectionViewUpdates() {
        defer {
            super.finalizeCollectionViewUpdates()
        }

        guard collectionViewContentSize.width >= 0, collectionViewContentSize.height >= 0 else {
            PMAssertionFailure("Flow layout - invalid size: \(collectionViewContentSize)")
            return
        }

        if let delegate = self.collectionView?.delegate as? ContactCollectionViewDelegateFlowLayout {
            delegate.collectionView(collectionView: collectionView, willChangeContentSizeTo: collectionViewContentSize)
        }
    }
}
