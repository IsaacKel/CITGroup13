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
  ROWS 1000
