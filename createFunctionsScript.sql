CREATE MATERIALIZED VIEW popularity_view AS
SELECT
    tp.nconst,
    SUM(tr.numVotes) AS popularity
FROM
    titlePrincipals tp
    JOIN titleRatings tr ON tp.tconst = tr.tconst
WHERE
    tp.category IN ('actor', 'actress')
GROUP BY
    tp.nconst;

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
  RETURNS TABLE("tconst" varchar, "title" varchar, "poster" varchar, "startYear" int4, "genre" varchar, "rating" numeric) AS $BODY$
BEGIN
    RETURN QUERY 
    SELECT 
        tb.tconst::VARCHAR,              
        tb.primarytitle::VARCHAR,        
        tb.poster::VARCHAR,               
        tb.startyear::INTEGER,           
        STRING_AGG(tg.genre, ', ')::VARCHAR AS genre, 
        tr.averagerating::NUMERIC        
    FROM titlebasic tb
    LEFT JOIN titleratings tr ON tb.tconst = tr.tconst 
    LEFT JOIN titlegenre tg ON tb.tconst = tg.tconst    
    WHERE tb.primarytitle ILIKE '%' || p_search_string || '%' 
       OR tb.tconst IN (
           SELECT tb.tconst 
           FROM titlebasic tb
           WHERE tb.plot ILIKE '%' || p_search_string || '%'
       )
    GROUP BY 
        tb.tconst, 
        tb.primarytitle, 
        tb.poster, 
        tb.startyear, 
        tr.averagerating 
    ORDER BY 
        CASE 
            WHEN tb.primarytitle ILIKE p_search_string THEN 1
            ELSE 2
        END, 
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

CREATE OR REPLACE FUNCTION "public"."search_names_by_text_sorted"("search_text" varchar, "sorttype" varchar)
  RETURNS TABLE("nconst" varchar, "primaryname" varchar, "birthyear" bpchar, "deathyear" bpchar, "nrating" numeric) AS $BODY$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT
            nb.nconst,
            nb.primaryName,
            nb.birthYear,
            nb.deathYear,
            nb.nrating
         FROM
            nameBasic nb
         LEFT JOIN popularity_view pop ON nb.nconst = pop.nconst
         WHERE
            nb.primaryName ILIKE ''%' || search_text || '%''
         ORDER BY ' || CASE 
                        WHEN sortType = 'popularity' THEN 'pop.popularity DESC NULLS LAST'
                        WHEN sortType = 'rating' THEN 'nb.nrating DESC NULLS LAST'
                        WHEN sortType = 'year' THEN 'nb.birthYear'
                        ELSE 'nb.primaryName'
                        END || ';';
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

CREATE OR REPLACE FUNCTION "public"."similarmovies"("testid" varchar)
  RETURNS TABLE("tconst" varchar, "primarytitle" varchar, "numvotes" int4, "matching_languages" int4, "poster" varchar) AS $BODY$
BEGIN

return query
select t.tconst, t.primarytitle, t.numvotes, t.matching_languages::int4, t.poster
from (
    select tb.tconst, tb.primarytitle, tr.numvotes, 
    (select count(*) from titlelanguage tl1 
     where tl1.tconst = tb.tconst
     and tl1.language in (select language from titlelanguage tl2 where tl2.tconst = testid)) as matching_languages,
    tb.poster,
    row_number() over (partition by tb.tconst order by 
                      (select count(*) from titlelanguage tl1 
                       where tl1.tconst = tb.tconst
                       and tl1.language in (select language from titlelanguage tl2 where tl2.tconst = testid)) desc, 
                      tr.numvotes desc) as rn
    from titlebasic tb
    natural join titlegenre tg
    natural join titleratings tr
    where tb.tconst IN (
        select tg_outer.tconst
        from titlegenre tg_outer
        where tg_outer.genre IN (
            select tg_inner.genre
            from titlegenre tg_inner
            where tg_inner.tconst = testid
        )
        group by tg_outer.tconst
        having count(distinct tg_outer.genre) = (
            select count(distinct tg_inner.genre)
            from titlegenre tg_inner
            where tg_inner.tconst = testid
        )
    )
    and tb.tconst != testid
) as t
where t.rn = 1
order by t.matching_languages DESC, t.numvotes DESC;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

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

