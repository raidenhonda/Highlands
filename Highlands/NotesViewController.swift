//
//  NotesViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 9/10/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate  {

    @IBOutlet weak var collectionViewBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionview: UICollectionView!
    var selectedIndexPath = NSIndexPath()

    var noteSource = NotesUISource()
    var note: Note = Note() // Gets passed in by parent VC

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add these notifications so that we can move the 
        // textfield into view if it's hiden by the keyboard
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide", name: UIKeyboardDidHideNotification, object: nil)
        
        self.collectionview!.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 220, right: 0)
    }

    override func viewDidAppear(animated: Bool) {
        // Init DataSource
        self.noteSource = NotesUISource(note: self.note)
        
        guard noteSource.layoutLines.count > 0
            else { return }
        
        // Fetch Notes from online
        if (Globals.userIsSignedIn) {
            NotesManager.getNotes(note.id, completionHandler: { () -> () in
                // Load the notes initially
                self.collectionview.reloadData()
            })
        } else {
            // Load the notes initially
            self.collectionview.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeNotes(sender: AnyObject) {
        
        // Sync the notes when the user closes the view
        NotesManager.syncNotesAsync()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.noteSource.layoutLines.count
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let line = noteSource.layoutLines[section]
        
        // There's a single item if the line type is Header, Footer, SectionHeader, or InlineUserNote
        if line.lineType == .Header || line.lineType == .Footer || line.lineType == .SectionHeader || line.lineType == .InlineUserNote {
            return 1
        }
        
        // Double-check type is line
        if line.lineType == .Line {
            return line.lineItems.count
        }
        
        return 0
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return noteSource.getCellForIndexPath(indexPath, collectionView: collectionView)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell : UICollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)!
        
        // If it's not a notes cell then carry on.
        if cell is UserNotesCell {
            
            // Get Cell's frame
            let notesCell = cell as! UserNotesCell
            
            if notesCell.isOpen == true {
                // Close Cell and flip minus/plus button
                self.closeNotesCell(notesCell, indexPath: indexPath)
                notesCell.isOpen = false
            } else if notesCell.isOpen == false {
                self.openNotesCell(notesCell, indexPath: indexPath)
                notesCell.isOpen = true
            }
        }
        
        if cell is NotesFooterCell {
            self.emailNotes()
        }
    }
    
    // Layout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return noteSource.getSizeForItemAtIndexPath(indexPath, collectionViewWidth: self.collectionview.frame.width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        // For Image we want the section full screen
        if section == 0 {
            return UIEdgeInsetsMake(0, 0, 0, 0)
        }
        
        // Calculate Inset for Indent and Double Indent
        let layoutLine = noteSource.layoutLines[section]
        if (layoutLine.lineType == .Line) {
            let line = noteSource.getLineByLineId(layoutLine.objId!)!
            
            if line.linePropertyType == .indent {
                return UIEdgeInsetsMake(0, 30, 10, 0)
            }
            
            if line.linePropertyType == .doubleIndent {
                return UIEdgeInsetsMake(0, 45, 10, 0)
            }
        }

        return UIEdgeInsetsMake(0, 15, 10, 0)
    }
    
    func openNotesCell(cell: UserNotesCell, indexPath: NSIndexPath) {
        
        self.selectedIndexPath = NSIndexPath(forItem: 0, inSection: indexPath.section)
        
        // Store new cell height in the cache
        noteSource.cellHeightCache.setObject(150, forKey: indexPath)
        self.collectionview.performBatchUpdates({ () -> Void in
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.collectionview.frame.width, 150)
        }, completion: nil)
     
        // Invalidate the layout so that we can monkey with it.
        self.collectionview.collectionViewLayout.invalidateLayout()
        
        // Open the background view of the Text View
        cell.viewToAnimateHeight.constant = cell.frame.height - 30
        
        UIView.animateWithDuration(0.4) { () -> Void in
            cell.viewToAnimateOpen.layer.opacity = 1.0
        }
        
        cell.formatOpenCell()
    }
    
    func closeNotesCell(cell: UserNotesCell, indexPath: NSIndexPath) {
        // Invalidate the layout so that we can monkey with it.
        self.collectionview.collectionViewLayout.invalidateLayout()
        // Dismiss the keyboard
        cell.textView.resignFirstResponder()
        // Remove cell height from the cache
        noteSource.cellHeightCache.removeObjectForKey(indexPath)
        self.collectionview.performBatchUpdates({ () -> Void in
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, self.collectionview.frame.width, 30)
        }, completion: nil);
        
        cell.formatClosedCell()
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    // Detect when Keyboard opens or closes
    func keyboardDidShow() {
        if self.selectedIndexPath.length > 0 {
            self.collectionview.scrollToItemAtIndexPath(self.selectedIndexPath,
                atScrollPosition: UICollectionViewScrollPosition.CenteredVertically,
                animated: true)
        }
    }
    
    func keyboardDidHide() {
        // reset indexPath so that it won't scroll to random places
        self.selectedIndexPath = NSIndexPath()
    }
    
    // Keep only portrait orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    // MARK: Footer Cell Delegate
    func emailNotes() {
        if #available(iOS 8.0, *) {
            // Alert Controller
            let alertController = UIAlertController(title: "Email Notes", message: "Please enter your email address", preferredStyle: .Alert)
            
            // Cancel Action
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            // Email input
            var inputTextField: UITextField?
            alertController.addTextFieldWithConfigurationHandler { (textField) in
                textField.placeholder = "Email"
                textField.keyboardType = .EmailAddress
                inputTextField = textField
            }
            
            // Send
            let sendAction = UIAlertAction(title: "Send", style: .Default) { (action) in
                if inputTextField!.text != "" {
                    NotesManager.emailNotes(self.note.id, emailAddress: inputTextField!.text!)
                }
            }
            alertController.addAction(sendAction)
            
            // Present view controller
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
