//
//  NCRichdocument.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 06/09/18.
//  Copyright © 2018 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class NCRichdocument: NSObject, SwiftWebVCDelegate {
    
    @objc static let sharedInstance: NCRichdocument = {
        let instance = NCRichdocument()
        return instance
    }()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @objc func viewRichDocumentAt(_ link: String, navigationViewController: UINavigationController) {
        
        let webVC = SwiftWebVC(urlString: link, hideToolbar: true)
        webVC.delegate = self
        navigationViewController.setViewControllers([webVC], animated: false)
    }
    
    func didStartLoading() {
        print("Started loading.")
    }
    
    func didReceiveServerRedirectForProvisionalNavigation(url: URL) {
        
    }
    
    func didFinishLoading(success: Bool) {
        print("Finished loading. Success: \(success).")
    }
    
    func didFinishLoading(success: Bool, url: URL) {
        print("Finished loading. Success: \(success).")
    }
    
    func webDismiss() {
        print("Web dismiss.")
    }
    
    func decidePolicyForNavigationAction(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
}
