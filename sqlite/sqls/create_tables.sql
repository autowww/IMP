-- Create Originals Table
CREATE TABLE IF NOT EXISTS Originals (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    FilePath TEXT UNIQUE NOT NULL
);

-- Create Proxies Table
CREATE TABLE IF NOT EXISTS Proxies (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    OriginalID INTEGER NOT NULL,
    FilePath TEXT UNIQUE NOT NULL,
    FOREIGN KEY (OriginalID) REFERENCES Originals(ID) ON DELETE CASCADE
);

-- Indexes for Faster Queries
CREATE INDEX IF NOT EXISTS idx_originals_filepath ON Originals(FilePath);
CREATE INDEX IF NOT EXISTS idx_proxies_originalid ON Proxies(OriginalID);
CREATE INDEX IF NOT EXISTS idx_proxies_filepath ON Proxies(FilePath);
