//
//  WebViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/11/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var spinnerContainer: UIView!
    var baseUrl : String = ""
    var spinner : LLARingSpinnerView = LLARingSpinnerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.delegate = self;
        
        spinnerContainer.hidden = true
        spinner = LLARingSpinnerView.init(frame:CGRectMake(0.0, 0.0, 45.0, 45.0))
        spinner.lineWidth = 3.0
        spinner.tintColor = UIColor(red: 77/255, green:157/255 , blue: 183/255, alpha: 1.0)
        spinnerContainer.addSubview(spinner)
        
    }

    override func viewDidAppear(animated: Bool) {
        let url = NSURL(string: baseUrl)
        let requestObj = NSURLRequest(URL: url!)
        webView.loadRequest(requestObj)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: WebView Delegate
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        spinner.startAnimating()
        spinnerContainer.hidden = false

        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let javascriptFunction = "var script = document.createElement('script'); script.type = 'text/javascript'; script.text = \"%@\"; document.getElementsByTagName(\"header\")[0].style.display = \"none\"; document.getElementsByTagName(\"footer\")[0].style.display = \"none\";"
        
        webView.stringByEvaluatingJavaScriptFromString(javascriptFunction)
        self.fadeOutSpinnerView()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        self.fadeOutSpinnerView()
    }
    
    func fadeOutSpinnerView() {
        
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.spinnerContainer.layer.opacity = 0
            }, completion: nil);
        
        self.delay(0.35, closure: {
            self.spinner.stopAnimating()
            self.spinnerContainer.hidden = true
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

}
