CREATE OR REPLACE FUNCTION search_names_by_text(search_text VARCHAR)
RETURNS TABLE (
    nconst VARCHAR(20),
    primaryName VARCHAR(255),
    birthYear CHAR(4),
    deathYear CHAR(4)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        nb.nconst,        -- Qualify nconst with the table alias
        nb.primaryName,   -- Qualify primaryName with the table alias
        nb.birthYear, 
        nb.deathYear
    FROM 
        nameBasic nb      -- Use an alias for the table
    WHERE 
        nb.primaryName ILIKE '%' || search_text || '%';  -- Case-insensitive search
END;
$$ LANGUAGE plpgsql;

