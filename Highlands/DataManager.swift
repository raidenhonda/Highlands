//
//  DataManager.swift
//  Highlands
//
//  Created by Raiden Honda on 9/29/15.
//  Copyright © 2015 Church of the Highlands. All rights reserved.
//

import Foundation

class DataManager {
    
    static let databaseName : String = "highlands.sqlite3"
    var queue : FMDatabaseQueue
    
    static var sharedInstance : DataManager = DataManager()
    
    private init() {
        // Get and unwrap instance of BRDatabase
        let sharedDatabase = BRDatabase.sharedBRDatabase() as! BRDatabase
        
        // If database path is nil then we are assured that it has not yet been created
        if let path = sharedDatabase.databasePath {
            NSLog("DB created at path: \(path)")
        } else {
            sharedDatabase.initializeWithDatabaseName(DataManager.databaseName, withDatabaseVersion: 0.0, withSuccess: nil)
            print("Path is \(sharedDatabase.databasePath)")
        }
        
        // Initialize the queue
        let appDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let dbPath = "\(appDir)/\(DataManager.databaseName)"
        queue = FMDatabaseQueue(path: dbPath)
    }
    
    func insertSomeText(text: String, success: ( () -> () )?) {
        queue.inDatabase { (database) -> Void in
            database.executeUpdate("INSERT INTO Test (someText) VALUES (?);", text)
            
            // Unwrap success block and execute
            if let callableSuccess = success {
                callableSuccess()
            }
        }
    }
    
    func retrieveSomeText(success: ( (String) -> () )? ) {
        queue.inDatabase { (database) -> Void in
            
            // Create an object to hold result
            var resultText : String = ""
            
            if let result = database.executeQuery("SELECT * FROM Test;") {
                
                while (result.next()) {
                    resultText = result.stringForColumn("someText")
                }
                
                result.close()
            }
            
            // Unwrap success block and execute
            if let callableSuccess = success {
                callableSuccess(resultText)
            }
        }
    }
    
    func getNote(noteId: Int, inputId: String, success: ( (String?) -> () )? ) {
        queue.inDatabase { (database) -> Void in
            let resultText = self.getNoteInDatabase(database, noteId: noteId, inputId: inputId)
            
            if let callableSuccess = success {
                callableSuccess(resultText)
            }
        }
    }
    
    func updateNote(noteId: Int, inputId: String, value: String, success: ( () -> () )? ) {
        
        // If value is blank then do nothing
        if (value == "") {
            return
        }
        
        queue.inDatabase { (database) -> Void in
            
            // First check if there's an existing value
            let currentValue = self.getNoteInDatabase(database, noteId: noteId, inputId: inputId)
            
            // Write insert or update query depending on result
            var query = ""
            if (currentValue == nil) {
                query = "INSERT INTO Notes (value, noteId, inputId) VALUES (?, ?, ?);"
            } else {
                query = "UPDATE NOTES SET value = ? WHERE noteId = ? AND inputId = ?;"
            }
                
            database.executeUpdate(query, value, noteId, inputId)
            
            if let callableSuccess = success {
                callableSuccess()
            }
        }
    }
    
    func getNotes(noteId: Int, success: ( ([String : String]?) -> () )? ) {
        queue.inDatabase { (database) -> Void in
            let results = self.getNotesInDatabase(database, noteId: noteId)
            if let callableSuccess = success {
                if results.keys.count > 0 {
                    callableSuccess(results)
                } else {
                    callableSuccess(nil)
                }
            }
        }
    }
    
    // Return Object is a Dictionary of Key => NoteId, Value => Dictionary of itemsIds : values
    func getNotesToSync(success: ( [Int : [String : String]]? -> () )? ) {
        queue.inDatabase { (database) -> Void in
            var results = [Int : [String : String]]()
            if let result = database.executeQuery("SELECT DISTINCT noteId FROM Notes;") {
                // For each value
                while result.next() {
                    let noteId = Int(result.intForColumn("noteId"))

                    // Get Notes
                    let notes = self.getNotesInDatabase(database, noteId: noteId)
                    
                    // Filter out the blanks (this is bad data that crept in)
                    let filteredNoteArray = notes.filter( { $0.1 != "" } )
                    var filteredNotes = [String : String]()
                    for tuple in filteredNoteArray {
                        filteredNotes[tuple.0] = tuple.1
                    }
                    
                    if filteredNotes.keys.count > 0 {
                        results.updateValue(filteredNotes, forKey: noteId)
                    }
                }
                result.close()
                
                if let callableSuccess = success {
                    if results.keys.count > 0 {
                        callableSuccess(results)
                    } else {
                        callableSuccess(nil)
                    }
                }
            }
        }
    }
    
    func deleteNotes() {
        queue.inDatabase { (database) -> Void in
            database.executeUpdate("DELETE FROM Notes;")
        }
    }
    
    // Mark: Helper Methods
    private func getNoteInDatabase(database: FMDatabase, noteId: Int, inputId: String) -> String? {
        var resultText : String?
        
        if let result = database.executeQuery("SELECT * FROM Notes WHERE noteId = ? AND inputId = ?;", noteId, inputId) {
            if (result.next()) {
                resultText = result.stringForColumn("value")
            }
            result.close()
        }

        return resultText
    }
    
    private func getNotesInDatabase(database: FMDatabase, noteId: Int) -> [String : String] {
        var results = [String : String]()
        if let result = database.executeQuery("SELECT * FROM Notes WHERE noteId = ?;", noteId) {
            // For each value
            while result.next() {
                let noteValue = result.stringForColumn("value")
                let inputId = result.stringForColumn("inputId")
                results.updateValue(noteValue, forKey: inputId)
            }
        }
        
        return results
    }
}
