//
//  NoteDeserializer.swift
//  Highlands
//
//  Created by Raiden Honda on 2/5/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

// For deserializing json coming from the highlands API
public class NoteSerializer {

    static func deserialize(data : AnyObject?) -> Note? {
        // Ensure there is data
        guard let dataObj = data
            else { return nil }

        // Map to SwiftyJson object
        let json = JSON(dataObj)

        // Create the Note
        let note = Note()
        
        // Deserialize data
        note.id = json["id"].intValue
        note.title = json["title"].stringValue
        note.data = json["data"].string
        note.published = json["published"].boolValue
        note.series = json["series"].boolValue
        note.part = json["part"].intValue
        note.date = NSDate(fromString: json["date"].stringValue, format: DateFormat.Custom("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"))
        note.slug = json["slug"].stringValue
        note.speaker = json["speaker"].stringValue
        note.speakerId = json["speaker_id"].stringValue
        note.seriesName = json["series_name"].stringValue
        note.seriesId = json["series_id"].stringValue
        note.imageUrl = json["image"].stringValue
        note.notesUrl = json["notes_url"].stringValue
        note.disabled = json["disabled"].boolValue
        note.autoUpdate = json["disabled"].boolValue
        
        note.sections = self.deserializeSections(json["sections"].array)
        
        return note
    }
    
    private static func deserializeSections(json : [JSON]?) -> [Section] {
        var sections = [Section]()
        
        // Ensure array is present
        if let jsonArray = json {
            
            // Loop through each section and deserialize
            for sectionJson in jsonArray {
                let section = Section()
                
                section.id = sectionJson["id"].intValue
                section.noteId = sectionJson["note_id"].intValue
                section.position = sectionJson["position"].intValue
                section.content = sectionJson["content"].stringValue
                section.lines = self.deserializeLines(sectionJson["lines"].array)
                
                // Add to result
                sections.append(section)
            }
        }
        
        return sections
    }
    
    private static func deserializeLines(json : [JSON]?) -> [Line] {
        var lines = [Line]()
        
        // Ensure array is present
        if let jsonArray = json {
            
            // Loop through each line and deserialize
            for lineJson in jsonArray {
                let line = Line()
                
                line.id = lineJson["id"].intValue
                line.sectionId = lineJson["section_id"].intValue
                line.position = lineJson["position"].intValue
                line.propertyName = lineJson["property_name"].stringValue
                line.prefixName = lineJson["prefix_name"].string
                line.items = self.deserializeItems(lineJson["items"].array)
                
                // Add to result
                lines.append(line)
            }
        }
        
        return lines
    }
    
    private static func deserializeItems(json : [JSON]?) -> [Item] {
        var items = [Item]()
        
        // Ensure array is present
        if let itemArray = json {
            
            // Loop through each item and deserialize
            for itemJson in itemArray {
                let item = Item()
                
                item.id = itemJson["id"].intValue
                item.lineId = itemJson["line_id"].intValue
                item.position = itemJson["position"].intValue
                item.content = itemJson["content"].stringValue
                item.propertyName = itemJson["property_name"].stringValue
                
                // Add to result
                items.append(item)
            }
        }
        
        return items
    }
}
