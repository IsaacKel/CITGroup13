create or replace function similarMovies(testId VARCHAR(10)) returns table (tconst VARCHAR(10), primarytitle VARCHAR(256), numvotes int4)
LANGUAGE plpgsql as $$
BEGIN

return query
select DISTINCT tb.tconst, tb.primarytitle, tr.numvotes from titlebasic tb 
natural join titlegenre tg 
natural join titlelanguage tl 
natural join titleratings tr 
where tg.genre in (select tg.genre from titlegenre tg where tg.tconst = testId) 
and tl.language in (select language from titlelanguage tl where tl.tconst = testId) 
order by tr.numvotes DESC limit 10;

END;
$$;