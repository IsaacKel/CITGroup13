CREATE OR REPLACE FUNCTION "public"."update_search_history"("p_userid" int4, "p_search_string" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
    INSERT INTO userSearchHistory (userId, searchQuery, searchDate) 
    VALUES (p_userid, p_search_string, CURRENT_DATE);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100