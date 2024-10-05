CREATE TABLE titleBasic (
    tconst VARCHAR(10) PRIMARY KEY,
    titleType VARCHAR(256),
    primaryTitle VARCHAR(256),
    originalTitle VARCHAR(256),
    isAdult BOOLEAN,
    startYear CHAR(4),
    endYear CHAR(4),
    runtimeMinutes INT,
    awards VARCHAR(256),
    plot TEXT,
    rated VARCHAR(50),
    releaseDate VARCHAR(80),
    dvd VARCHAR(80),
    productionCompany VARCHAR(256),
    poster VARCHAR(256),
    boxOffice VARCHAR(256),
    website VARCHAR(256)
);

CREATE TABLE nameBasic (
    nconst VARCHAR(10) PRIMARY KEY,
    primaryName VARCHAR(256),
    birthYear CHAR(4),
    deathYear CHAR(4)
);

CREATE TABLE titleRatings (
    tconst VARCHAR(10) PRIMARY KEY,
    averageRating DECIMAL(3, 1),
    numVotes INT,
    rottenTomatoes INT,
    metaCritic INT,
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleAkas (
    tconst VARCHAR(10),
    ordering INT,
    title VARCHAR(256),
    region VARCHAR(50),
    language VARCHAR(50),
    types VARCHAR(100),
    attributes VARCHAR(100),
    isOriginalTitle BOOLEAN,
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleLanguage (
    tconst VARCHAR(10),
    language VARCHAR(256),
    PRIMARY KEY (tconst, language),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleEpisode (
    tconst VARCHAR(10),
    parenttconst VARCHAR(10),
    seasonNumber INT,
    episodeNumber INT,
    PRIMARY KEY (tconst),
    FOREIGN KEY (parenttconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE,
		FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCharacters (
    nconst VARCHAR(10),
    tconst VARCHAR(10),
    character VARCHAR(500),
		ordering INT,
    PRIMARY KEY (nconst, tconst, character, ordering),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleCountry (
    tconst VARCHAR(10),
    country VARCHAR(256),
    PRIMARY KEY (tconst, country),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titleGenre (
    tconst VARCHAR(10),
    genre VARCHAR(50),
    PRIMARY KEY (tconst, genre),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

CREATE TABLE titlePrincipals (
    tconst VARCHAR(10),
    ordering INT,
    nconst VARCHAR(10),
    category VARCHAR(50),
    job VARCHAR, 
    PRIMARY KEY (tconst, ordering),
    FOREIGN KEY (tconst) REFERENCES titleBasic(tconst) ON DELETE CASCADE,
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE
);

CREATE TABLE nameKnownFor (
    nconst VARCHAR(10),
    knownForTitles VARCHAR(256),
    PRIMARY KEY (nconst, knownForTitles),
    FOREIGN KEY (nconst) REFERENCES nameBasic(nconst) ON DELETE CASCADE,
    FOREIGN KEY (knownForTitles) REFERENCES titleBasic(tconst) ON DELETE CASCADE
);

-- Insert data into titleBasic from IMDb's title_basics
INSERT INTO titleBasic (tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes)
SELECT 
    tconst,
    NULLIF(NULLIF(titleType, 'N/A'), ''),
    NULLIF(NULLIF(primaryTitle, 'N/A'), ''),
    NULLIF(NULLIF(originalTitle, 'N/A'), ''),
    isAdult,
    NULLIF(NULLIF(startYear, 'N/A'), ''),
    NULLIF(NULLIF(endYear, 'N/A'), ''),
    runtimeMinutes
FROM title_basics;

-- Insert data into titleBasic from omdb_data table
INSERT INTO titleBasic (
    tconst, awards, plot, rated, releaseDate, dvd, 
    productioncompany, poster, boxOffice, website
)
SELECT 
    tconst, 
    NULLIF(NULLIF(awards, 'N/A'), ''),
    NULLIF(NULLIF(plot, 'N/A'), ''),
    NULLIF(NULLIF(rated, 'N/A'), ''),
    NULLIF(NULLIF(released, 'N/A'), ''),
    NULLIF(NULLIF(dvd, 'N/A'), ''),
    NULLIF(NULLIF(production, 'N/A'), ''),
    NULLIF(NULLIF(poster, 'N/A'), ''),
    NULLIF(NULLIF(boxOffice, 'N/A'), ''),
    NULLIF(NULLIF(website, 'N/A'), '')
FROM omdb_data
ON CONFLICT (tconst) 
DO UPDATE 
SET 
    awards = COALESCE(NULLIF(NULLIF(EXCLUDED.awards, 'N/A'), ''), titleBasic.awards),
    plot = COALESCE(NULLIF(NULLIF(EXCLUDED.plot, 'N/A'), ''), titleBasic.plot),
    rated = COALESCE(NULLIF(NULLIF(EXCLUDED.rated, 'N/A'), ''), titleBasic.rated),
    releaseDate = COALESCE(NULLIF(NULLIF(EXCLUDED.releaseDate, 'N/A'), ''), titleBasic.releaseDate),
    dvd = COALESCE(NULLIF(NULLIF(EXCLUDED.dvd, 'N/A'), ''), titleBasic.dvd),
    productionCompany = COALESCE(NULLIF(NULLIF(EXCLUDED.productionCompany, 'N/A'), ''), titleBasic.productionCompany),
    poster = COALESCE(NULLIF(NULLIF(EXCLUDED.poster, 'N/A'), ''), titleBasic.poster),
    boxOffice = COALESCE(NULLIF(NULLIF(EXCLUDED.boxOffice, 'N/A'), ''), titleBasic.boxOffice),
    website = COALESCE(NULLIF(NULLIF(EXCLUDED.website, 'N/A'), ''), titleBasic.website);

-- Insert data into nameBasic from IMDb's name_basics
INSERT INTO nameBasic (nconst, primaryName, birthYear, deathYear)
SELECT 
    nconst,
    NULLIF(NULLIF(primaryName, 'N/A'), ''),
    NULLIF(NULLIF(birthYear, 'N/A'), ''),
    NULLIF(NULLIF(deathYear, 'N/A'), '')
FROM name_basics;

-- Insert data into titleRatings from IMDb's title_ratings
INSERT INTO titleRatings (tconst, averageRating, numVotes)
SELECT 
    tconst,
    averageRating,
    numVotes
FROM title_ratings;

-- Insert data into titleRatings from omdb_data table with Rotten Tomatoes and Metacritic ratings
WITH RatingsExtract AS (
    SELECT 
        od.tconst,
        -- Extract Rotten Tomatoes rating
        CAST(
            TRIM(BOTH '%' FROM (
                SELECT rating ->> 'Value'
                FROM jsonb_array_elements(od.ratings::jsonb) AS rating
                WHERE rating ->> 'Source' = 'Rotten Tomatoes'
                LIMIT 1
            )) AS INT
        ) AS rottenTomatoes,
        -- Extract Metacritic rating
        CAST(
            SPLIT_PART(
                (
                    SELECT rating ->> 'Value'
                    FROM jsonb_array_elements(od.ratings::jsonb) AS rating
                    WHERE rating ->> 'Source' = 'Metacritic'
                    LIMIT 1
                ), '/', 1
            ) AS INT
        ) AS metaCritic
    FROM omdb_data od
)
-- Update titleRatings table with the extracted ratings from omdb_data
UPDATE titleRatings tr
SET 
    rottenTomatoes = COALESCE(re.rottenTomatoes, tr.rottenTomatoes), -- Update only if new value is found
    metaCritic = COALESCE(re.metaCritic, tr.metaCritic)              -- Update only if new value is found
FROM RatingsExtract re
WHERE tr.tconst = re.tconst;

-- Insert data into titleAkas from IMDb's title_akas
INSERT INTO titleAkas (tconst, ordering, title, region, language, types, attributes, isOriginalTitle)
SELECT 
    titleId AS tconst,
    ordering,
    NULLIF(NULLIF(title, 'N/A'), ''),
    NULLIF(NULLIF(region, 'N/A'), ''),
    NULLIF(NULLIF(language, 'N/A'), ''),
    NULLIF(NULLIF(types, 'N/A'), ''),
    NULLIF(NULLIF(attributes, 'N/A'), ''),
    isOriginalTitle
FROM title_akas;

-- Insert data into titleGenre by splitting genres from IMDb's title_basics
INSERT INTO titleGenre (tconst, genre)
SELECT 
    tconst,
    TRIM(NULLIF(NULLIF(UNNEST(STRING_TO_ARRAY(genres, ',')), 'N/A'), ''))
FROM title_basics;

-- Insert data into titlePrincipals from IMDb's title_principals
INSERT INTO titlePrincipals (tconst, ordering, nconst, category, job)
SELECT 
    tconst,
    ordering,
    nconst,
    NULLIF(NULLIF(category, 'N/A'), ''),
    NULLIF(NULLIF(job, 'N/A'), '')
FROM title_principals;

-- Insert data into titleCharacters from IMDb's title_principals
INSERT INTO titleCharacters (nconst, tconst, character, ordering)
SELECT 
    nconst,
    tconst,
    REPLACE(REPLACE(REPLACE(NULLIF(NULLIF(characters, 'N/A'), ''), '[', ''), ']', ''), '''', '') AS cleaned_characters,
    ordering
FROM title_principals
WHERE characters IS NOT NULL
AND characters != ''
AND category = 'actor';

-- Insert data into nameKnownFor from IMDb's name_basics, ensuring only valid titles that are included in our database
INSERT INTO nameKnownFor (nconst, knownForTitles)
SELECT 
    nb.nconst,
    nb.knownForTitles
FROM (
    SELECT 
        nconst,
        TRIM(NULLIF(NULLIF(UNNEST(STRING_TO_ARRAY(NULLIF(knownForTitles, 'N/A'), ',')), ''), '')) AS knownForTitles
    FROM name_basics
) AS nb
JOIN titleBasic tb ON nb.knownForTitles = tb.tconst;

-- Insert data into titleEpisode from IMDb's title_episode
INSERT INTO titleEpisode(tconst, parenttconst, seasonnumber, episodenumber) 
SELECT 
    tconst, 
    parenttconst, 
    seasonnumber, 
    episodenumber
FROM title_episode; 

-- Insert data into titleCountry from omdb_data table
INSERT INTO titleCountry(tconst, country) 
SELECT 
    tconst, 
    TRIM(NULLIF(NULLIF(UNNEST(STRING_TO_ARRAY(NULLIF(country, 'N/A'), ',')), ''), ''))
FROM omdb_data;

-- Insert data into titleLanguage from omdb_data table, ignoring duplicates
INSERT INTO titleLanguage(tconst, language) 
SELECT 
    tconst, 
    TRIM(NULLIF(NULLIF(UNNEST(STRING_TO_ARRAY(NULLIF(language, 'N/A'), ',')), ''), ''))
FROM omdb_data
ON CONFLICT (tconst, language) DO NOTHING;

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