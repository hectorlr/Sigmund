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
    var userID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        personalityView.hidden = true
        activityIndicator.startAnimating()
        textField.hidden = true
        setUpTextField()
        
        let fbLoginButton = FBSDKLoginButton()
        fbLoginButton.center = view.center
        fbLoginButton.setTop(view.center.y + 40.0)
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["user_posts"]
        view.addSubview(fbLoginButton)
        
        doTheFacebookThing()
        
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
    
    func doTheFacebookThing(){
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            let request = FBSDKGraphRequest(graphPath: "me/", parameters: nil, HTTPMethod: "GET")
            request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                if let userDict = result as? NSDictionary{
                    self.userID = result["id"] as! String
                    self.getFeed()
                }
            }
            
        }
        
    }
    
    func getFeed(){
        let request = FBSDKGraphRequest(graphPath: "me/posts", parameters: nil, HTTPMethod: "GET")
        request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            
            var posts = result.valueForKey("data") as! [NSDictionary]
            println(posts.count)
            var messages = [String]()
            for post in posts {
                var id = self.getPostId(post)
                if id == self.userID && post["message"] != nil {
                    var message = post["message"] as! String
                    messages.append(message)
                    
                }
                var commentMessages = self.getAllComments(post)
                if !commentMessages.isEmpty{
                    messages += commentMessages
                }
            }
            self.getWatsonInsight(self.userID, strings: messages)
        }
    }
    
    func getAllComments(parent: AnyObject) -> [String]{
        if let comments = parent.valueForKey("comments") as? NSDictionary {
            var commentData = comments.valueForKey("data") as? [NSDictionary]
            if commentData == nil || commentData!.count == 0 {
                return []
            }else{
                var messages = [String]()
                for comment in commentData! {
                    
                    var id = self.getPostId(comment)
                    if id == self.userID {
                        messages.append(comment["message"] as! String)
                    }
                    messages += getAllComments(comment)
                }
                
                return messages
                
            }
        }else{
            return []
        }
        
    }
    
    func getPostId(post:NSDictionary) -> String{
        var from = post.objectForKey("from") as? NSDictionary
        var id = from?.objectForKey("id") as! String
        return id
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
                    
                    self.getWatsonInsight(username, strings: tweetTexts)
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
    
    func getWatsonInsight(username:String, strings: [String]){
        
        var contentItems : [[String : AnyObject]] = []
        
        for (index, string) in enumerate(strings) {
            let contentItem = [
                "id" : "MYIDoserigjesrgjes\(index)",
                "userid" : "username",
                "sourceid" : "twitter",
                "contenttype" :"text/html",
                "language" : "en",
                "content" : string]
            
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

extension ViewController: FBSDKLoginButtonDelegate {
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        println("User Logged In")
        let request = FBSDKGraphRequest(graphPath: "me/feed", parameters: nil, HTTPMethod: "GET")
        request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            self.doTheFacebookThing()
        }
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        println("User Logged Out")
    }
}

