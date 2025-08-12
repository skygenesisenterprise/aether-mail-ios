//
//  HorizontallyScrollableWebViewContainer.swift
//  Proton Mail - Created on 01/05/2019.
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
import TrustKit
import ProtonCoreServices
import WebKit

class HorizontallyScrollableWebViewContainer: UIViewController {
    internal var webView: PMWebView!

    private var height: NSLayoutConstraint!
    private var lastContentOffset: CGPoint = .zero
    private var lastZoom: CGAffineTransform = .identity
    private var initialZoom: CGAffineTransform = .identity
    private var contentSizeObservation: NSKeyValueObservation! // used to update content size after loading images
    private var loadingObservation: NSKeyValueObservation!

    internal weak var enclosingScroller: ScrollableContainer?
    private var enclosingScrollerObservation: NSKeyValueObservation!
    private var verticalRecognizer: UIPanGestureRecognizer!
    private var gestureInitialOffset: CGPoint = .zero

    private lazy var animator = UIDynamicAnimator(referenceView: self.enclosingScroller!.scroller)
    private var pushBehavior: UIPushBehavior!
    private var frictionBehaviour: UIDynamicItemBehavior!
    private var scrollDecelerationOverlay: ViewBlowingAfterTouch!
    private var scrollDecelerationOverlayObservation: NSKeyValueObservation!

    deinit {
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.scrollDecelerationOverlayObservation = nil
         self.enclosingScrollerObservation = nil

        if let webView = self.webView {
            webView.scrollView.delegate = nil
            webView.uiDelegate = nil
            webView.navigationDelegate = nil
        }
    }

    func prepareWebView(
        with loader: HTTPRequestSecureLoader? = nil,
        urlHandler: WKURLSchemeHandler? = nil,
        urlSchemesToBeHandled: Set<String> = []
    ) {
        let config = WKWebViewConfiguration()
        urlSchemesToBeHandled.forEach { scheme in
            config.setURLSchemeHandler(urlHandler, forURLScheme: scheme)
        }
        loader?.inject(into: config)
        config.dataDetectorTypes = [.phoneNumber, .link]

        // oh, WKWebView is available in IB since iOS 11 only
        self.webView = PMWebView(frame: .zero, configuration: config)
        #if DEBUG
        if #available(iOS 16.4, *) {
            self.webView?.isInspectable = true
        }
        #endif
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        self.webView.scrollView.bounces = false // otherwise 1px margin will make contents horizontally scrollable
        self.webView.scrollView.bouncesZoom = false
        self.webView.scrollView.isDirectionalLockEnabled = false
        self.webView.scrollView.showsVerticalScrollIndicator = false
        self.webView.scrollView.showsHorizontalScrollIndicator = true
        self.view.addSubview(self.webView)
        webView.fillSuperview()

        self.verticalRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
            self.verticalRecognizer.allowedScrollTypesMask = .all
        self.verticalRecognizer.delegate = self
        self.verticalRecognizer.maximumNumberOfTouches = 1
        self.webView.scrollView.addGestureRecognizer(verticalRecognizer)

        self.webView.scrollView.isScrollEnabled = true
        self.verticalRecognizer.isEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.height = self.view.heightAnchor.constraint(equalToConstant: 0.1)
        self.height.priority = .init(999.0) // for correct UITableViewCell autosizing
        self.height.isActive = true
    }

    @objc func pan(sender gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.animator.removeAllBehaviors()
            self.gestureInitialOffset = .zero
            self.stopInertia()

        case .ended:
            let magic: CGFloat = 100 // this constant makes inertia feel right, something about the mass of UIKit objects
            guard let parent = self.enclosingScroller?.scroller else { return }
            self.scrollDecelerationOverlay = ViewBlowingAfterTouch(frame: .init(origin: .zero, size: parent.contentSize))
            parent.addSubview(self.scrollDecelerationOverlay)

            self.pushBehavior = UIPushBehavior(items: [self.scrollDecelerationOverlay], mode: .instantaneous)
            self.pushBehavior.pushDirection = CGVector(dx: 0, dy: -1)
            self.pushBehavior.magnitude = gesture.velocity(in: self.webView).y / magic
            self.animator.addBehavior(self.pushBehavior)

            self.frictionBehaviour = UIDynamicItemBehavior(items: [self.scrollDecelerationOverlay])
            self.frictionBehaviour.resistance = self.webView.scrollView.decelerationRate.rawValue
            self.frictionBehaviour.friction = 1.0
            self.frictionBehaviour.density = (magic * magic) / (self.scrollDecelerationOverlay.frame.size.height * self.scrollDecelerationOverlay.frame.size.width)
            self.animator.addBehavior(self.frictionBehaviour)

            self.scrollDecelerationOverlayObservation = self.scrollDecelerationOverlay.observe(\ViewBlowingAfterTouch.center, options: [.old, .new]) { [weak self] pixel, change in
                guard let _ = pixel.superview else { return }
                guard let new = change.newValue, let old = change.oldValue else { return }
                self?.enclosingScroller?.propagate(scrolling: .init(x: new.x - old.x, y: new.y - old.y),
                                                   boundsTouchedHandler: pixel.removeFromSuperview)
            }

        default:
            let translation = gesture.translation(in: self.webView)
            self.enclosingScroller?.propagate(scrolling: CGPoint(x: 0, y: self.gestureInitialOffset.y - translation.y),
                                              boundsTouchedHandler: { /* nothing */ })
            self.gestureInitialOffset = translation
        }
    }

    internal func stopInertia() {
        self.scrollDecelerationOverlayObservation = nil
        self.scrollDecelerationOverlay?.blow()
    }

    internal func updateHeight(to newHeight: CGFloat) {
        self.height.constant = newHeight
    }

    /// Switch off to disable observations of self.webView.scrollView.contentSize and webView.estimatedProgress
    func shouldDefaultObserveContentSizeChanges() -> Bool {
        return true
    }
}

