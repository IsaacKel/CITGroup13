CREATE OR REPLACE FUNCTION "public"."add_user"("p_username" varchar, "p_email" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
    INSERT INTO users (username, email) 
    VALUES (p_username, p_email);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  
  CREATE OR REPLACE FUNCTION "public"."bookmark_movie"("p_userid" int4, "p_tconst" varchar)
  RETURNS "pg_catalog"."void" AS
$BODY$
BEGIN
    -- Check if the bookmark already exists
    IF NOT EXISTS (
        SELECT 1
        FROM userbookmarks
        WHERE userid = p_userid AND tconst = p_tconst
    ) THEN
        -- If not exists, insert the new bookmark
        INSERT INTO userbookmarks (userid, tconst)
        VALUES (p_userid, p_tconst);
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE OR REPLACE FUNCTION "public"."bookmark_name"("p_userid" int4, "p_nconst" varchar)
  RETURNS "pg_catalog"."void" AS
$BODY$
BEGIN
    -- Check if the bookmark for the name already exists
    IF NOT EXISTS (
        SELECT 1
        FROM userbookmarks
        WHERE userid = p_userid AND nconst = p_nconst
    ) THEN
        -- If not exists, insert the new bookmark
        INSERT INTO userbookmarks (userid, nconst)
        VALUES (p_userid, p_nconst);
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  CREATE OR REPLACE FUNCTION "public"."get_bookmarks"("p_userid" int4)
RETURNS TABLE(bookmark_type VARCHAR, id VARCHAR, name_or_title VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    -- Fetch bookmarked movies
    SELECT 
        'title'::VARCHAR AS bookmark_type,  -- Indicate this is a title bookmark, cast to VARCHAR
        b.tconst::VARCHAR AS id,            -- Return the tconst (movie/series ID), cast to VARCHAR
        tb.primarytitle::VARCHAR AS name_or_title  -- Return the movie/series title, cast to VARCHAR
    FROM 
        userbookmarks b
    JOIN 
        titlebasic tb ON b.tconst = tb.tconst
    WHERE 
        b.userid = p_userid

    UNION ALL

    -- Fetch bookmarked actors/directors
    SELECT 
        'name'::VARCHAR AS bookmark_type,   -- Indicate this is a name bookmark, cast to VARCHAR
        b.nconst::VARCHAR AS id,            -- Return the nconst (name ID), cast to VARCHAR
        nb.primaryname::VARCHAR AS name_or_title  -- Return the person's name, cast to VARCHAR
    FROM 
        userbookmarks b
    JOIN 
        namebasic nb ON b.nconst = nb.nconst
    WHERE 
        b.userid = p_userid;
END;
$$ LANGUAGE plpgsql VOLATILE
COST 100
ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."string_search"("p_search_string" varchar)
  RETURNS TABLE("tconst" varchar, "title" varchar) AS $BODY$
BEGIN
    RETURN QUERY 
    SELECT tb.tconst::VARCHAR, tb.primarytitle::VARCHAR
    FROM titlebasic tb
    WHERE tb.primarytitle ILIKE '%' || p_search_string || '%' 
       OR tb.tconst IN (
           SELECT tb.tconst 
           FROM titlebasic tb
           WHERE tb.plot ILIKE '%' || p_search_string || '%'
       )
    ORDER BY 
       -- Exact matches first
       CASE 
           WHEN tb.primarytitle ILIKE p_search_string THEN 1
           ELSE 2
       END, 
       -- Then sort by closest partial matches
       tb.primarytitle;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
  
  
  CREATE OR REPLACE FUNCTION "public"."string_search"("p_search_string" varchar, "p_userid" int4)
  RETURNS TABLE("tconst" varchar, "title" varchar) AS $BODY$
BEGIN
    -- Log the search history for the user
    PERFORM update_search_history(p_userid, p_search_string);

    -- Perform the search with prioritization of exact matches
    RETURN QUERY 
    SELECT tb.tconst::VARCHAR, tb.primarytitle::VARCHAR
    FROM titlebasic tb
    WHERE tb.primarytitle ILIKE '%' || p_search_string || '%' 
       OR tb.tconst IN (
           SELECT tb.tconst 
           FROM titlebasic tb
           WHERE tb.plot ILIKE '%' || p_search_string || '%'
       )
    ORDER BY 
       -- Exact matches first
       CASE 
           WHEN tb.primarytitle ILIKE p_search_string THEN 1
           ELSE 2
       END, 
       -- Then sort by closest partial matches
       tb.primarytitle;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
  
  CREATE OR REPLACE FUNCTION "public"."update_search_history"("p_userid" int4, "p_search_string" varchar)
  RETURNS "pg_catalog"."void" AS
$BODY$
BEGIN
    -- Check if the search query already exists for the user
    IF NOT EXISTS (
        SELECT 1
        FROM userSearchHistory
        WHERE userId = p_userid AND searchQuery = p_search_string
    ) THEN
        -- If not exists, insert the new search query
        INSERT INTO userSearchHistory (userId, searchQuery, searchDate)
        VALUES (p_userid, p_search_string, CURRENT_DATE);
    END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  create or replace PROCEDURE rate(titleId VARCHAR(10), _rating int4, _userId int4)
LANGUAGE plpgsql as $$
declare oldRating int;
oldnumvotes int;
oldaveragerating numeric(3,1);
BEGIN

if _rating between 1 and 10 then
  select numvotes from titleratings tr where tr.tconst = titleId into oldnumvotes;
  select averagerating from titleratings tr where tr.tconst = titleId into oldaveragerating;
  if exists (select 1 from userratings ur where ur.tconst = titleId and ur.userid = _userId) THEN
    --update existing rating
    --update userratings (get old value)
    select rating from userratings ur where ur.tconst = titleId and ur.userid = _userId into oldRating;
    update userratings set rating = _rating, ratingdate = CURRENT_DATE where userid = _userId and tconst = titleId;
    --update titleratings (needs old value)
    update titleratings set averagerating = (COALESCE(oldnumvotes,0)*COALESCE(oldaveragerating,0)-oldRating + _rating)/COALESCE(oldnumvotes,1) where tconst = titleId;
  ELSE
    --new rating
    --insert into userratings
    insert into userratings(userid, tconst, rating, ratingdate)
    values (_userId, titleId, _rating, CURRENT_DATE);
    --update titleratings
    update titleratings set numvotes = numvotes + 1,
    averagerating = (COALESCE(oldnumvotes,0)*COALESCE( oldaveragerating,0) + _rating)/(COALESCE(oldnumvotes)+1) where tconst = titleId;
  end if;
    --update nrating in namebasic
    update namebasic set nrating = (select round(sum(tr.averagerating*tr.numvotes)/sum(tr.numvotes),1) from titleprincipals tp inner join titleratings tr on tp.tconst = tr.tconst where namebasic.nconst = tp.nconst) where namebasic.nconst in (select nconst from titleprincipals where tconst = titleId);
else
  raise notice 'Input value must be between 1 and 10';
end if;
END;
$$;


CREATE OR REPLACE FUNCTION "public"."structured_string_search"("p_title" varchar, "p_plot" varchar, "p_characters" varchar, "p_names" varchar)
  RETURNS TABLE("tconst" text, "title" text) AS $BODY$
BEGIN
    RETURN QUERY 
    SELECT tb.tconst::TEXT, tb.primarytitle::TEXT
    FROM titlebasic tb
    JOIN titlecharacters tp ON tb.tconst = tp.tconst
    JOIN namebasic nb ON tp.nconst = nb.nconst
    WHERE tb.primarytitle ILIKE '%' || p_title || '%'
      AND tb.plot ILIKE '%' || p_plot || '%'
      AND tp.character ILIKE '%' || p_characters || '%'
      AND nb.primaryname ILIKE '%' || p_names || '%';
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION search_names_by_text(search_text VARCHAR)
RETURNS TABLE (
    nconst VARCHAR(10),
    primaryName VARCHAR(256),
    birthYear CHAR(4),
    deathYear CHAR(4)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        nb.nconst,        -- Qualify nconst with the table alias
        nb.primaryName,   -- Qualify primaryName with the table alias
        nb.birthYear, 
        nb.deathYear
    FROM 
        nameBasic nb      -- Use an alias for the table
    WHERE 
        nb.primaryName ILIKE '%' || search_text || '%';  -- Case-insensitive search
END;
$$ LANGUAGE plpgsql;


create or replace function coPlayers(testId varCHAR (10)) RETURNS TABLE (nconst varCHAR(10), primaryname VARCHAR(256), frequency BIGINT)
LANGUAGE plpgsql as $$
BEGIN

return query
SELECT tp.nconst, nb.primaryname, count(tp.tconst) as freq from titleprincipals tp JOIN namebasic nb on tp.nconst = nb.nconst where tp.tconst in (select tconst from titleprincipals where titleprincipals.nconst = testId) and (tp.category = 'actor' or tp.category = 'actress') and nb.nconst != testId group by tp.nconst, nb.primaryname order by freq desc;

END;
$$;

ALTER TABLE namebasic ADD IF NOT EXISTS nRating NUMERIC (5,1);
CREATE INDEX IF NOT EXISTS index_tp_nconst ON titleprincipals (nconst);
UPDATE namebasic
SET nRating=(
SELECT round(SUM (tr.averagerating*tr.numvotes)/SUM (tr.numvotes),1) FROM titleprincipals tp INNER JOIN titleratings tr ON tp.tconst=tr.tconst WHERE namebasic.nconst=tp.nconst);
CREATE INDEX IF NOT EXISTS index_tp_category ON titleprincipals (category);
CREATE INDEX IF NOT EXISTS index_nb_nrating ON namebasic (nrating);
CREATE INDEX IF NOT EXISTS index_tr_numvotes ON titleratings (numvotes);
CREATE INDEX IF NOT EXISTS index_tp_tconst ON titleprincipals (tconst);
CREATE INDEX IF NOT EXISTS index_tb_primarytitle ON titlebasic (primarytitle);
CREATE INDEX IF NOT EXISTS index_tl_languages ON titlelanguage (language);
CREATE INDEX IF NOT EXISTS index_tg_genre ON titlegenre (genre);

create or replace function ratingActors(testId VARCHAR(10)) returns table (nconst VARCHAR(10), nRating numeric(5,1))
LANGUAGE plpgsql as $$
BEGIN

return query
select nb.nconst, nb.nRating from (select tp.nconst from titleprincipals tp where tp.tconst = testId and (category = 'actor' or category = 'actress')) as tp_alias
natural join namebasic nb order by nb.nRating DESC;

END;
$$;

create or replace function ratingCoPlayers(testId VARCHAR (10)) RETURNS TABLE (nconst VARCHAR(10), primaryname VARCHAR(256), nRating numeric(5,1))
LANGUAGE plpgsql as $$
BEGIN

return query
SELECT DISTINCT tp.nconst, nb.primaryname, nb.nRating from titleprincipals tp natural JOIN namebasic nb where tp.tconst in (select tconst from titleprincipals where titleprincipals.nconst = testId) and (tp.category = 'actor' or tp.category = 'actress') and nb.nconst != testId order by nrating desc nulls last;

END;
$$;

create or replace function ratingCrew(testId VARCHAR(10)) returns table (nconst VARCHAR(10), nRating numeric(5,1))
LANGUAGE plpgsql as $$
BEGIN

return query
select nb.nconst, nb.nRating from (select tp.nconst from titleprincipals tp where tp.tconst = testId and category != 'actor' and category != 'actress') as tp_alias
natural join namebasic nb order by nb.nRating DESC;

END;
$$;

create or replace function similarMovies(testId VARCHAR(10)) returns table (tconst VARCHAR(10), primarytitle VARCHAR(256), numvotes int4)
LANGUAGE plpgsql as $$
BEGIN

return query
select DISTINCT tb.tconst, tb.primarytitle, tr.numvotes from titlebasic tb 
natural join titlegenre tg 
natural join titlelanguage tl 
natural join titleratings tr 
where tg.genre in (select tg.genre from titlegenre tg where tg.tconst = testId) 
and tl.language in (select language from titlelanguage tl where tl.tconst = testId) 
order by tr.numvotes DESC limit 10;

END;
$$;

CREATE OR REPLACE FUNCTION person_words(
    p_primaryname VARCHAR,     -- The name of the person we're interested in
    p_limit INTEGER DEFAULT 10 -- Limit on the number of words returned (default 10)
) 
RETURNS TABLE (
    word VARCHAR,              -- The word associated with the person
    frequency INTEGER,         -- Frequency of the word in titles the person is involved in
    category VARCHAR           -- The field category (t = title, p = plot, c = characters)
) AS $$
BEGIN
    RETURN QUERY
    WITH PersonTitles AS (
        -- Step 1: Retrieve all titles (tconst) the person is associated with from the titlePrincipals table
        SELECT DISTINCT tp.tconst
        FROM titlePrincipals tp
        JOIN namebasic nb ON tp.nconst = nb.nconst
        WHERE LOWER(nb.primaryname) = LOWER(p_primaryname) -- Match the person's name (case-insensitive)
    ),
    
    WordsFromTitles AS (
        -- Step 2: Retrieve words associated with these titles from the wi table
        SELECT wi.word AS word, wi.field AS category
        FROM wi
        JOIN PersonTitles pt ON wi.tconst = pt.tconst
        WHERE wi.field IN ('t', 'p', 'c') -- Focus on words from primarytitle, plot, and characters
    ),
    
    WordFrequencies AS (
        -- Step 3: Count the frequency of each word across the titles the person is involved in
        SELECT CAST(wt.word AS VARCHAR), CAST(wt.category AS VARCHAR), CAST(COUNT(*) AS INTEGER) AS frequency
        FROM WordsFromTitles wt -- Using alias 'wt' for WordsFromTitles CTE
        GROUP BY wt.word, wt.category -- Group by both word and category to distinguish between different word sources
        ORDER BY frequency DESC -- Sort by frequency in descending order
        LIMIT p_limit           -- Return only the top words, limited by p_limit
    )
    
    -- Step 4: Return the words, their frequencies, and their categories
    SELECT wf.word, wf.frequency, wf.category FROM WordFrequencies wf;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exact_match_query(p_keywords TEXT[])
RETURNS TABLE(tconst VARCHAR, title VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT tb.tconst::VARCHAR, tb.primarytitle::VARCHAR
    FROM titlebasic tb
    JOIN (
        SELECT wi.tconst
        FROM wi
        WHERE wi.word = ANY(p_keywords)
        GROUP BY wi.tconst
        HAVING COUNT(DISTINCT wi.word) = array_length(p_keywords, 1)
    ) matched_titles ON tb.tconst = matched_titles.tconst;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION best_match_query(p_keywords TEXT[])
RETURNS TABLE(tconst VARCHAR, title VARCHAR, match_count INT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tb.tconst::VARCHAR,               
        tb.primarytitle::VARCHAR,          
        COUNT(DISTINCT wi.word)::INT AS match_count
    FROM 
        titlebasic tb
    JOIN 
        wi ON tb.tconst = wi.tconst
    WHERE 
        wi.word = ANY(p_keywords)
    GROUP BY 
        tb.tconst, tb.primarytitle
    ORDER BY 
        match_count DESC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION word_to_words_query(p_keywords TEXT[])
RETURNS TABLE(word VARCHAR, frequency INT) AS $$
BEGIN
    RETURN QUERY
    WITH matched_titles AS (
        SELECT wi.tconst
        FROM wi
        WHERE wi.word = ANY(p_keywords)
        GROUP BY wi.tconst
    ),
    word_frequencies AS (
        SELECT wi.word::VARCHAR, COUNT(*)::INT AS frequency  -- Cast 'COUNT(*)' to INT
        FROM wi
        JOIN matched_titles mt ON wi.tconst = mt.tconst
        GROUP BY wi.word
    )
    SELECT wf.word, wf.frequency
    FROM word_frequencies wf
    ORDER BY wf.frequency DESC;
END;
$$ LANGUAGE plpgsql;