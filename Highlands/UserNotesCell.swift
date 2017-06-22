//
//  CollectionViewCell.swift
//  OpenCollectionView
//
//  Created by Raiden Honda on 9/23/15.
//  Copyright © 2015 Beloved Robot. All rights reserved.
//

import UIKit

class UserNotesCell: UICollectionViewCell, UITextViewDelegate {
    
    var indexPath = NSIndexPath()
    var isOpen = false
    var hasValue = false
    private var noteId : Int = 0
    private var inputId : String = ""
    
    var minusButton: MinusButton = MinusButton()
    var plusButton: PlusButton = PlusButton()
    
    @IBOutlet weak var viewToAnimateOpen: UIView!
    @IBOutlet weak var viewToAnimateHeight: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setUpUserCell() {
        
        for subview in self.subviews {
            if subview is MinusButton {
                subview.removeFromSuperview()
            }
            if subview is PlusButton {
                subview.removeFromSuperview()
            }
        }        
        self.minusButton = MinusButton(frame: CGRectMake(self.frame.width - 48, 0, 24, 24))
        self.minusButton.layer.cornerRadius = 4
        self.addSubview(self.minusButton)
        
        self.plusButton = PlusButton(frame: CGRectMake(self.frame.width - 48, 0, 24, 24))
        self.plusButton.layer.cornerRadius = 4
        self.addSubview(self.plusButton)
        
        self.textView.text = ""
        
    }
    
    func formatOpenCell() {
        self.viewToAnimateOpen.layer.opacity = 1.0
        self.viewToAnimateHeight.constant = self.frame.height - 30
        
        // Flip plus/minus button
        self.plusButton.hidden = true
        self.minusButton.hidden = false
        
        if self.hasValue {
            self.setupCellWithText()
        } else {
            self.setupCellWithoutText()
        }
    }
    
    func formatClosedCell() {
        self.viewToAnimateOpen.layer.opacity = 0.0
        self.viewToAnimateHeight.constant = 0
        
        // Flip plus/minus button
        self.plusButton.hidden = false
        self.minusButton.hidden = true
        
        if self.hasValue {
            self.setupCellWithText()
        } else {
            self.setupCellWithoutText()
        }
        
    }
    
    func setupCellWithText() {
        self.plusButton.layer.borderWidth = 1.0
        self.plusButton.layer.borderColor = UIColor.highlandsBlue().CGColor
        self.minusButton.layer.borderWidth = 1.0
        self.minusButton.layer.borderColor = UIColor.highlandsBlue().CGColor
    }

    func setupCellWithoutText() {
        self.plusButton.layer.borderWidth = 0.0
        self.plusButton.layer.borderColor = UIColor.clearColor().CGColor
        self.minusButton.layer.borderWidth = 0.0
        self.minusButton.layer.borderColor = UIColor.clearColor().CGColor
    }
    
    func setSavedText(noteId: Int, inputId: String) {
        self.noteId = noteId
        self.inputId = inputId
        
        DataManager.sharedInstance.getNote(noteId, inputId: inputId) { (value) -> () in
            if let text = value {
                self.textView.text = text
                self.hasValue = true
            } else {
                self.hasValue = false
            }
            
        }
    }
    
    // MARK: TextView Delegate Method
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Enter your notes here..." {
            textView.text = ""
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        // Make sure that the messageId and noteId were set, and that there's more than empty space
        if (self.noteId != 0 && self.inputId != "") {
            DataManager.sharedInstance.updateNote(noteId, inputId: inputId, value: textView.text, success: nil)
            self.hasValue = true
        }
    }
}
