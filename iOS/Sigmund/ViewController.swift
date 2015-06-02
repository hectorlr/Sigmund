//
//  ViewController.swift
//  Sigmund
//
//  Created by Hector Rodriguez on 5/19/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit
import TwitterKit
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet weak var personalityLabel: UILabel!
    @IBOutlet weak var personalityView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        personalityView.hidden = true
        activityIndicator.startAnimating()
        textField.hidden = true
        setUpTextField()
        
        Twitter.sharedInstance().logInGuestWithCompletion { (session: TWTRGuestSession!, error: NSError!) -> Void in
            self.activityIndicator.stopAnimating()
            self.textField.hidden = false
            self.textField.becomeFirstResponder()
        }
        
        if Twitter.sharedInstance().session() != nil {
            self.textField.hidden = false
            self.textField.becomeFirstResponder()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func setUpTextField() {
        
        let textFieldAttributes : Dictionary = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        let textFieldPlaceholderAttributedString = NSAttributedString(string: self.textField.placeholder!, attributes: textFieldAttributes)
        self.textField.attributedPlaceholder = textFieldPlaceholderAttributedString
        
        let paddingView = UIView(frame: CGRectMake(0, 0, 5, self.textField.frame.height))
        self.textField.leftView = paddingView
        self.textField.leftViewMode = UITextFieldViewMode.Always
        
    }
    
    func parseTwitter(username: String!) {
        let searchTweetsEndpoint = "https://api.twitter.com/1.1/statuses/user_timeline.json"
        let params = ["screen_name" : username, "exclude_replies" : "false", "trim_user" : "true", "include_rts": "false", "count" : "200"]
        var clientError : NSError?
        
        let request = Twitter.sharedInstance().APIClient.URLRequestWithMethod("GET", URL: searchTweetsEndpoint, parameters: params, error: &clientError)
        
        if request != nil {
            Twitter.sharedInstance().APIClient.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if (connectionError == nil) {
                    var jsonError : NSError?
                    let json : AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError)
                    
                    var tweetTexts: [String] = []
                    
                    for object in json as! [[NSObject : AnyObject]!] {
                        let tweet = TWTRTweet(JSONDictionary: object)
                        
                        var tweetText = tweet.text as String!
                        
                        let linkDetector = NSDataDetector(types: NSTextCheckingType.Link.rawValue, error: nil)
                        
                        let matches = linkDetector?.matchesInString(tweetText, options: NSMatchingOptions.allZeros, range: NSMakeRange(0, count(tweetText)))
                        if matches!.count > 0 {
                            for match in matches as! [NSTextCheckingResult] {
                                if match.resultType == NSTextCheckingType.Link {
                                    let urlString = "\(match.URL!)"
                                    
                                    tweetText = tweetText.stringByReplacingOccurrencesOfString(urlString, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                                }
                            }
                            
                            tweetTexts.append(tweetText)
                        }else{
                            tweetTexts.append(tweetText)
                        }
                    }
                    
                    self.getWatsonInsight(username, tweets: tweetTexts)
                }
                else {
                    println("Error: \(connectionError)")
                }
            }
        }
        else {
            println("Error: \(clientError)")
        }
    }
    
    func getWatsonInsight(username:String, tweets: [String]){
        
        var contentItems : [[String : AnyObject]] = []
        
        for (index, tweet) in enumerate(tweets) {
            let contentItem = [
                "id" : "MYIDoserigjesrgjes\(index)",
                "userid" : "username",
                "sourceid" : "twitter",
                "contenttype" :"text/html",
                "language" : "en",
                "content" : tweet]
            
            contentItems.append(contentItem)
        }
        let jsonPayload = ["contentItems" : contentItems]
        
        
        Alamofire.request(Method.POST, "http://sigmund-insights.mybluemix.net/", parameters: jsonPayload, encoding: ParameterEncoding.JSON).responseJSON(options: NSJSONReadingOptions.allZeros) { (request:NSURLRequest, response:NSHTTPURLResponse?, json, error: NSError?) -> Void in
            println(json!)
            let jsonResponse = json as! [String : AnyObject]
            if jsonResponse["response"] != nil {
                let summaryString = jsonResponse["response"] as? String
                self.personalityLabel.text = "@\(username)\n\n\(summaryString!)"
                self.activityIndicator.stopAnimating()
                self.personalityView.hidden = false
            }
            
        }
        
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool{
        
        self.personalityView.hidden = true
        let username = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        self.parseTwitter(username)
        
        textField.text = ""
        self.activityIndicator.startAnimating()
        textField.resignFirstResponder()
        return true
    }
}

