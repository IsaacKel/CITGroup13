create or replace function coPlayers(testId varCHAR (10)) RETURNS TABLE (nconst varCHAR(10), primaryname VARCHAR(256), frequency BIGINT)
LANGUAGE plpgsql as $$
BEGIN

return query
SELECT tp.nconst, nb.primaryname, count(tp.tconst) as freq from titleprincipals tp JOIN namebasic nb on tp.nconst = nb.nconst where tp.tconst in (select tconst from titleprincipals where titleprincipals.nconst = testId) and (tp.category = 'actor' or tp.category = 'actress') and nb.nconst != testId group by tp.nconst, nb.primaryname order by freq desc;

END;
$$;