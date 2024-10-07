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
