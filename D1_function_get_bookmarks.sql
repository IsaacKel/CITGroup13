CREATE OR REPLACE FUNCTION "public"."get_bookmarks"("p_userid" INT)
  RETURNS TABLE("tconst" varchar, "title" varchar) AS $BODY$
BEGIN
    RETURN QUERY 
    SELECT b.tconst, tb.primarytitle::VARCHAR
    FROM userbookmarks b
    JOIN title_basics tb ON b.tconst = tb.tconst
    WHERE b.userid = p_userid;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000
