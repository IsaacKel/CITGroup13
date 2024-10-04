DROP FUNCTION IF EXISTS person_words(VARCHAR, INTEGER);

CREATE OR REPLACE FUNCTION person_words(
    p_primaryname VARCHAR,     -- The name of the person we're interested in
    p_limit INTEGER DEFAULT 10 -- Limit on the number of words returned (default 10)
) 
RETURNS TABLE (
    word VARCHAR,              -- The word associated with the person
    frequency INTEGER,         -- Frequency of the word in titles the person is involved in
    category VARCHAR           -- The field category (t = title, p = plot, c = characters)
) AS $$
BEGIN
    RETURN QUERY
    WITH PersonTitles AS (
        -- Step 1: Retrieve all titles (tconst) the person is associated with from the titlePrincipals table
        SELECT DISTINCT tp.tconst
        FROM titlePrincipals tp
        JOIN namebasic nb ON tp.nconst = nb.nconst
        WHERE LOWER(nb.primaryname) = LOWER(p_primaryname) -- Match the person's name (case-insensitive)
    ),
    
    WordsFromTitles AS (
        -- Step 2: Retrieve words associated with these titles from the wi table
        SELECT wi.word AS word, wi.field AS category
        FROM wi
        JOIN PersonTitles pt ON wi.tconst = pt.tconst
        WHERE wi.field IN ('t', 'p', 'c') -- Focus on words from primarytitle, plot, and characters
    ),
    
    WordFrequencies AS (
        -- Step 3: Count the frequency of each word across the titles the person is involved in
        SELECT CAST(wt.word AS VARCHAR), CAST(wt.category AS VARCHAR), CAST(COUNT(*) AS INTEGER) AS frequency
        FROM WordsFromTitles wt -- Using alias 'wt' for WordsFromTitles CTE
        GROUP BY wt.word, wt.category -- Group by both word and category to distinguish between different word sources
        ORDER BY frequency DESC -- Sort by frequency in descending order
        LIMIT p_limit           -- Return only the top words, limited by p_limit
    )
    
    -- Step 4: Return the words, their frequencies, and their categories
    SELECT wf.word, wf.frequency, wf.category FROM WordFrequencies wf;

END;
$$ LANGUAGE plpgsql;

SELECT * FROM person_words('Will Smith');