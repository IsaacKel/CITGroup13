CREATE OR REPLACE FUNCTION word_to_words_query(p_keywords TEXT[])
RETURNS TABLE(word VARCHAR, frequency INT) AS $$
BEGIN
    RETURN QUERY
    WITH matched_titles AS (
        SELECT wi.tconst
        FROM wi
        WHERE wi.word = ANY(p_keywords)
        GROUP BY wi.tconst
    ),
    word_frequencies AS (
        SELECT wi.word::VARCHAR, COUNT(*)::INT AS frequency  -- Cast 'COUNT(*)' to INT
        FROM wi
        JOIN matched_titles mt ON wi.tconst = mt.tconst
        GROUP BY wi.word
    )
    SELECT wf.word, wf.frequency
    FROM word_frequencies wf
    ORDER BY wf.frequency DESC;
END;
$$ LANGUAGE plpgsql;
