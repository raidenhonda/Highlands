//
//  NoteDataSource.swift
//  Highlands
//
//  Created by Raiden Honda on 2/10/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

class NotesUISource {
    private var note : Note = Note()
    var layoutLines : [LayoutLine] = [LayoutLine]()

    // User Note vars
    var cellHeightCache = NSCache()
    let userNotesCellHeight: Float = 28.0
    
    init(note : Note) {
        self.note = note
        flattenNote(note)
    }
    
    init() {}
    
    // MARK: Data mapping methods
    
    // Create a flattened array of "lines" from a Note that the collection view can properly iterate
    // The lines array represents a tuple of type (LayoutLineTypes, optional Id). The line type will be used
    // to determine what UI to present and the Id will be used to search the Note structure and find the correct data.
    // The line items represents a dictionary where key is the lineId and value is an array of tuples representing ItemType and ItemId.
    private func flattenNote(note : Note) {
        var lines = [LayoutLine]()
        
        // Add header
        lines.append(LayoutLine(lineType: .Header, objId: nil))
        
        // Iterate through sections
        for section in note.sections {
            
            // Add section itself
            lines.append(LayoutLine(lineType: .SectionHeader, objId: section.id))
            
            // Iterate through lines in section
            for line in section.lines {
                
                // Add the line
                let layoutLine = LayoutLine(lineType: .Line, objId: line.id)
                
                // Flatten items
                if line.prefixName != nil {
                    layoutLine.lineItems.append(LayoutLineItem(itemType: .Prefix, itemId: nil))
                }
                
                for item in line.items {
                    if item.itemPropertyType == .blank {
                        let lineItem = LayoutLineItem(itemType: .Blank, itemId: item.id as Int?)
                        layoutLine.lineItems.append(lineItem)
                    }

                    if item.itemPropertyType == .blankText {
                        // We will break up blank-text items into individual words to ensure they flow properly
                        let stringArray = item.content.characters.split{$0 == " "}.map(String.init)
                        for string in stringArray {
                            let lineItem = LayoutLineItem(itemType: .BlankText, itemId: item.id as Int?)
                            lineItem.content = string
                            layoutLine.lineItems.append(lineItem)
                        }
                    }
                    
                    if item.itemPropertyType == .scripture {
                        let lineItem = LayoutLineItem(itemType: .Scripture, itemId: item.id as Int?)
                        layoutLine.lineItems.append(lineItem)
                    }
                }
             
                // Add the line
                lines.append(layoutLine)
                
                // At the end of every line we inject a user line
                lines.append(LayoutLine(lineType: .InlineUserNote, objId: line.id))
            }
        }
        
        // Add footer
        lines.append(LayoutLine(lineType: .Footer, objId: nil))
        
        self.layoutLines = lines
    }
    
    // MARK: UI Methods
    private func getSizeForText(font : UIFont, text : String, maxWidth : CGFloat) -> CGSize {
        // Set attributes
        let attributes = [NSFontAttributeName : font]
        
        // Calculate size
        let rect = NSString(string: text)
            .boundingRectWithSize(
                CGSizeMake(maxWidth, CGFloat.max),
                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                attributes: attributes,
                context: nil)
        
        return rect.size
    }
    
    // MARK: UI Size Methods
    func getSizeForItemAtIndexPath(indexPath : NSIndexPath, collectionViewWidth : CGFloat) -> CGSize {
        // Get layout obj
        let layoutLine : LayoutLine = layoutLines[indexPath.section]
        
        // Calculate max width
        let maxWidth = collectionViewWidth - 15 - 10 // The section insets are hard-coded to left:15 and right:10, and it's not possible to properly retrieve these values
        
        // Build UI Based on Type
        switch layoutLine.lineType {
        case .Header:
            return getSizeForHeader(collectionViewWidth)
        case .SectionHeader:
            return getSizeForSectionHeader(layoutLine, maxWidth: maxWidth)
        case .Line:
            // Calculate height based upon item type
            // Get the item type
            let layoutItem = layoutLine.lineItems[indexPath.item]
            
            switch layoutItem.itemType {
            case .Blank:
                return getSizeForBlank(layoutItem, maxWidth: maxWidth)
            case .BlankText:
                return getSizeForBlankText(layoutItem, maxWidth: maxWidth)
            case .Scripture:
                return getSizeForScripture(layoutLine, layoutLineItem: layoutItem, maxWidth: maxWidth)
            case .Prefix:
                return getSizeForPrefix(maxWidth)
            }
        case .InlineUserNote:
            return getSizeForInlineNote(indexPath, collectionViewWidth: collectionViewWidth)
        case .Footer:
            return CGSizeMake(maxWidth, 190.0)
        }
    }
    