CREATE OR REPLACE FUNCTION "public"."filtered_search_numvotes"("search_term" varchar='null'::character varying, "search_titletype" varchar='null'::character varying, "search_genre" varchar='null'::character varying, "search_year" int4='-1'::integer)
  RETURNS TABLE("tconst" varchar, "primarytitle" varchar, "startyear" int4, "numvotes" int4, "rating" numeric, "poster" varchar, "genre" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        tb.tconst, 
        tb.primarytitle, 
        tb.startyear::INTEGER, 
        COALESCE(tr.numvotes, 0) AS numvotes, 
        tr.averagerating, 
        tb.poster, 
        STRING_AGG(tg.genre, ', ')::varchar AS genre
    FROM 
        titlebasic tb
        LEFT JOIN titleratings tr ON tb.tconst = tr.tconst
        LEFT JOIN titlegenre tg ON tb.tconst = tg.tconst
    WHERE 
        (search_term ='null' OR tb.primarytitle ILIKE '%' || search_term || '%' OR tb.plot ILIKE '%' || search_term || '%')
        AND (search_titletype ='null' OR tb.titletype = search_titletype)
        AND (search_year =-1 OR tb.startyear::INTEGER = search_year)
    GROUP BY tb.tconst, tb.primarytitle, tb.startyear, tb.poster, tr.numvotes, tr.averagerating
    HAVING
        (search_genre = 'null' OR STRING_AGG(tg.genre, ', ') ILIKE '%' || search_genre || '%')
    ORDER BY numvotes DESC NULLS LAST;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."filtered_search_avgrating"("search_term" varchar='null'::character varying, "search_titletype" varchar='null'::character varying, "search_genre" varchar='null'::character varying, "search_year" int4='-1'::integer)
  RETURNS TABLE("tconst" varchar, "primarytitle" varchar, "startyear" int4, "numvotes" int4, "rating" numeric, "poster" varchar, "genre" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        tb.tconst, 
        tb.primarytitle, 
        tb.startyear::INTEGER, 
        COALESCE(tr.numvotes, 0) AS numvotes, 
        tr.averagerating as rating,
        tb.poster, 
        STRING_AGG(tg.genre, ', ')::varchar AS genre
    FROM 
        titlebasic tb
        LEFT JOIN titleratings tr ON tb.tconst = tr.tconst
        LEFT JOIN titlegenre tg ON tb.tconst = tg.tconst
    WHERE 
        (search_term = 'null' OR tb.primarytitle ILIKE '%' || search_term || '%' OR tb.plot ILIKE '%' || search_term || '%')
        AND (search_titletype = 'null' OR tb.titletype = search_titletype)
        AND (search_year =-1 OR tb.startyear::INTEGER = search_year)
    GROUP BY tb.tconst, tb.primarytitle, tb.startyear, tb.poster, tr.numvotes, tr.averagerating
    HAVING
        (search_genre = 'null' OR STRING_AGG(tg.genre, ', ') ILIKE '%' || search_genre || '%')
    ORDER BY rating DESC NULLS LAST;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."filtered_search_years"("search_term" varchar='null'::character varying, "search_titletype" varchar='null'::character varying, "search_genre" varchar='null'::character varying, "search_year" int4='-1'::integer)
  RETURNS TABLE("tconst" varchar, "primarytitle" varchar, "startyear" int4, "numvotes" int4, "rating" numeric, "poster" varchar, "genre" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT 
        tb.tconst, 
        tb.primarytitle, 
        tb.startyear::INTEGER, 
        COALESCE(tr.numvotes, 0) AS numvotes, 
        tr.averagerating, 
        tb.poster, 
        STRING_AGG(tg.genre, ', ')::varchar AS genre
    FROM 
        titlebasic tb
        LEFT JOIN titleratings tr ON tb.tconst = tr.tconst
        LEFT JOIN titlegenre tg ON tb.tconst = tg.tconst
    WHERE 
        (search_term ='null' OR tb.primarytitle ILIKE '%' || search_term || '%' OR tb.plot ILIKE '%' || search_term || '%')
        AND (search_titletype ='null' OR tb.titletype = search_titletype)
        AND (search_year =-1 OR tb.startyear::INTEGER = search_year)
    GROUP BY tb.tconst, tb.primarytitle, tb.startyear, tb.poster, tr.numvotes, tr.averagerating
    HAVING
        (search_genre = 'null' OR STRING_AGG(tg.genre, ', ') ILIKE '%' || search_genre || '%')
    ORDER BY startyear DESC NULLS LAST;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."get_distinct_genres"()
  RETURNS TABLE("genre" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT DISTINCT titlegenre.genre AS genre_alias
    FROM titlegenre
    ORDER BY titlegenre.genre;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."get_distinct_title_types"()
  RETURNS TABLE("titletype" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT DISTINCT tb.titletype
    FROM titlebasic tb
    ORDER BY tb.titletype;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."get_distinct_start_years"()
  RETURNS TABLE("startyear" int4) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT DISTINCT tb.startyear::INTEGER
    FROM titlebasic tb
    WHERE tb.startyear IS NOT NULL
    ORDER BY tb.startyear::INTEGER DESC;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."get_title_principals_name"("_nconst" text)
  RETURNS TABLE("tconst" varchar, "nconst" varchar, "ordering" int4, "name" varchar, "title" varchar, "release_year" int4, "roles" text, "poster" varchar) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        tp.tconst,
        tp.nconst,
                MIN(tp.ordering) AS ordering,
        nb.primaryName AS name,
        tb.primaryTitle AS title,
        tb.startYear::int4 AS release_year,
        STRING_AGG(
            DISTINCT INITCAP(REPLACE(tp.category, '_', ' ')),
            ', '
        ) AS roles,
        tb.poster
    FROM 
        titleprincipals tp
    JOIN 
        titlebasic tb ON tp.tconst = tb.tconst
    JOIN
        namebasic nb ON tp.nconst = nb.nconst -- Join with namebasic to get the name
    WHERE 
        tp.nconst = _nconst
    GROUP BY
        tp.tconst, tp.nconst, nb.primaryName, tb.primaryTitle, tb.startYear, tb.poster
    ORDER BY
        tb.startYear DESC, 
        MIN(tp.ordering),
        tb.primaryTitle;   -- Then alphabetically by title
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;

CREATE OR REPLACE FUNCTION "public"."top10actors"()
  RETURNS TABLE("nconst" text, "primaryname" text, "total_numvotes" int4) AS $BODY$
BEGIN
    RETURN QUERY
    SELECT
        nb.nconst::TEXT,
        nb.primaryName::TEXT,
        pop.popularity::INT AS total_numvotes
    FROM
        nameBasic nb
    JOIN popularity_view pop ON nb.nconst = pop.nconst
    WHERE
        nb.nconst IN (
            SELECT tp.nconst
            FROM titlePrincipals tp
            WHERE tp.category IN ('actor', 'actress')
        )
    ORDER BY
        pop.popularity DESC
    LIMIT 10;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 10;


CREATE OR REPLACE FUNCTION "public"."top10movies"()
  RETURNS TABLE("tconst" varchar, "titletype" varchar, "primarytitle" varchar, "poster" varchar) AS $BODY$
BEGIN

return query
select tb.tconst, tb.titletype, tb.primarytitle, tb.poster
from titlebasic tb
join titleratings tr on tb.tconst = tr.tconst
where tb.titletype = 'movie'
order by tr.numvotes DESC
limit 10;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 10;

CREATE OR REPLACE FUNCTION "public"."top10series"()
  RETURNS TABLE("tconst" varchar, "titletype" varchar, "primarytitle" varchar, "poster" varchar) AS $BODY$
BEGIN

return query
select tb.tconst, tb.titletype, tb.primarytitle, tb.poster
from titlebasic tb
join titleratings tr on tb.tconst = tr.tconst
where tb.titletype = 'tvSeries'
order by tr.numvotes DESC
limit 10;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 10;