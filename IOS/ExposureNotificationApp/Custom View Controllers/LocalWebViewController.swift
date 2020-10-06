//
//  LocalWebViewController.swift
//  ExposureNotificationApp
//
//

import UIKit
import WebKit
import Foundation

struct WebViewModel {
    var title: String?
    var urlString: String
    
    var url: URL? {
        return URL(string: urlString)
    }
}

class LocalWebViewController: BrandViewController,WKNavigationDelegate, WKUIDelegate {
    
    private var webModel: WebViewModel!
    @IBOutlet var webview: WKWebView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
       
    init?(with webModel: WebViewModel, coder: NSCoder) {
        super.init(with: coder)
        self.webModel = webModel
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webview.uiDelegate = self
        self.webview.navigationDelegate = self
        self.title = webModel.title
        if let url = webModel.url {
            let request = URLRequest(url: url)
            self.webview.load(request)
        }
    }
    //MARK: WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
}
