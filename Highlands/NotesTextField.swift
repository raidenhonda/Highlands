//
//  NotesTextField.swift
//  Highlands
//
//  Created by Raiden Honda on 10/3/15.
//  Copyright © 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class NotesTextField : UITextField, UITextFieldDelegate {
    
    private var _noteId : Int
    private var _inputId : String
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Coding not supported on this class")
    }
    
    init(frame: CGRect, noteId: Int, inputId: String) {
        _noteId = noteId
        _inputId = inputId
        
        super.init(frame: frame)
        
        DataManager.sharedInstance.getNote(noteId, inputId: inputId) { (value) -> () in
            if (value != "") {
                self.text = value
            } 
        }
        
        self.delegate = self
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // Make sure that the messageId and noteId were set, and that there's more than empty space
        if (self._noteId != 0 && self._inputId != "") {
            DataManager.sharedInstance.updateNote(_noteId, inputId: _inputId, value: textField.text!, success: nil)
        }
    }
}
