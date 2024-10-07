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
