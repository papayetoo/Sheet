//
//  ViewController.swift
//  Sheet
//
//  Created by 최광현 on 2022/05/13.
//

import UIKit

public protocol BackgroundSheetDelegate: AnyObject {
    func didShowBackgroundSheet()
    func didHideBackgroundSheet()
}

public protocol FrontSheetDelegate: AnyObject {
    func didShowEntireFrontSheet()
    func didHidePartialFrontSheet()
}

public extension Notification.Name {
    static var shouldEnablePannable: Notification.Name {
        return Notification.Name(rawValue: "shouldEnablePannable")
    }
}

public protocol Pannable {
    var panGestureRecognizer: UIPanGestureRecognizer {get}
    func bindEnablePannable()
}

public extension Pannable where Self: UIViewController {
    func bindEnablePannable() {
        NotificationCenter.default.addObserver(forName: .shouldEnablePannable, object: nil, queue: .main) {[weak self] in
            guard let shouldEnable = $0.object as? Bool else {
                return
            }
            self?.panGestureRecognizer.isEnabled = shouldEnable
        }
    }
}

public protocol PannableDelegate: AnyObject {
    func shouldEnablePannable(_ isEnable: Bool)
}

public extension PannableDelegate where Self: UIViewController {
    func shouldEnablePannable(_ isEnable: Bool) {
        NotificationCenter.default.post(name: .shouldEnablePannable, object: isEnable)
    }
}

public protocol PanHolderble {
    var panHolder: UIView { get }
    var panHolderIsHidden: Bool { get set }
}

public extension PanHolderble where Self: UIViewController {
    var panHolder: UIView {
        let holder = UIView()
        holder.layer.cornerRadius = 3
        holder.clipsToBounds = true
        holder.backgroundColor = .darkGray
        holder.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(holder)
        NSLayoutConstraint.activate([
            holder.widthAnchor.constraint(equalToConstant: 20),
            holder.heightAnchor.constraint(equalToConstant: 5),
            holder.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            holder.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4)
        ])
        return holder
    }
}


open class Sheet<BackgroundSheet: UIViewController, FrontSheet: UIViewController>: UIViewController, UIGestureRecognizerDelegate, Pannable {
    public struct SheetConfiguration {
        public enum PinPosition {
            case top
            case left
            case bottom
            case right
            
            public func oppositePosition() -> PinPosition {
                switch self {
                case .top:
                    return .bottom
                case .left:
                    return .right
                case .bottom:
                    return .top
                case .right:
                    return .left
                }
            }
        }
        var pinPosition: PinPosition
        var pinOppositePosition: PinPosition
        var originMargin: CGFloat
        var targetMargin: CGFloat
        
        public init(originMargin: CGFloat = 300, targetMargin: CGFloat = 0, pinPosition: PinPosition = .bottom) {
            self.originMargin = originMargin
            self.targetMargin = targetMargin
            self.pinPosition = pinPosition
            self.pinOppositePosition = pinPosition.oppositePosition()
        }
    }
    
    enum FrontSheetState {
        case initial
        case moved
    }
    
    private let backgroundSheet: BackgroundSheet
    
    private let frontSheet: FrontSheet
    
    private let sheetConfiguration: SheetConfiguration
    
    private var frontSheetState: FrontSheetState = .initial {
        willSet {
            switch newValue {
            case .initial:
                self.frontSheetDelegate?.didHidePartialFrontSheet()
            case .moved:
                self.frontSheetDelegate?.didShowEntireFrontSheet()
            }
        }
    }
    
    private var frontSheetConstraint: NSLayoutConstraint = NSLayoutConstraint() {
        willSet {
            self.frontSheetConstraint.isActive = false
        }
        didSet {
            self.frontSheetConstraint.isActive = true
        }
    }
    
    public weak var backgroundSheetDelegate: BackgroundSheetDelegate?
    
    public weak var frontSheetDelegate: FrontSheetDelegate?
    
    private var backgroundSheetView: UIView {
        get {
            self.backgroundSheet.view
        }
    }
    
    private var frontSheetView: UIView {
        get {
            self.frontSheet.view
        }
    }
    
    public var panGestureRecognizer: UIPanGestureRecognizer {
        get {
            return self._panGestureRecognizer
        }
    }
    
    private let _panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer()
    
    public init(_ backgroundSheet: BackgroundSheet,
                _ frontSheet: FrontSheet, positionConfiguration: SheetConfiguration) {
        self.backgroundSheet = backgroundSheet
        self.frontSheet = frontSheet
        self.sheetConfiguration = positionConfiguration
        super.init(nibName: nil, bundle: nil)
        self.backgroundSheetView.translatesAutoresizingMaskIntoConstraints = false
        self.frontSheetView.translatesAutoresizingMaskIntoConstraints = false
        self.setPanGestureReconizer()
        self.bindEnablePannable()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.setSheet()
        self.setInitialLayout()
    }
    
