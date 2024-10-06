create or replace function ratingActors(testId VARCHAR(10)) returns table (nconst VARCHAR(10), nRating numeric(5,1))
LANGUAGE plpgsql as $$
BEGIN

return query
select nb.nconst, nb.nRating from (select tp.nconst from titleprincipals tp where tp.tconst = testId and (category = 'actor' or category = 'actress')) natural join namebasic nb order by nb.nRating DESC;

END;
$$;