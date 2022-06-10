//
//  BackgroundSheetViewController.swift
//  SheetExample
//
//  Created by 최광현 on 2022/05/13.
//

import UIKit
import Sheet

class BackgroundSheetViewController: UIViewController {
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.view.addSubview(self.backgroundImageView)
        self.loadImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NSLayoutConstraint.activate([
            self.backgroundImageView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.backgroundImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.backgroundImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.backgroundImageView.bottomAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    private func loadImage() {
        guard let url = URL(string: "https://w.namu.la/s/a60874eddb91d70cb5d03f3d8236520d993035a7465207df6afa6709084a992ecf2acb204bdd01bf5b32b634410f33bf9cacd2d1000291925df391b040c01642831d417e11c6e0df7ddf3810502edc82470c8d787d8d7bb528dfa6be1f9e9303")
        else {
            return
        }
        URLSession.shared.dataTask(with: url, completionHandler: { dataOrNil, responseOrNil, errorOrNil in
            guard errorOrNil == nil else {
                return
            }
            
            guard let response = responseOrNil as? HTTPURLResponse else {
                return
            }
            
            guard let data = dataOrNil else {
                return
            }
            DispatchQueue.main.async { [unowned self] in
                self.backgroundImageView.image = UIImage(data: data)
            }
        }).resume()
    }
}

extension BackgroundSheetViewController: BackgroundSheetDelegate {
    func didShowBackgroundSheet() {
        self.navigationController?.setNavigationBarTransparent()
    }
    
    func didHideBackgroundSheet() {
        self.navigationController?.setNavigationBarBackground(.white)
    }
    
    
}

extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UINavigationController {
    @discardableResult
    func setNavigationBarBackground(_ color: UIColor) -> UINavigationController {
        if #available(iOS 13.0, *) {
            self.navigationBar.standardAppearance.backgroundColor = color
            self.navigationBar.scrollEdgeAppearance?.backgroundColor = color
        } else {
            self.navigationBar
                .setBackgroundImage(UIImage.imageWithColor(color: color), for: .default)
        }
        self.navigationBar.isTranslucent = false
        return self
    }
    
    @discardableResult
    func setNavigationBarTransparent() -> UINavigationController {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationBar.backgroundColor = .clear
            self.navigationBar
                .setBackgroundImage(UIImage.imageWithColor(color: .clear), for: .default)
        }
        self.navigationBar.isTranslucent = true
        self.navigationBar.topItem?.title = nil
        return self
    }
}