    private func setPanGestureReconizer() {
        self._panGestureRecognizer.delegate = self
        self._panGestureRecognizer.addTarget(self, action: #selector(handlePan))
        self.frontSheetView.addGestureRecognizer(self._panGestureRecognizer)
    }
    
    @objc
    private func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.frontSheetView)
        let velocity = sender.velocity(in: self.frontSheetView)
        let translationY = translation.y
        let yMag = translationY.magnitude
        
        switch sender.state {
        case .began, .changed:
            switch self.frontSheetState {
            case .initial:
                let newConstant = self.sheetConfiguration.originMargin + yMag
                guard translationY < 0 else {return}
                guard newConstant.magnitude > self.sheetConfiguration.originMargin else {
                    self.showBackgroundSheet(true)
                    return
                }
                self.frontSheetConstraint.constant = -newConstant
                self.view.layoutIfNeeded()
            case .moved:
                let newConstant = UIScreen.main.bounds.height - yMag
                guard translationY > 0 else {return}
                guard newConstant.magnitude < self.view.frame.height else {
                    self.hideBackgroundSheet(true)
                    return
                }
                self.frontSheetConstraint.constant = -newConstant
                self.view.layoutIfNeeded()
            }
        case .ended:
            switch self.frontSheetState {
            case .initial:
                translationY > 0 ? self.showBackgroundSheet(velocity.y.magnitude < 1000) : self.hideBackgroundSheet(velocity.y.magnitude < 1000)
            case .moved:
                translationY <= 0 ? self.hideBackgroundSheet(velocity.y.magnitude < 1000) : self.showBackgroundSheet(velocity.y.magnitude < 1000)
            }
        default:
            break
        }
    }
    
    private func setSheet() {
        self.addChild(self.backgroundSheet)
        self.addChild(self.frontSheet)
        
        self.view.addSubview(self.backgroundSheetView)
        self.view.addSubview(self.frontSheetView)
        self.setFrontSheetConstraint()
    }
    
    private func setInitialLayout() {
        NSLayoutConstraint.activate([
            self.backgroundSheetView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.backgroundSheetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.backgroundSheetView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.backgroundSheetView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            self.frontSheetConstraint,
            self.frontSheetView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.frontSheetView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.frontSheetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    public func showBackgroundSheet(_ animated: Bool) {
        //        self.frontSheetConstraint.isActive = false
        self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -self.sheetConfiguration.originMargin)
        //        self.frontSheetConstraint.isActive = true
        //        self.frontSheetConstraint.constant = -self.sheetConfiguration.originMargin
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.frontSheetState = .initial
            })
        } else {
            self.view.layoutIfNeeded()
            self.frontSheetState = .initial
        }
        self.panGestureRecognizer.isEnabled = true
        self.backgroundSheetDelegate?.didShowBackgroundSheet()
    }
    
    public func hideBackgroundSheet(_ animated: Bool) {
        //        self.frontSheetConstraint.constant = -(UIScreen.main.nativeBounds.height - self.sheetConfiguration.targetMargin)
        //        self.frontSheetConstraint.constant = -UIScreen.main.bounds.height + self.sheetConfiguration.targetMargin
        //        self.frontSheetConstraint.isActive = false
        self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        //        self.frontSheetConstraint.isActive = true
        //        self.frontSheetConstraint.constant = 0
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.frontSheetState = .moved
            })
        } else {
            self.view.layoutIfNeeded()
            self.frontSheetState = .moved
        }
        self.backgroundSheetDelegate?.didHideBackgroundSheet()
    }
    
    private func setFrontSheetConstraint() {
        //        switch self.sheetConfiguration.pinPosition {
        //        case .bottom:
        //            self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
        //                                                                                 constant: -self.sheetConfiguration.originMargin)
        //        default:
        //            break
        //        }
        switch self.sheetConfiguration.pinPosition {
        case .bottom:
            switch self.frontSheetState {
            case .initial:
                self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                                                                                     constant: -self.sheetConfiguration.originMargin)
            case .moved:
                self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
            }
        default:
            break
        }
        //        switch self.frontSheetState {
        //        case .initial:
        //            self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
        //                                                                                 constant: -self.sheetConfiguration.originMargin)
        //        case .moved:
        //            self.frontSheetConstraint = self.frontSheetView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
        //        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
