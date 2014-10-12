//
//  ViewController.swift
//  SwiftExample
//
//  Created by Nick Lockwood on 12/10/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit

class ViewController: UIViewController, iConsoleDelegate {

    @IBOutlet var label: UILabel!
    @IBOutlet var field: UITextField!
    @IBOutlet var swipeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iConsole.sharedConsole().delegate = self;
    }
    
    @IBAction func sayHello(sender: AnyObject) -> Void {
        
        var text = field.text ?? ""
        if text == "" {
            text = "World"
        }
        text = "Hello " + text
        
        label.text = text
        iConsole.info("Said '%@'", args: getVaList([text as NSString]))
    }
    
    @IBAction func crash(sender: AnyObject) -> Void {
    
        NSException(name: "HelloWorldException", reason: "Demonstrating crash logging", userInfo: nil).raise()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        sayHello(self)
        return true
    }

    func handleConsoleCommand(command: String) -> Void {
        
        if command == "version" {
            
            iConsole.info("%@ version %@", args:getVaList([
                NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as NSString,
                NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as NSString]))
        
        } else {
            
            iConsole.error("unrecognised command, try 'version' instead", args:getVaList([]))
        }
    }
}

