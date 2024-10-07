CREATE OR REPLACE FUNCTION best_match_query(p_keywords TEXT[])
RETURNS TABLE(tconst VARCHAR, title VARCHAR, match_count INT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tb.tconst::VARCHAR,               
        tb.primarytitle::VARCHAR,          
        COUNT(DISTINCT wi.word)::INT AS match_count
    FROM 
        titlebasic tb
    JOIN 
        wi ON tb.tconst = wi.tconst
    WHERE 
        wi.word = ANY(p_keywords)
    GROUP BY 
        tb.tconst, tb.primarytitle
    ORDER BY 
        match_count DESC;
END;
$$ LANGUAGE plpgsql;
