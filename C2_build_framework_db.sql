CREATE TABLE users (
   userId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    password VARCHAR(100)
);

CREATE TABLE userRatings (
    userId INT,
    tconst VARCHAR(10),
    rating DECIMAL(3, 1),
    ratingDate DATE,
    PRIMARY KEY (userId, tconst, rating),
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE userSearchHistory (
    userId INT,
    searchQuery TEXT,
    searchDate DATE,
		PRIMARY KEY (userId, searchQuery, searchDate),
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
);

CREATE TABLE userBookmarks (
    bookmarkId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT,
    tconst VARCHAR(20),
    nconst VARCHAR(20),
    note TEXT,
    bookmarkDate DATE,
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE
);