extension HorizontallyScrollableWebViewContainer: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // this will prevent our gesture recognizer from blocking webView's built-in gesture resognizers
        return self.webView.scrollView.gestureRecognizers?.filter { !($0 is UITapGestureRecognizer) }.contains(otherGestureRecognizer) ?? false
    }
}

extension HorizontallyScrollableWebViewContainer: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.initialZoom = webView.scrollView.subviews.first?.transform ?? .identity
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let validator = PMAPIService.trustKit?.pinningValidator {
            if !validator.handle(challenge, completionHandler: completionHandler) {
                completionHandler(.performDefaultHandling, challenge.proposedCredential)
            }
        } else {
            assert(false, "TrustKit was not correctly initialized")
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.contentSizeObservation = self.webView.scrollView.observe(\.contentSize, options: [.initial, .new, .old]) { [weak self] scrollView, change in
            guard self?.shouldDefaultObserveContentSizeChanges() == true else { return }
            // as of iOS 13 beta 2, contentSize increases by 1pt after every updateHeight causing infinite loop. This 10pt treshold will prevent looping
            guard let new = change.newValue?.height, let old = change.oldValue?.height, new - old > 10.0 else { return }
            self?.updateHeight(to: scrollView.contentSize.height)
        }

        self.loadingObservation = self.loadingObservation ?? self.webView.observe(\.isLoading) { [weak self] webView, change in
            guard self?.shouldDefaultObserveContentSizeChanges() == true else { return }
            guard webView.estimatedProgress > 0.1 else { return } // skip first call because it will inherit irrelevant contentSize
            self?.updateHeight(to: webView.scrollView.contentSize.height)
        }

        decisionHandler(.allow)
    }
}

extension HorizontallyScrollableWebViewContainer: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.contentSizeObservation = nil
        self.loadingObservation = nil
        self.lastZoom = view?.transform ?? .identity
        self.lastContentOffset = .zero
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard self.shouldDefaultObserveContentSizeChanges() == true else { return } // cuz there is no zoom in Composer

        var newSize = scrollView.contentSize
        newSize = newSize.applying(self.lastZoom.inverted()).applying(self.initialZoom)

        let united = CGPoint(x: 0, y: self.lastContentOffset.y + self.enclosingScroller!.scroller.contentOffset.y)
        self.enclosingScroller?.propagate(scrolling: self.lastContentOffset, boundsTouchedHandler: {
            // sometimes offset after zoom can exceed tableView's heigth (usually when pinch center is close to the bottom of the cell and cell after zoom should be much bigger than before)
            // here we're saying the tableView which contentOffset we'd like to have after it will increase cell and animate changes. That will cause a little glitch tho :(
            self.enclosingScroller?.scroller.contentOffset = united
            self.enclosingScroller?.saveOffset()
        })

        self.updateHeight(to: newSize.height)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !scrollView.isZooming {
            scrollView.contentOffset = .init(x: scrollView.contentOffset.x, y: 0)
        }
    }
}

/// This UIView removes itself from superview after first touch
private class ViewBlowingAfterTouch: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        if target == self {
            self.blow()
            return nil
        }
        return target
    }

    func blow() {
        DispatchQueue.main.async {
            self.removeFromSuperview()
        }
    }
}
