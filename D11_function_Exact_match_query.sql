CREATE OR REPLACE FUNCTION exact_match_query(p_keywords TEXT[])
RETURNS TABLE(tconst VARCHAR, title VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT tb.tconst::VARCHAR, tb.primarytitle::VARCHAR
    FROM title_basics tb
    JOIN (
        SELECT wi.tconst
        FROM wi
        WHERE wi.word = ANY(p_keywords)
        GROUP BY wi.tconst
        HAVING COUNT(DISTINCT wi.word) = array_length(p_keywords, 1)
    ) matched_titles ON tb.tconst = matched_titles.tconst;
END;
$$ LANGUAGE plpgsql;