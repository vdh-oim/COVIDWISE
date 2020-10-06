//
//  BrandViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import Foundation

class BrandViewController: UIViewController {
  
    init?(with coder: NSCoder) {
      super.init(coder: coder)
      self.hidesBottomBarWhenPushed = true
  }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpNavigationBar()
    }
    private func setUpNavigationBar() {
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "",
                                                                                              style: .plain,
                                                                                              target: nil,
                                                                                              action: nil)
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Medium", size: 20)!,
                                                                        NSAttributedString.Key.foregroundColor: UIColor.white]

    }
}
