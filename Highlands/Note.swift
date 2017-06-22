//
//  Note.swift
//  Highlands
//
//  Created by Raiden Honda on 2/5/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

public class Note {
    var id : Int = 0
    var title : String = ""
    var data : String?
    var published : Bool = false
    var series : Bool = false
    var part : Int = 0
    var date : NSDate = NSDate()
    var slug : String = ""
    var speaker : String = ""
    var speakerId : String = ""
    var seriesName : String = ""
    var seriesId : String = ""
    var imageUrl : String = ""
    var notesUrl : String = ""
    var disabled : Bool = false
    var autoUpdate : Bool = false
    var sections : [Section] = [Section]()
    /*
        "id": 29,
        "title": "Holding On to God's Word",
        "data": null,
        "published": true,
        "series": false,
        "part": 4,
        "date": "2016-01-31T00:00:00.000Z",
        "slug": "holding-on-to-gods-word",
        "speaker": "Chris Hodges",
        "speaker_id": "chris-hodges",
        "series_name": "It is Written",
        "series_id": "it-is-written",
        "image": "https://www.churchofthehighlands.com/images/content/series/_series_grid/it-is-written.jpg",
        "notes_url": "http://media.churchofthehighlands.com/messages/2016/weekend/01-31-16/01-31-16.pdf",
        "disabled": false,
        "auto_update": true,
        "sections" : []
    */
    public init() { }
}

// MARK: As in the JSON data model we need to map sub objects for Notes
public class Section {
    var id : Int = 0
    var noteId : Int = 0
    var position : Int = 0
    var content : String = ""
    var lines : [Line] = [Line]()
    /*
        "id": 81,
        "note_id": 29,
        "position": 1,
        "content": "It Is Written",
        "lines": []
    */
    init() {}
}

public class Line {
    var id : Int = 0
    var sectionId : Int = 0
    var position : Int = 0
    var propertyName : String = ""
    var prefixName : String?
    var items : [Item] = [Item]()
    var linePropertyType : LinePropertyType {
        get {
            let lineType = LinePropertyType(rawValue: self.propertyName)
            return (lineType != nil) ? lineType! : LinePropertyType.line
        }
    }
    /*
        "id": 703,
        "section_id": 81,
        "position": 1,
        "property_name": "line",
        "prefix_name": null,
        "items": []
    */
    init() {}
}

public class Item {
    var id : Int = 0
    var lineId : Int = 0
    var position : Int = 0
    var content : String = ""
    var propertyName : String = ""
    var itemPropertyType : BlankPropertyType {
        get {
            let itemType = BlankPropertyType(rawValue: self.propertyName)
            return (itemType != nil) ? itemType! : BlankPropertyType.blank
        }
    }
    /*
        "id": 1219,
        "line_id": 681,
        "position": 1,
        "content": "Feelings",
        "property_name": "blank"
    */
    init() {}
}

public enum LinePropertyType : String {
    case line = "line"
    case indent = "indent"
    case doubleIndent = "double-indent"
}

public enum BlankPropertyType : String {
    case blank = "blank"
    case blankText = "blank-text"
    case scripture = "scripture"
}
