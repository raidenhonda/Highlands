//
//  Notes.swift
//  Highlands
//
//  Created by Raiden Honda on 9/14/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//
// ****** Commenting out all code in this file rather than archiving to preserver history. Delete July 2016 ******
//import Foundation
//import UIKit
//class Line {
//    var lineJson: JSON!
//    var lineId: Int = 0
//    var position: Int = 0
//    var items = [Item]()
//}
//
//class Item {
//    var itemJson: JSON!
//    var itemId: Int = 0
//    var view: UIView!
//    var position: Int? = 0
//    var isInlineNote: Bool = false
//}
//class Notes {
//    struct lineTypes {
//        static let lineKey = "line"
//        static let scriptureKey = "scripture"
//        static let blankTextKey = "blank-text"
//        static let blankKey = "blank"
//        static let indentKey = "indent"
//        static let doubleIndentKey = "double-indent"
//    }
//    var notesJson : JSON
//    var noteId : Int
//    var parseNotesData : [String] = []
//    var lines = [Line]()
//    var width: CGFloat = 0.0
//    var indentSize: CGFloat = 10.0
//    init () {
//        notesJson = JSON("")
//        noteId = 0
//    }
//    init(notesJson: JSON, withViewWidth width: CGFloat) {
//        // Set properties
//        self.notesJson = notesJson
//        self.noteId = notesJson["id"].intValue
//        self.width = width
//        
//        // Increase the indent size a smidge for iPad.
//        if DeviceType.IS_IPAD {
//            self.indentSize = CGFloat(25.0)
//        }
//        
//        /* OVERVIEW - [JG] 10/21/15
//        
//            The basic idea here is to create LINE objects for each full line in the notes.
//                - Lines with Blanks
//                - Scripture
//                - Text
//                - Section Headers
//        
//            For each LINE we build up a collection of ITEM's that make up that LINE. 
//                - Example: for a "blank" we build up a collection fo labels and textvies to make up the LINE
//        */
//        
//        // The first item is the Sermon Artwork so we create the Notes Header here.
//        let headerLine = Line()
//        let headerItem = Item()
//        headerItem.view = self.getNotesHeader()
//        headerLine.items.append(headerItem)
//        self.lines.append(headerLine)
//        
//        // So that items don't span edge to edge
//        self.width = self.width - 10
//
//        // Get the "sections" array
//        let sections = self.notesJson["sections"]
//
//        // Foreach "section"
//        for (_, sectionJson) in sections {
//            
//            // Section Headers
//            let sectionHeaderLine = self.getLine(sectionJson)
//
//            // Header Item
//            let headerItem = self.getItem(sectionJson)
//            headerItem.view = self.getLabelForHeader(sectionJson["content"].stringValue)
//            sectionHeaderLine.items.append(headerItem)
//            self.lines.append(sectionHeaderLine)
//            
//            var linesSorted = Array<Line>()
//            
//            for (_, subJson) in sectionJson["lines"] {
//                let nestedLine = self.getLine(subJson)
//                
//                // Check for indentation
//                var isIndented = false
//                if subJson["property_name"].stringValue == lineTypes.indentKey {
//                    let indentItem = getItem(subJson)
//                    indentItem.view = self.getIndentView()
//                    nestedLine.items.append(indentItem)
//                    isIndented = true
//                }
//                
//                // Check for double indentation
//                var isDoubleIndented = false
//                if subJson["property_name"].stringValue == lineTypes.doubleIndentKey {
//                    let indentItem = getItem(subJson)
//                    indentItem.view = self.getIndentView()
//                    // Add two items for a double indentation
//                    nestedLine.items.append(indentItem)
//                    nestedLine.items.append(indentItem)
//                    isDoubleIndented = true
//                }
//                
//                // Check for Prefix
//                // A prefix is a numbered list, bullet list, or check marks
//                let prefix = subJson["prefix_name"].stringValue
//                if !prefix.isEmpty {
//                    let prefixItem = getItem(subJson)
//                    prefixItem.view = self.getPrefixView(prefix,
//                        isIndented:isIndented,
//                        isDoubleIndented:isDoubleIndented)
//                    nestedLine.items.append(prefixItem)
//                }
//                
//                let itemCount = subJson["items"].count
//                if itemCount > 1 {
//                    var itemArray = Array<Item>()
//                    for (_, itemJson) in subJson["items"] {
//                        if itemJson["property_name"].stringValue == lineTypes.blankKey {
//                            let nestedItem = self.getItem(itemJson)
//                            nestedItem.view = self.getViewForBlank(itemJson["content"].stringValue,
//                                isIndented: isIndented,
//                                isDoubleIndented:isDoubleIndented,
//                                itemId: String(nestedItem.itemId))
//                            itemArray.append(nestedItem)
//                        } else {
//                            // Generate single labels for each "blank" text
//                            let contentLabelArray = self.getLabelForText(itemJson["content"].stringValue,
//                                isIndented: isIndented,
//                                isDoubleIndented:isDoubleIndented)
//                            for label in contentLabelArray {
//                                let singleWordItem = self.getSingleWordItem(label,
//                                    itemJson: itemJson,
//                                    itemId: itemJson["id"].intValue,
//                                    position: itemJson["position"].intValue)
//                                itemArray.append(singleWordItem)
//                            }
//                        }
//                    }
//                    
//                    // Sort Items by position
//                    itemArray.sortInPlace({ (i1: Item, i2:Item) -> Bool in
//                        return i1.position < i2.position
//                    })
//                    nestedLine.items += itemArray
//                    
//                } else {
//                    for (_, itemJson) in subJson["items"] {
//                        if itemJson["property_name"].stringValue == lineTypes.scriptureKey {
//                            let singleItem = self.getItem(itemJson)
//                            singleItem.view = self.getLabelForScripture(itemJson["content"].stringValue,
//                                isIndented: isIndented,
//                                isDoubleIndented:isDoubleIndented)
//                            nestedLine.items.append(singleItem)
//                        } else {
//                            // Generate single labels for each "blank" text
//                            let contentLabelArray = self.getLabelForText(itemJson["content"].stringValue,
//                                isIndented: isIndented,
//                                isDoubleIndented:isDoubleIndented)
//                            for label in contentLabelArray {
//                                let singleWordItem = self.getSingleWordItem(label,
//                                    itemJson: itemJson,
//                                    itemId: itemJson["Id"].intValue,
//                                    position: nil)
//                                nestedLine.items.append(singleWordItem)
//                            }
//                        }
//                    }
//                }
//                
//                // Add inline note item
//                // This is added to the end of every "Line" so that the user can add thier own notes.
//                let userNoteItem = Item()
//                userNoteItem.isInlineNote = true
//                userNoteItem.view = UIView(frame: CGRectMake(0, 0, width, 28))
//                nestedLine.items.append(userNoteItem)
//                
//                linesSorted.append(nestedLine)
//                isIndented = true
//            }
//            // Order the Lines by position
//            linesSorted.sortInPlace({ (l1: Line, l2: Line) -> Bool in
//                return l1.position < l2.position
//            })
//            self.lines += linesSorted
//        }
//        
//        // The last item is the footer, which does not have any associated json data so we append an empty line here
//        let footerLine = Line()
//        let footerItem = Item()
//        footerItem.view = self.getNotesFooter()
//        footerLine.items.append(footerItem)
//        self.lines.append(footerLine)
//    }
//    func getNotesHeader() -> UIView {
//        var height = 220.0
//        if DeviceType.IS_IPHONE_6 {
//            height = 255.0
//        } else if DeviceType.IS_IPHONE_6P {
//            height = 280.0
//        } else if DeviceType.IS_IPAD {
//            height = 470.0
//        }
//        return UIView(frame: CGRectMake(0, 0, self.width + 10, CGFloat(height)))
//    }
//    
//    func getNotesFooter() -> UIView {
//        return UIView(frame: CGRectMake(0, 0, self.width, 70))
//    }
//    
//    func getLabelForHeader(content: String) -> UILabel {
//        let label = UILabel(frame: CGRectMake(0, 0, self.width, CGFloat.max))
//        label.text = content
//        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
//        label.numberOfLines = 0
//        if DeviceType.IS_IPAD {
//            label.font = UIFont.highlandsBold(22)
//        } else {
//            label.font = UIFont.highlandsBold(20)
//        }
//        label.textColor = UIColor.highlandsBlue()
//        label.sizeToFit()
//        return label
//    }
//    
//    func getLabelForText(content: String, isIndented: Bool, isDoubleIndented: Bool) -> [UILabel] {
//        // Here we break apart the string into individual words to make it easily adapatable to any layout.
//        let stringArray = content.characters.split{$0 == " "}.map(String.init)
//
//        var labelArray = [UILabel]()
//        for string in stringArray {
//            // Adapt MaxWidth to account for indentation
//            let maxWidth = self.getMaxwidth(isIndented, isDoubleIndented: isDoubleIndented)
//            
//            let label = UILabel(frame: CGRectMake(0, 0, maxWidth, CGFloat.max))
//            label.text = string
//            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
//            label.numberOfLines = 0
//            if DeviceType.IS_IPAD {
//                label.font = UIFont.highlandsMedium(20)
//            } else {
//                label.font = UIFont.highlandsMedium(18)
//            }
//            label.textColor = UIColor(white: 0.2, alpha: 1.0)
//            label.sizeToFit()
//            labelArray.append(label)
//        }
//        return labelArray
//    }
//    
//    func getViewForBlank(content: String, isIndented: Bool, isDoubleIndented: Bool, itemId: String, noteId : Int) -> UIView {
//        let maxWidth = self.getMaxwidth(isIndented, isDoubleIndented: isDoubleIndented)
//
//        // Make label to calculate size
//        let label = UILabel(frame: CGRectMake(0, 0, maxWidth, CGFloat.max))
//        label.text = content
//        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
//        label.numberOfLines = 0
//        if DeviceType.IS_IPAD {
//            label.font = UIFont.highlandsBold(18)
//        } else {
//            label.font = UIFont.highlandsBold(16)
//        }
//        label.textColor = UIColor.highlandsBlue()
//        label.sizeToFit()
//        label.hidden = true
//        
//        let textWidth = label.frame.width + 50
//        let viewHeight = label.frame.height + 10
//        
//        let view = UIView(frame: CGRectMake(0, 0, textWidth, viewHeight))
//        view.addSubview(label)
//        
//        let underline = UIView(frame: CGRectMake(0, viewHeight - 3, textWidth, 2))
//        underline.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
//        view.addSubview(underline)
//
//        let textField = NotesTextField(frame: CGRectMake(0, 0, textWidth, viewHeight), noteId: noteId, inputId: itemId)
//        if DeviceType.IS_IPAD {
//            textField.font = UIFont.highlandsBold(20)
//        } else {
//            textField.font = UIFont.highlandsBold(18)
//        }
//        textField.textColor = UIColor.highlandsBlue()
//        view.addSubview(textField)
//        
//        return view
//    }
//    
//    func getLabelForScripture(content: String, isIndented: Bool, isDoubleIndented: Bool) -> UILabel {
//        let maxWidth = self.getMaxwidth(isIndented, isDoubleIndented: isDoubleIndented)
//        let label = UILabel(frame: CGRectMake(0, 0, maxWidth, CGFloat.max))
//        label.text = content
//        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
//        label.numberOfLines = 0
//        if DeviceType.IS_IPAD {
//            label.font = UIFont.highlandsMediumItalic(17)
//        } else {
//            label.font = UIFont.highlandsMediumItalic(15)
//        }
//        label.textColor = UIColor(white: 0.2, alpha: 1.0)
//        label.sizeToFit()
//                
//        return label
//    }
//    
//    func getIndentView() -> UIView {
//        let view = UIView(frame: CGRectMake(0, 0, self.indentSize, 50))
//        return view
//    }
//    
//    func getPrefixView(content: String, isIndented: Bool, isDoubleIndented: Bool) -> UIView {
//        
//        let index = content.startIndex.advancedBy(1)
//        let digit = content.substringToIndex(index)
//        let number = Int(digit)
//        if DeviceType.IS_IPAD {
//            
//        }
//        var font = UIFont.highlandsBold(30)
//        if number > 0 {
//            font = UIFont.highlandsBold(20)
//        }
//        
//        if DeviceType.IS_IPAD {
//            font = UIFont.highlandsBold(32)
//            if number > 0 {
//                font = UIFont.highlandsBold(22)
//            }
//        }
//        
//        // Adapt MaxWidth to account for indentation
//        let maxWidth = self.getMaxwidth(isIndented, isDoubleIndented: isDoubleIndented)
//        
//        let label = UILabel(frame: CGRectMake(0, 0, maxWidth, CGFloat.max))
//        label.text = content
//        label.numberOfLines = 0
//        label.font = font
//        label.textColor = UIColor(white: 0.2, alpha: 1.0)
//        label.sizeToFit()
//        return label
//    }
    
//    func getSingleWordItem(label: UILabel, itemJson: JSON, itemId: Int, position: Int?) -> Item {
//        let item = Item()
//        item.itemId = itemId
//        item.itemJson = itemJson
//        item.view = label
//        item.position = position
//        return item
//    }
//    func getMaxwidth(isIndented: Bool, isDoubleIndented: Bool) -> CGFloat {
//        // We need to adjust the width depend on the device.
//        let indentAdjustment: CGFloat = DeviceType.IS_IPAD ? 60 : 30
//        var maxWidth = self.width
//        if isIndented {
//            maxWidth = maxWidth - indentAdjustment
//        } else if isDoubleIndented {
//            maxWidth = maxWidth - (indentAdjustment * 2)
//        }
//        return CGFloat(maxWidth)
//    }
    // MARK Helper Methods
//    private func getLine(data: JSON) -> Line {
//        let line = Line()
//        line.lineId = data["id"].intValue
//        line.lineJson = data
//        line.position = data["position"].intValue
//        return line
//    }
//    private func getItem(data: JSON) -> Item {
//        let item = Item()
//        item.itemId = data["id"].intValue
//        item.position = data["position"].intValue
//        item.itemJson = data
//        return item
//    }
//}
