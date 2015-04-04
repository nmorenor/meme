//
//  MemeCreatorController.swift
//  Image Picker
//
//  Created by nacho on 3/28/15.
//  Copyright (c) 2015 Ignacio Moreno. All rights reserved.
//

import Foundation
import UIKit

class MemeCreatorController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var toolBar: UIToolbar!
    var meme:MemeEntry!;
    
    let memeTextAttributes = [
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSStrokeColorAttributeName : UIColor.blackColor(),
        //negative stroke width so that we get the foreground color
        NSStrokeWidthAttributeName: -5.0
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(.Camera);
        topText.delegate = self;
        bottomText.delegate = self;
        //self.navigationItem.hidesBackButton = true;
        
        bottomText.autocapitalizationType = UITextAutocapitalizationType.AllCharacters;
        topText.autocapitalizationType = UITextAutocapitalizationType.AllCharacters;
        
        bottomText.defaultTextAttributes = memeTextAttributes;
        topText.defaultTextAttributes = memeTextAttributes;
        
        topText.text = MemeEntry.defaultValues[MemeEntry.topTextID];
        bottomText.text = MemeEntry.defaultValues[MemeEntry.bottomTextID];
        
        topText.textAlignment = NSTextAlignment.Center;
        bottomText.textAlignment = NSTextAlignment.Center;
        
        self.meme = MemeEntry(textFields: MemeEntry.getInitialTextFields(), originalImage: nil, memedImage: nil);
    }
    
    func close() {
        self.navigationController?.popToRootViewControllerAnimated(true);
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        subscribeToKeyboardNotifications();
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "close");
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "share:");
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        unsubscribeFromKeyboardNotifications();
    }
    
    @IBAction func pickAnImage(sender: AnyObject) {
        let imagePicker = UIImagePickerController();
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        imagePicker.delegate = self;
        self.presentViewController(imagePicker, animated: true, completion: nil);
    }
    
    @IBAction func pickAnImageFromCamera(sender: AnyObject) {
        let imagePicker = UIImagePickerController();
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
        imagePicker.delegate = self;
        self.presentViewController(imagePicker, animated: true, completion: nil);
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage;
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        var currentValue:String = self.meme.textFields[textField.restorationIdentifier!]!;
        
        if (currentValue.isEmpty) {
            textField.text = "";
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.meme.textFields[textField.restorationIdentifier!] = textField.text;
        if let currentValue = self.meme.textFields[textField.restorationIdentifier!] {
            if (currentValue.isEmpty) {
                textField.text = MemeEntry.defaultValues[textField.restorationIdentifier!];
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil);
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil);
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if (self.bottomText.isFirstResponder()) {
            self.view.frame.origin.y += getKeyboardHeight(notification);
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if (self.bottomText.isFirstResponder()) {
            self.view.frame.origin.y -= getKeyboardHeight(notification);
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo;
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as NSValue;
        return keyboardSize.CGRectValue().height
    }
    
    func share(sender: AnyObject) {
        if (self.imageView.image == nil) {
            return;
        }
        var item:UIImage! = generateMemedImage();
        let activityVC = UIActivityViewController(activityItems: [item], applicationActivities: nil);
        activityVC.completionWithItemsHandler = { (activityType:String!, completed:Bool, items:[AnyObject]!, error:NSError!) -> Void in
            if (completed) {
                self.save(item);
                self.dismissViewControllerAnimated(true, completion: nil);
            }
        }
        self.presentViewController(activityVC, animated: true, completion: nil);
    }
    
    func save(memedImage:UIImage!) {
        self.meme.memedImage = memedImage;
        self.meme.originalImage = imageView.image;
        
        let object = UIApplication.sharedApplication().delegate;
        let appDelegate = object as AppDelegate;
        appDelegate.memes.append(self.meme);
        self.close();
    }
    
    func generateMemedImage() -> UIImage {
        hideElements(true);
        hideText(true);
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.drawViewHierarchyInRect(self.view.frame,
            afterScreenUpdates: true)
        let memedImage : UIImage =
        UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        hideElements(false);
        hideText(false);
        
        return memedImage
    }
    
    func hideElements(hidden:Bool) {
        self.toolBar.hidden = hidden;
        self.navigationController?.navigationBar.hidden = hidden;
    }
    
    func hideText(hidden:Bool) {
        var topText:String = self.meme.textFields[MemeEntry.topTextID]!;
        var bottomText:String = self.meme.textFields[MemeEntry.bottomTextID]!;
        if (topText.isEmpty) {
            self.topText.hidden = hidden;
        }
        if (bottomText.isEmpty) {
            self.bottomText.hidden = hidden;
        }
    }
}

