CREATE OR REPLACE FUNCTION "public"."bookmark_movie"("p_userid" int4, "p_tconst" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
    INSERT INTO userbookmarks (userid, tconst) VALUES (p_userid, p_tconst);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100