    private func getSizeForHeader(width: CGFloat) -> CGSize {
        // Get header height, it's pretty straight forward
        var height = 220.0
        if DeviceType.IS_IPHONE_6 {
            height = 255.0
        } else if DeviceType.IS_IPHONE_6P {
            height = 280.0
        } else if DeviceType.IS_IPAD {
            height = 470.0
        }
        return CGSizeMake(width, CGFloat(height)) // Ignore max-width and section insets
    }
    
    private func getSizeForSectionHeader(line: LayoutLine, maxWidth: CGFloat) -> CGSize {
        // Need to calculate the size
        let section = getSectionBySectionId(line.objId!)
        // Create the font
        var font = UIFont.highlandsMedium(20)
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsMedium(22)
        }
        return getSizeForText(font, text: section!.content, maxWidth: maxWidth)
    }
    
    private func getSizeForBlank(layoutLineItem : LayoutLineItem, maxWidth : CGFloat) -> CGSize {
        // Create the font
        var font = UIFont.highlandsBook(18)
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsBook(20)
        }
        
        // Get the item
        let item = getItemByItemId(layoutLineItem.itemId!)!
        
        // Get size of really long word in order for all blanks to be identical size
        var size = getSizeForText(font, text: item.content, maxWidth: maxWidth)
        
        // Set the minimum size for blanks.
        if size.width < 60 {
            size = CGSizeMake(60, size.height)
        } else if size.width < (maxWidth - 20) {
            size = CGSizeMake(size.width + 15, size.height)
        }
        
        return size
    }
    
    private func getSizeForBlankText(layoutItem : LayoutLineItem, maxWidth: CGFloat) -> CGSize {
        // Create the font
        var font = UIFont.highlandsBook(18)
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsBook(20)
        }
        
        return getSizeForText(font, text: layoutItem.content!, maxWidth: maxWidth)
    }
    
    private func getSizeForScripture(layoutLine : LayoutLine, layoutLineItem : LayoutLineItem, var maxWidth: CGFloat) -> CGSize {
        // Create the font
        var font = UIFont.highlandsBook(15)
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsBook(17)
        }
        
        // Compenseate for indent/double-indent
        let line = getLineByLineId(layoutLine.objId!)!
        if (line.linePropertyType == .indent) {
            maxWidth -= 15
        }
        
        if (line.linePropertyType == .doubleIndent) {
            maxWidth -= 30
        }
        
        // Get the item
        let item = getItemByItemId(layoutLineItem.itemId!)!
        
        return getSizeForText(font, text: item.content, maxWidth: maxWidth)
    }
    
