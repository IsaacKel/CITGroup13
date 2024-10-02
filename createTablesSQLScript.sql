CREATE TABLE titleBasic (
    tconst VARCHAR(20) PRIMARY KEY,
    titleType VARCHAR(256),
    primaryTitle VARCHAR(256),
    originalTitle VARCHAR(255),
    isAdult BOOLEAN,
    startYear CHAR(4),
    endYear CHAR(4),
    runtimeMinutes INT,
    awards VARCHAR(255),
    plot TEXT,
    rated VARCHAR(50),
    releaseDate VARCHAR(80),
    dvd VARCHAR(80),
    productionCompany VARCHAR(255),
    poster VARCHAR(255),
    boxOffice VARCHAR(255),
    website VARCHAR(255)
);

CREATE TABLE nameBasic (
    nconst VARCHAR(20) PRIMARY KEY,
    primaryName VARCHAR(255),
    birthYear CHAR(4),
    deathYear CHAR(4)
);

CREATE TABLE titleRatings (
    tconst VARCHAR(20) PRIMARY KEY,
    averageRating DECIMAL(3, 1),
    numVotes INT,
    rottenTomatoes INT,
    metaCritic INT,
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
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
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleLanguage (
    tconst VARCHAR(20),
    language VARCHAR(256),
    PRIMARY KEY (tconst, language),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleEpisode (
    tconst VARCHAR(20),
    parenttconst VARCHAR(20),
    seasonNumber INT,
    episodeNumber INT,
    PRIMARY KEY (tconst),
    FOREIGN KEY (parenttconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCharacters (
    nconst VARCHAR(20),
    tconst VARCHAR(20),
    character VARCHAR(500),
		ordering INT,
    PRIMARY KEY (nconst, tconst, character, ordering),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCountry (
    tconst VARCHAR(20),
    country VARCHAR(256),
    PRIMARY KEY (tconst, country),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleGenre (
    tconst VARCHAR(20),
    genre VARCHAR(50),
    PRIMARY KEY (tconst, genre),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);


		--potentialy remove job here
CREATE TABLE titlePrincipals (
    tconst VARCHAR(20),
    ordering INT,
    nconst VARCHAR(20),
    category VARCHAR(50),
    job VARCHAR, 
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE
);


CREATE TABLE nameKnownFor (
    nconst VARCHAR(20),
    knownForTitles VARCHAR(255),
    PRIMARY KEY (nconst, knownForTitles),
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE,
    FOREIGN KEY (knownForTitles) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE nameProfession (
    nconst VARCHAR(20),
    profession VARCHAR(100),
    PRIMARY KEY (nconst, profession),
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE
);

CREATE TABLE users (
   userId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50),
    email VARCHAR(100),
    password VARCHAR(100)
);

CREATE TABLE userRatings (
    userId INT,
    ratingId INT,
    tconst VARCHAR(20),
    rating DECIMAL(2, 1),
    ratingDate DATE,
    PRIMARY KEY (userId, ratingId),
    FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE,
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE userSearchHistory (
    historyId INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    userId INT,
    searchQuery TEXT,
    searchDate DATE,
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

-- Insert data into titleBasic from IMDb's title_basics
INSERT INTO titleBasic (tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes)
SELECT 
    tconst,
    titleType,
    primaryTitle,
    originalTitle,
    isAdult,
    startYear,
    endYear,
    runtimeMinutes
FROM title_basics;


-- Insert data into titleBasic from omdb_data table
INSERT INTO titleBasic (
    tconst, awards, plot, rated, releaseDate, dvd, 
    productioncompany, poster, boxOffice, website
)
SELECT 
    tconst, 
    awards, 
    plot, 
    rated, 
    released,
    dvd, 
    production, 
    poster, 
    boxOffice, 
    website
FROM omdb_data
ON CONFLICT (tconst) 
DO UPDATE 
SET 
    awards = COALESCE(EXCLUDED.awards, titleBasic.awards),
    plot = COALESCE(EXCLUDED.plot, titleBasic.plot),
    rated = COALESCE(EXCLUDED.rated, titleBasic.rated),
    releaseDate = COALESCE(EXCLUDED.releaseDate, titleBasic.releaseDate),
    dvd = COALESCE(EXCLUDED.dvd, titleBasic.dvd),
    productionCompany = COALESCE(EXCLUDED.productionCompany, titleBasic.productionCompany),
    poster = COALESCE(EXCLUDED.poster, titleBasic.poster),
    boxOffice = COALESCE(EXCLUDED.boxOffice, titleBasic.boxOffice),
    website = COALESCE(EXCLUDED.website, titleBasic.website);

-- Insert data into nameBasic from IMDb's name_basics
INSERT INTO nameBasic (nconst, primaryName, birthYear, deathYear)
SELECT 
    nconst,
    primaryName,
    birthYear,
    deathYear
FROM name_basics;

-- Insert data into titleRatings from IMDb's title_ratings
INSERT INTO titleRatings (tconst, averageRating, numVotes)
SELECT 
    tconst,
    averageRating,
    numVotes
FROM title_ratings;

-- Insert data into titleAkas from IMDb's title_akas
INSERT INTO titleAkas (tconst, ordering, title, region, language, types, attributes, isOriginalTitle)
SELECT 
    titleId AS tconst,
    ordering,
    title,
    region,
    language,
    types,
    attributes,
    isOriginalTitle
FROM title_akas;

-- Insert data into titleGenre by splitting genres from IMDb's title_basics
INSERT INTO titleGenre (tconst, genre)
SELECT 
    tconst,
    UNNEST(STRING_TO_ARRAY(genres, ',')) AS genre  -- Split genres by comma
FROM title_basics;

-- Insert data into titlePrincipals from IMDb's title_principals
INSERT INTO titlePrincipals (tconst, ordering, nconst, category, job)
SELECT 
    tconst,
    ordering,
    nconst,
    category,
    job
FROM title_principals;

-- Insert data into titleCharacters from IMDb's title_principals
INSERT INTO titleCharacters (nconst, tconst, character, ordering)
SELECT 
    nconst,
    tconst,
    REPLACE(REPLACE(REPLACE(characters, '[', ''), ']', ''), '''', '') AS cleaned_characters,
    ordering
FROM title_principals
WHERE characters IS NOT NULL
AND characters != ''
AND category ='actor';

-- Insert data into nameKnownFor from IMDb's name_basics, ensuring only valid titles
INSERT INTO nameKnownFor (nconst, knownForTitles)
SELECT 
    nb.nconst,
    knownForTitles
FROM (
    SELECT 
        nconst,
        UNNEST(STRING_TO_ARRAY(knownForTitles, ',')) AS knownForTitles
    FROM name_basics
) AS nb
JOIN titleBasic tb ON nb.knownForTitles = tb.tconst; 

-- Insert data into nameProfession while ignoring duplicates
INSERT INTO nameProfession (nconst, profession)
SELECT DISTINCT nconst, category AS profession
FROM title_principals
ON CONFLICT (nconst, profession) DO NOTHING;

-- Instert data into titleEpisde from IMDb's title_episode
INSERT INTO titleEpisode(tconst, parenttconst, seasonnumber, episodenumber) 
SELECT 
	tconst, 
	parenttconst, 
	seasonnumber, 
	episodenumber
FROM title_episode; 

--Insert data into titleCountry from omdb_data table
INSERT INTO titleCountry(tconst, country) 
SELECT 
	tconst, 
	country
FROM omdb_data;

--Insert data into titleLanguage from omdb_data table
INSERT INTO titlelanguage(tconst, language) 
SELECT 
	tconst, 
	language
FROM omdb_data;

-- Alter wi table to ensure foreign key constraints and same type as tconst in titleBasic
ALTER TABLE wi 
ALTER COLUMN tconst TYPE VARCHAR(20);
-- Add the foreign key constraint
ALTER TABLE wi
ADD CONSTRAINT fk_tconst_titleBasic
FOREIGN KEY (tconst) REFERENCES titleBasic(tconst)
ON DELETE CASCADE;

--Drop original tables
-- DROP TABLE
-- title_basics, name_basics, title_akas, title_crew, title_episode, title_principals, title_ratings;
