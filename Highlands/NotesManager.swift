//
//  NotesManager.swift
//  Highlands
//
//  Created by Raiden Honda on 2/5/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

// For performing data operations on Notes
public class NotesManager {
 
    // Mark: Sync Notes
    static func syncNotes() {
        // This method simply pushes notes from the device to the cloud (a lot of complicated code for something so simple)
        
        
        // If there's no user id then return
        if (!Globals.userIsSignedIn) {
            return
        }
        
        // Create semaphore to await results
        var sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        // First get notes to sync
        var results : [Int : [String : String]]?
        DataManager.sharedInstance.getNotesToSync { (dbResults) -> () in
            results = dbResults
            dispatch_semaphore_signal(sema)
        }
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
        
        // If there are no results, then don't call the API
        if results == nil { return; }
        
        // Need to create an object to track the syncing success
        var syncStatus = [Int : Bool]()
        
        // Re-up the semaphore to await results
        sema = dispatch_semaphore_create(0)
        
        // Push to cloud each set of notes
        for noteId in results!.keys {
            let notes = results![noteId]
            
            // We need to mock the form data accepted by the endpoint
            var noteParams = [String : String]()
            for key in notes!.keys {
                let value = notes![key]
                let inputId = "blanks[\(key)]"
                if let valueStr = value {
                    noteParams[inputId] = valueStr
                }
            }
            
            // Set the authorization header value
            let headerDict = [
                "Authorization" : "Token token=7da26a26129eb469f1f0b8f5728bdd98",
                "Content-Type" : "application/x-www-form-urlencoded"
            ]
            
            // NOTE the noteId is in the URL
            let notePostUrl = "https://notes.highlandsapp.com/api/v2/notes/\(noteId)/update_user/\(Globals.currentUserF1Id!)"
            
            print("Note posted to \(notePostUrl)")
            
            // Send the request
            request(.POST, notePostUrl, parameters: noteParams, headers: headerDict)
                .responseJSON { request, response, data in
                    if response!.statusCode == 200 {
                        print("Notes synced!")
                        syncStatus[noteId] = true
                        
                        for key in noteParams.keys {
                            let value = noteParams[key] as String!
                            print("\(key) -> \(value)")
                        }
                    } else {
                        print("There was a problem syncing notes")
                        print("Response code is \(response!.statusCode)")
                        
                        for key in noteParams.keys {
                            let value = noteParams[key]
                            print("\(key) -> \(value)")
                        }
                        
                        syncStatus[noteId] = false
                    }
                    
                    // If last call, release semaphore
                    if (syncStatus.keys.count == results!.keys.count) {
                        dispatch_semaphore_signal(sema)
                    }
            }
        }
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
        
        // If the sync was successful clear notes from the db
        let filteredStatus = syncStatus.filter { $0.1 == false }
        if (filteredStatus.count == 0) {
            DataManager.sharedInstance.deleteNotes()
        }
    }
    
    static func syncNotesAsync() {
        // Setting up background thread
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.syncNotes()
        }) // End dispatch background queue
    }
    
    // Mark: Get Notes
    static func getNotes(noteId : Int, completionHandler: ( () -> () )? )  {
        // Set the authorization header value
        let headerDict = [ "Authorization" : "Token token=7da26a26129eb469f1f0b8f5728bdd98" ]
        
        // NOTE the noteId is in the URL
        let noteGetUrl = "https://notes.highlandsapp.com/api/v2/notes/\(noteId)/blanks/\(Globals.currentUserF1Id!)"
        
        print("Fetch notes url is \(noteGetUrl)")
        
        // Send the request
        request(.GET, noteGetUrl, parameters: nil, headers: headerDict)
            .responseJSON { request, response, result in
                // The key is inputId and value is value
                if let data = result.value as? [String: String] {
                    // Iterate and save keys/values in database
                    for key in data.keys {
                        DataManager.sharedInstance.updateNote(noteId, inputId: key, value: data[key]!, success: nil)
                    }
                }
                
                // Execute completion
                if let callableCompletion = completionHandler {
                    callableCompletion()
                }
        }
    }
    
    // Mark: Email Notes
    static func emailNotes(noteId : Int, emailAddress : String) {
        // Get fields and use callback to send to API
        DataManager.sharedInstance.getNotes(noteId) { (results) -> () in
            
            // If there are no results, then don't call the API
            if let resultDict = results {
                
                // Create the request object
                let parameters : [String : AnyObject] = [
                    "email": emailAddress,
                    "blanks": resultDict
                ]
                
                // Set the authorization header value
                let headerDict = [ "Authorization" : "Token token=7da26a26129eb469f1f0b8f5728bdd98" ]
                
                // NOTE the noteId is in the URL
                let notePostUrl = "https://notes.highlandsapp.com/api/v2/notes/\(noteId)/email_notes"
                
                // Send the request
                request(.POST, notePostUrl, parameters: parameters, headers: headerDict, encoding: .JSON)
                    .response(completionHandler: { (_, response, _, _) -> Void in
                        if response!.statusCode == 200 {
                            print("Notes emailed!")
                        } else {
                            print("There was a problem emailing notes")
                        }
                    })
            }
        }
    }
}
