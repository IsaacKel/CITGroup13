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
        title_basics tb ON b.tconst = tb.tconst
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
        name_basics nb ON b.nconst = nb.nconst
    WHERE 
        b.userid = p_userid;
END;
$$ LANGUAGE plpgsql VOLATILE
COST 100
ROWS 1000;
