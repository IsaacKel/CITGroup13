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
