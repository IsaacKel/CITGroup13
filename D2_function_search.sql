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
  ROWS 1000
