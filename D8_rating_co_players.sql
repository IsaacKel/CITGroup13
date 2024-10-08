create or replace function ratingCoPlayers(testId VARCHAR (10)) RETURNS TABLE (nconst VARCHAR(10), primaryname VARCHAR(256), nRating numeric(5,1))
LANGUAGE plpgsql as $$
BEGIN

return query
SELECT DISTINCT tp.nconst, nb.primaryname, nb.nRating from titleprincipals tp natural JOIN namebasic nb where tp.tconst in (select tconst from titleprincipals where titleprincipals.nconst = testId) and (tp.category = 'actor' or tp.category = 'actress') and nb.nconst != testId order by nrating desc nulls last;

END;
$$;