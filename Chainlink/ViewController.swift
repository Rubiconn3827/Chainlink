//
//  ViewController.swift
//  Chainlink
//
//  Created by AJ Priola on 6/30/15.
//  Copyright © 2015 AJ Priola. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var messagesScrollView: UIScrollView!
    @IBOutlet weak var inputParentView: UIView!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameBarButton: UIBarButtonItem!
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var connectionsLevelView: UIView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var sendingProgressBar: UIProgressView!
    
    var connectionLevelLabel:UILabel!
    var imagePicker = UIImagePickerController()
    var connectionsLevelArray = [UIView]()
    var messageViewArray = [UIView]()
    var messageObjectArray = [MessageObject]()
    var username:String?
    var manager:SessionManager!
    var totalHeight = CGFloat(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.blueColor()]
        imagePicker.delegate = self
        self.sendButton.enabled = false
        connectionLevelLabel = UILabel(frame: self.connectionsLevelView.frame)
        connectionLevelLabel.textAlignment = NSTextAlignment.Center
        connectionLevelLabel.textColor = UIColor.blueColor()
        connectionLevelLabel.hidden = true
        connectionsLevelView.userInteractionEnabled = true
        let w = self.view.frame.width/7
        let h = CGFloat(5)
        for (var i = 0; i < 7; i++) {
            let v = UIView(frame: CGRectMake(w * CGFloat(i) + 4, 0, w, h))
            v.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.1)
            v.layer.borderColor = UIColor.whiteColor().CGColor
            v.layer.borderWidth = 0.5
            
            connectionsLevelView.addSubview(v)
            connectionsLevelArray.append(v)
        }
        nameBarButton.title = ""
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "scrollViewTapped")
        messagesScrollView.addGestureRecognizer(tapGestureRecognizer)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        let askAlert = UIAlertController(title: "Username", message: "Please enter a username for this session", preferredStyle: UIAlertControllerStyle.Alert)
        var inputTextField: UITextField?
        askAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            inputTextField = textField
        }
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            if inputTextField?.text != "" {
                self.username = inputTextField?.text
                self.manager = SessionManager(controller: self, id: self.username!)
                self.nameBarButton.title = "@" + self.username!
            } else {
                self.presentViewController(askAlert, animated: true, completion: nil)
            }
        }
        askAlert.addAction(okAction)
        self.presentViewController(askAlert, animated: true, completion: nil)
    }
    
    @IBAction func inputFieldChanged(sender: UITextField) {
        self.sendingProgressBar.setProgress(0, animated: false)
        if sender.text != "" {
            self.sendButton.enabled = true
        } else {
            self.sendButton.enabled = false
        }
    }
    
    func connectionLevelTapped() {
        connectionsLevelView.hidden = !connectionsLevelView.hidden
        if connectionLevelLabel.hidden {
            connectionLevelLabel.hidden = false
            for v in connectionsLevelArray {
                v.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.001)
            }
        } else {
            connectionLevelLabel.hidden = true
            updateCount(4)
        }
    }
    
    func updateCount(num:Int) {
        for (var i = 0; i < 7; i++) {
            if self.manager.session.connectedPeers.count > i {
                self.connectionsLevelArray[i].backgroundColor = UIColor.blueColor()
            }
        }
        /*
        for session in self.manager.sessions {
        if session.connectedPeers.count == 8 {
        self.connectionsLevelArray[c].backgroundColor = UIColor.blueColor()
        } else if session.connectedPeers.count > 0 {
        self.connectionsLevelArray[c].backgroundColor = UIColor.blueColor().colorWithAlphaComponent(CGFloat(session.connectedPeers.count/8))
        } else {
        self.connectionsLevelArray[c].backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.1)
        }
        c++
        }*/
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true) { () -> Void in
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            if image != nil {
                let view = self.getViewForPersonalImage(image!)
                self.messageViewArray.append(view)
                
                view.frame.origin = CGPointMake(view.frame.origin.x, self.totalHeight)
                self.totalHeight += view.frame.height + 4
                self.messagesScrollView.contentSize.height = self.totalHeight
                self.messagesScrollView.addSubview(view)
                
                let imageData = UIImageJPEGRepresentation(image!, 1)
                let messageToSend = MessageObject(withImageData: imageData!, from: self.username!)
                self.messageObjectArray.append(messageToSend)
                let data = NSKeyedArchiver.archivedDataWithRootObject(messageToSend)
                self.manager.sendData(data, type: "m")
                if self.totalHeight > self.messagesScrollView.frame.height {
                    let bottomOffset = CGPointMake(0, self.messagesScrollView.contentSize.height - self.messagesScrollView.bounds.size.height)
                    self.messagesScrollView.setContentOffset(bottomOffset, animated: true)
                }
            }
        }
    }
    
    func imageResize(imageObj:UIImage, sizeChange:CGSize)-> UIImage {
        
        let hasAlpha = false
        let scale: CGFloat = 0.0
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    @IBAction func pictureButtonTapped(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func pictureTapped(sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func sendButtonTapped(sender: UIButton) {
        sendingProgressBar.setProgress(1, animated: true)
        let message = self.inputTextField.text
        if message != "" {
            
            let view = getViewForPersonalMessage(message!)
            messageViewArray.append(view)
            view.frame.origin = CGPointMake(view.frame.origin.x, totalHeight)
            totalHeight += view.frame.height + 4
            messagesScrollView.contentSize.height = totalHeight
            
            self.messagesScrollView.addSubview(view)
            if totalHeight > self.messagesScrollView.frame.height {
                let bottomOffset = CGPointMake(0, self.messagesScrollView.contentSize.height - self.messagesScrollView.bounds.size.height + 5)
                messagesScrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
        let messageToSend = MessageObject(message: message!, from: username!)
        self.messageObjectArray.append(messageToSend)
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(messageToSend)
        self.manager.sendData(data, type: "m")
        self.inputTextField.text = ""
        self.view.endEditing(true)
        self.sendButton.enabled = false
    }
    
    func displayNewMessage(messageObject: MessageObject) {
        var view:UIView!
        if messageObject.message != nil {
            view = getViewForMessage(messageObject.message!, from: messageObject.from!)
        }
        if messageObject.image != nil {
            print("here")
            let img = UIImage(data: messageObject.image!)
            view = getViewForImage(img!, from: messageObject.from)
        }
        messageViewArray.append(view)
        view.frame.origin = CGPointMake(view.frame.origin.x, totalHeight)
        totalHeight += view.frame.height + 4
        self.messagesScrollView.contentSize.height = totalHeight + view.frame.height
        self.messagesScrollView.addSubview(view)
        if totalHeight > self.messagesScrollView.frame.height {
            let bottomOffset = CGPointMake(0, self.messagesScrollView.contentSize.height - self.messagesScrollView.bounds.size.height  + 5)
            messagesScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        if let userInfo = sender.userInfo {
            if let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
                inputViewBottomConstraint.constant = keyboardHeight
                scrollViewBottomConstraint.constant = keyboardHeight + 50
                UIView.animateWithDuration(0.15, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @IBAction func nameButtonTapped(sender: UIBarButtonItem) {
        let warningAlert = UIAlertController(title: "Warning", message: "Changing your username will reset your current connections. Are you sure you want to change your username?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let changeAction = UIAlertAction(title: "Change", style: UIAlertActionStyle.Destructive) { (action) -> Void in
            self.askForName()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            warningAlert.dismissViewControllerAnimated(true, completion: nil)
        }
        warningAlert.addAction(changeAction)
        warningAlert.addAction(cancelAction)
        self.presentViewController(warningAlert, animated: true, completion: nil)
    }
    
    func askForName() {
        let askAlert = UIAlertController(title: "Username", message: "Please enter a username for this session", preferredStyle: UIAlertControllerStyle.Alert)
        var inputTextField: UITextField?
        askAlert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            inputTextField = textField
        }
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            if inputTextField?.text != "" {
                self.username = inputTextField?.text
                self.manager.close()
                self.manager = SessionManager(controller: self, id: self.username!)
                for sub in self.messagesScrollView.subviews {
                    sub.removeFromSuperview()
                }
                self.totalHeight = 0
                self.messageViewArray.removeAll()
                self.messageObjectArray.removeAll()
                self.nameBarButton.title = "@" + self.username!
            } else {
                self.presentViewController(askAlert, animated: true, completion: nil)
            }
        }
        askAlert.addAction(okAction)
        self.presentViewController(askAlert, animated: true, completion: nil)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        inputViewBottomConstraint.constant = 0
        scrollViewBottomConstraint.constant = 50
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func scrollViewTapped() {
        self.view.endEditing(true)
    }
    
    func displaySystemMessage(message:String) {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        let time = formatter.stringFromDate(date)
        let label = UILabel(frame: CGRectMake(0, totalHeight, self.messagesScrollView.frame.width, 30))
        label.text = message + " [\(time)]"
        label.textColor = UIColor.lightGrayColor()
        label.textAlignment = NSTextAlignment.Center
        label.font = UIFont(name: "Helvetica", size: 14)
        self.messagesScrollView.addSubview(label)
        totalHeight += label.frame.height
    }
    
    func getViewForImage(image:UIImage, from:String) -> UIView {
        let resizedImage = imageResize(image, sizeChange: CGSize(width: self.view.frame.width * 0.5, height: self.view.frame.width * 0.5 * 1.61803398875))
        
        let imageView = UIImageView(image: resizedImage)
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        let view = UIView(frame: CGRectMake(8, 0, self.view.frame.size.width * 0.8, imageView.frame.size.height + 30))
        imageView.frame.origin = CGPointMake(0, 30)
        view.addSubview(imageView)
        
        let fromLabel = UILabel(frame: CGRectMake(0, 0, view.frame.width, 30))
        fromLabel.text = "@" + from + ":"
        fromLabel.textAlignment = NSTextAlignment.Left
        fromLabel.textColor = UIColor.blueColor()
        view.addSubview(fromLabel)
        return view
    }
    
    func getViewForPersonalImage(image:UIImage) -> UIView {
        let resizedImage = imageResize(image, sizeChange: CGSize(width: self.view.frame.width * 0.5, height: self.view.frame.width * 0.5 * 1.61803398875))
        
        let imageView = UIImageView(image: resizedImage)
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        let view = UIView(frame: CGRectMake(self.view.frame.width * 0.2 - 8, 0, self.view.frame.size.width * 0.8, imageView.frame.size.height + 30))
        imageView.frame.origin = CGPointMake(view.frame.width - imageView.frame.width, 30)
        view.addSubview(imageView)
        
        let fromLabel = UILabel(frame: CGRectMake(0, 0, view.frame.width, 30))
        fromLabel.text = "@Me:"
        fromLabel.textAlignment = NSTextAlignment.Right
        fromLabel.font = UIFont(name: "Helvetica Neue", size: 14)
        view.addSubview(fromLabel)
        return view
    }
    
    func getViewForPersonalMessage(message:String) -> UIView {
        let label = UILabel(frame: CGRectMake(0, 0, 100, 21))
        label.text = "@Me:"
        label.textAlignment = NSTextAlignment.Right
        label.font = UIFont(name: "Helvetica Neue", size: 15)
        label.sizeToFit()
        
        let text = UITextView(frame: CGRectMake(0, 21, self.view.frame.width * 0.5, 100))
        text.text = message
        text.textAlignment = NSTextAlignment.Right
        text.font = UIFont(name: "Helvetica Neue", size: 15)
        text.sizeToFit()
        text.backgroundColor = UIColor.groupTableViewBackgroundColor()
        text.layer.cornerRadius = 6
        
        let parentView = UIView(frame: CGRectMake(8, 0, max(label.frame.width, text.frame.width), label.frame.height + text.frame.height))
        parentView.frame.origin.y = self.totalHeight
        parentView.frame.origin.x = self.view.frame.width - 8 - parentView.frame.width
        label.frame.origin.x = parentView.frame.width - label.frame.width
        text.frame.origin.x = parentView.frame.width - text.frame.width
        parentView.addSubview(label)
        parentView.addSubview(text)
        return parentView
    }
    
    func getViewForMessage(message:String, from:String) -> UIView {
        let label = UILabel(frame: CGRectMake(0, 0, 100, 21))
        label.text = "@" + from
        label.textAlignment = NSTextAlignment.Right
        label.font = UIFont(name: "Helvetica Neue", size: 15)
        label.textColor = UIColor.blueColor()
        label.sizeToFit()
        
        let text = UITextView(frame: CGRectMake(0, 21, self.view.frame.width * 0.5, 100))
        text.text = message
        text.textAlignment = NSTextAlignment.Right
        text.font = UIFont(name: "Helvetica Neue", size: 15)
        text.sizeToFit()
        text.backgroundColor = UIColor.blueColor()
        text.textColor = UIColor.whiteColor()
        text.layer.cornerRadius = 6
        
        let parentView = UIView(frame: CGRectMake(8, 0, max(label.frame.width, text.frame.width), label.frame.height + text.frame.height))
        parentView.frame.origin.y = self.totalHeight
        parentView.addSubview(label)
        parentView.addSubview(text)
        return parentView
    }
    
    func resizeTextView(textView:UITextView) {
        textView.scrollEnabled = false
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat(MAXFLOAT)))
        var newFrame = textView.frame
        let fmf = fmaxf(Float(newSize.width), Float(fixedWidth))
        newFrame.size = CGSizeMake(CGFloat(fmf), newSize.height)
        textView.frame = newFrame
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}