CREATE TABLE titleBasic (
    tconst VARCHAR(20) PRIMARY KEY,
    titleType VARCHAR(50),
    primaryType VARCHAR(50),
    originalTitle VARCHAR(255),
    isAdult BOOLEAN,
    startYear INT,
    endYear INT,
    runtimeMinutes INT,
    awards VARCHAR(255),
    plot TEXT,
    rated VARCHAR(50),
    releaseDate DATE,
    dvd DATE,
    productionCompany VARCHAR(255),
    poster VARCHAR(255),
    boxOffice VARCHAR(255),
    website VARCHAR(255)
);

CREATE TABLE nameBasic (
    nconst VARCHAR(20) PRIMARY KEY,
    primaryName VARCHAR(255),
    birthYear INT,
    deathYear INT
);

CREATE TABLE titleRatings (
    tconst VARCHAR(20) PRIMARY KEY,
    averageRating DECIMAL(2, 1),
    numVotes INT,
    rottenTomatoes INT,
    metaCritic INT,
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

--Potentially redundant table, can drop? 
CREATE TABLE titleAkas (
    tconst VARCHAR(20),
    ordering INT,
    title VARCHAR(255),
    region VARCHAR(50),
    language VARCHAR(50),
    types VARCHAR(100),
    attributes VARCHAR(100),
    isOriginalTitle BOOLEAN,
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleLanguage (
    tconst VARCHAR(20),
    language VARCHAR(50),
    PRIMARY KEY (tconst, language),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleEpisode (
    tconst VARCHAR(20),
    parenttconst VARCHAR(20),
    seasonNumber INT,
    episodeNumber INT,
    PRIMARY KEY (tconst),
    FOREIGN KEY (parenttconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCharacters (
    nconst VARCHAR(20),
    tconst VARCHAR(20),
    character VARCHAR(255),
    PRIMARY KEY (nconst, tconst, character),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCountry (
    tconst VARCHAR(20),
    country VARCHAR(50),
    PRIMARY KEY (tconst, country),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleGenre (
    tconst VARCHAR(20),
    genre VARCHAR(50),
    PRIMARY KEY (tconst, genre),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);


		--potentialy remove job here
CREATE TABLE titlePrincipals (
    tconst VARCHAR(20),
    ordering INT,
    nconst VARCHAR(20),
    category VARCHAR(50),
    job VARCHAR(50), 
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES name_basic(nconst) ON DELETE CASCADE
);


CREATE TABLE nameKnownfor (
    nconst VARCHAR(20),
    knownForTitles VARCHAR(255),
    PRIMARY KEY (nconst, knownForTitles),
    FOREIGN KEY (nconst) REFERENCES name_basic(nconst) ON DELETE CASCADE
);

CREATE TABLE nameProfession (
    nconst VARCHAR(20),
    profession VARCHAR(100),
    PRIMARY KEY (nconst, profession),
    FOREIGN KEY (nconst) REFERENCES name_basic(nconst) ON DELETE CASCADE
);

CREATE TABLE users (
    userId INT PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    password VARCHAR(100)
);

CREATE TABLE user_ratings (
    userId INT,
    ratingId INT,
    tconst VARCHAR(20),
    rating DECIMAL(2, 1),
    ratingDate DATE,
    PRIMARY KEY (userId, ratingId),
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);

CREATE TABLE search_history (
    historyId INT PRIMARY KEY,
    userId INT,
    searchQuery TEXT,
    searchDate DATE,
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
);

CREATE TABLE bookmarks (
    bookmarkId INT PRIMARY KEY,
    userId INT,
    tconst VARCHAR(20),
    nconst VARCHAR(20),
    note TEXT,
    bookmarkDate DATE,
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES name_basic(nconst) ON DELETE CASCADE
);

CREATE TABLE wi (
    tconst VARCHAR(20) PRIMARY KEY,
    word VARCHAR(100),
    field VARCHAR(100),
    lexeme TEXT,
    FOREIGN KEY (tconst) REFERENCES title_basic(tconst) ON DELETE CASCADE
);