//
//  VirtualAgentViewController.swift
//  ExposureNotificationApp
//
//

import Foundation
import UIKit
import WebKit

class VirtualAgentViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet var webview: WKWebView!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private var pageTitle: String = NSLocalizedString("VIRTUAL_AGENT_SCREEN_HEADER", comment: "Header")
    private var virtualAgentURL: URL = URL(string: SMLConfig.VirtualAgentURL)!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.title = pageTitle
    }
    
    override func viewDidLoad() {
        let request = URLRequest(url: virtualAgentURL)
        self.webview.load(request)
        self.webview.navigationDelegate = self
        setupNavigationBar(navigationItem: self.navigationItem, title: pageTitle)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var action: WKNavigationActionPolicy?

        defer {
            decisionHandler(action ?? .allow)
        }

        guard let url = navigationAction.request.url else { return }

        if navigationAction.navigationType == .linkActivated, url.absoluteString != SMLConfig.VirtualAgentURL{
            action = .cancel  // Stop in WebView
            UIApplication.shared.open(url)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code != NSURLErrorCancelled {
            webView.loadHTMLString("Page Not Found", baseURL: virtualAgentURL)
        }
    }
}