//    private func getSizeForIndent(isDouble : Bool, maxWidth: CGFloat) -> CGSize {
//        // Create the font
//        var font = UIFont.highlandsBook(18)
//        if DeviceType.IS_IPAD {
//            font = UIFont.highlandsBook(20)
//        }
//        
//        let width = (isDouble) ? 20 : 10
//        
//        // Get "size" from a pointless value
//        let size = getSizeForText(font, text: "MM", maxWidth: maxWidth)
//        return CGSize(width: CGFloat(width), height: size.height)
//    }
    
    private func getSizeForPrefix(maxWidth : CGFloat) -> CGSize {
        // Create the font
        var font = UIFont.highlandsBook(18)
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsBook(20)
        }
        // Get "size" for a check
        var size = getSizeForText(font, text: "✓", maxWidth: maxWidth)
        size.width += 12 // The checkmark gets cut-off for some reason
        return size
    }
    
    private func getSizeForInlineNote(indexPath : NSIndexPath, collectionViewWidth : CGFloat) -> CGSize {
        var height = cellHeightCache.objectForKey(indexPath)?.floatValue
        if height < 1 {
            height = self.userNotesCellHeight
        }
        return CGSizeMake(collectionViewWidth, CGFloat(height!))
    }
    
    // MARK: UI Item Methods
    func getCellForIndexPath(indexPath : NSIndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        // Get layout obj
        let layoutLine = layoutLines[indexPath.section]
        
        // Build UI Based on Type
        switch layoutLine.lineType {
        case .Header:
            return getCellForHeader(indexPath, collectionView: collectionView)
        case .SectionHeader:
            // Get a cell
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("NoteCell", forIndexPath: indexPath)
            clearCellContents(&cell)
            return getCellForSectionHeader(layoutLine, cell: cell)
        case .Line:
            if let line = getLineByLineId(layoutLine.objId!) {
                // Get a cell
                var cell = collectionView.dequeueReusableCellWithReuseIdentifier("NoteCell", forIndexPath: indexPath)
                clearCellContents(&cell)
                
                // Get the item
                let item = layoutLine.lineItems[indexPath.item] //dataSource.layoutLineItems[line.id]![indexPath.item]
                
                switch item.itemType {
                case .Blank:
                    return getCellForBlank(item, cell: cell)
                case .BlankText:
                    return getCellForBlankText(item, cell: cell)
                case .Scripture:
                    return getCellForScripture(item, cell: cell)
                case .Prefix:
                    return getCellForPrefix(line, cell: cell)
                }
            }
        case .InlineUserNote:
            return getCellForInlineNote(indexPath, collectionView: collectionView, layoutLine: layoutLine)
        case .Footer:
            return collectionView.dequeueReusableCellWithReuseIdentifier("FooterCell", forIndexPath: indexPath) as! NotesFooterCell
        }
        
        // Get a cell
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("NoteCell", forIndexPath: indexPath)
        clearCellContents(&cell)
        return cell
    }
    
    private func getCellForHeader(indexPath : NSIndexPath, collectionView : UICollectionView) -> NotesHeaderCell {
        let headerCell: NotesHeaderCell = collectionView.dequeueReusableCellWithReuseIdentifier("HeaderCell", forIndexPath: indexPath) as! NotesHeaderCell
        let url = "https://www.churchofthehighlands.com/images/content/series/_series_mobile/\(self.note.seriesId).jpg"
        if let imageUrl = NSURL(string: url) {
            headerCell.seriesArtwork.sd_setImageWithURL(imageUrl)
        }
        headerCell.sermonTitle.text = self.note.title
        headerCell.sermonTitle.textColor = UIColor.highlandsBlue()
        return headerCell
    }
    
    private func getCellForSectionHeader(layoutLine : LayoutLine, cell : UICollectionViewCell) -> UICollectionViewCell {
        let section = getSectionBySectionId(layoutLine.objId!)!
        let label = UILabel(frame: CGRectMake(0, 0, cell.frame.width, CGFloat.max))
        label.text = section.content
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.numberOfLines = 0
        if DeviceType.IS_IPAD {
            label.font = UIFont.highlandsMedium(22)
        } else {
            label.font = UIFont.highlandsMedium(20)
        }
        label.textColor = UIColor.highlandsBlue()
        label.sizeToFit()
        cell.addSubview(label)
        
        return cell
    }
    
    private func getCellForBlank(layoutItem : LayoutLineItem, cell : UICollectionViewCell) -> UICollectionViewCell {
        // Get the item
        let item = getItemByItemId(layoutItem.itemId!)!
        
        let lineView = UIView(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
        
        // Underline
        let underline = UIView(frame: CGRectMake(0, cell.frame.height - 2, cell.frame.width, 2))
        underline.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        lineView.addSubview(underline)
        
        // Textfield
        let textField = NotesTextField(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height - 1), noteId: self.note.id, inputId: String(item.id))
        if DeviceType.IS_IPAD {
            textField.font = UIFont.highlandsBook(20)
        } else {
            textField.font = UIFont.highlandsBook(18)
        }
        textField.textColor = UIColor.highlandsBlue()
        textField.autocapitalizationType = .None
        lineView.addSubview(textField)
        cell.addSubview(lineView)

        return cell
    }

    private func getCellForBlankText(layoutItem : LayoutLineItem, cell : UICollectionViewCell) -> UICollectionViewCell {
        // Label
        let label = UILabel(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
        label.lineBreakMode = .ByWordWrapping
        label.text = layoutItem.content
        label.font = UIFont.highlandsBook(18)
        if DeviceType.IS_IPAD {
            label.font = UIFont.highlandsBook(20)
        }
        label.textColor = UIColor(white: 0.2, alpha: 1.0)
        label.sizeToFit()
        cell.addSubview(label)

        return cell
    }
    
    private func getCellForScripture(layoutItem : LayoutLineItem, cell : UICollectionViewCell) -> UICollectionViewCell {
        // Get the item
        let item = getItemByItemId(layoutItem.itemId!)!
        
        // Add label for scripture
        let label = UILabel(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
        label.text = item.content
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.numberOfLines = 0
        label.font = UIFont.highlandsBook(15)
        if DeviceType.IS_IPAD {
            label.font = UIFont.highlandsBook(17)
        }
        label.textColor = UIColor(white: 0.2, alpha: 1.0)
        label.sizeToFit()
        cell.addSubview(label)
        
        return cell
    }
    
    private func getCellForPrefix(line : Line, cell : UICollectionViewCell) -> UICollectionViewCell {
        let index = line.prefixName!.startIndex.advancedBy(1)
        let digit = line.prefixName!.substringToIndex(index)
        let number = Int(digit)
        
        var font = UIFont.highlandsBook(30)
        if number > 0 {
            font = UIFont.highlandsBook(20)
        }
        
        if DeviceType.IS_IPAD {
            font = UIFont.highlandsBook(32)
            if number > 0 {
                font = UIFont.highlandsBook(22)
            }
        }
        
        let label = UILabel(frame: CGRectMake(0, 0, cell.frame.width, cell.frame.height))
        label.text = line.prefixName!
        label.font = font
        label.textColor = UIColor(white: 0.2, alpha: 1.0)
        cell.addSubview(label)
        
        return cell
    }
    
    private func getCellForInlineNote(indexPath : NSIndexPath, collectionView : UICollectionView, layoutLine : LayoutLine) -> UserNotesCell {
        let usercell: UserNotesCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserNotesCell", forIndexPath: indexPath) as! UserNotesCell
        usercell.setUpUserCell()
        usercell.textView.delegate = usercell
        usercell.setSavedText(self.note.id, inputId: "l\(layoutLine.objId!)")
        
        // Check for opened Cell by checking the cached cell height
        let cachedHeight = cellHeightCache.objectForKey(indexPath)?.floatValue
        if cachedHeight > 1 {
            usercell.formatOpenCell()
        } else {
            usercell.formatClosedCell()
        }
        usercell.clipsToBounds = false
        
        // Open cell if there are notes
        if (usercell.textView.text == "") {
            // Set default if there aren't any active user notes.
            usercell.textView.text = "Enter your notes here..."
        }
        return usercell
    }
    
    private func clearCellContents(inout cell : UICollectionViewCell) {
        let _ = cell.subviews.map({ $0.removeFromSuperview() })
    }
    
    // MARK: Data Lookup Methods
    func getItemByItemId(itemId: Int) -> Item? {
        return self.note.sections.flatMap({$0.lines}).flatMap({$0.items}).filter({$0.id == itemId}).first
    }
    
    func getLineByLineId(lineId: Int) -> Line? {
        return self.note.sections.flatMap({$0.lines}).filter({$0.id == lineId}).first
    }
    
    func getSectionBySectionId(sectionId : Int) -> Section? {
        return self.note.sections.filter({ $0.id == sectionId }).first
    }
}

// Create enum to switch on type during collection view iteration
enum LayoutLineType {
    case Header
    case SectionHeader
    case Line
    case InlineUserNote
    case Footer
}

class LayoutLine {
    var lineType : LayoutLineType = .Line
    let objId : Int?
    var lineItems : [LayoutLineItem] = [LayoutLineItem]()
    
    init(lineType: LayoutLineType, objId : Int?) {
        self.lineType = lineType
        self.objId = objId
    }
}

enum LayoutItemType {
    case Prefix
    case Blank
    case BlankText
    case Scripture
}

class LayoutLineItem {
    var itemType : LayoutItemType = .Blank
    let itemId : Int?
    var content : String?
    
    init(itemType: LayoutItemType, itemId : Int?) {
        self.itemType = itemType
        self.itemId = itemId
    }
}
