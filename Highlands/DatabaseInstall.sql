-- Create the Version table to store the database version
CREATE TABLE Version (versionId INTEGER PRIMARY KEY ASC, databaseVersion INT, description TEXT);

CREATE TABLE Test (testId INTEGER PRIMARY KEY ASC, someText TEXT);

CREATE TABLE Notes (id INTEGER PRIMARY KEY ASC, noteId INTEGER, inputId TEXT, value TEXT);

-- Seed any data

-- Update the Version
INSERT INTO Version (databaseVersion, description) VALUES (0.0, 'The initial install of the database.');