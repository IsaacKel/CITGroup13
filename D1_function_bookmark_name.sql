CREATE OR REPLACE FUNCTION "public"."bookmark_name"("p_userid" int4, "p_nconst" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
    INSERT INTO userbookmarks (userid, nconst) VALUES (p_userid, p_nconst);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100