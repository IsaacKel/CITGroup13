create or replace PROCEDURE rate(titleId VARCHAR(20), _rating int4, _userId int4)
LANGUAGE plpgsql as $$
declare oldRating int;
oldnumvotes int;
oldaveragerating numeric(3,1);
BEGIN

if _rating between 1 and 10 then
  select numvotes from titleratings tr where tr.tconst = titleId into oldnumvotes;
  select averagerating from titleratings tr where tr.tconst = titleId into oldaveragerating;
  if exists (select 1 from userratings ur where ur.tconst = titleId and ur.userid = _userId) THEN
    --update existing rating
    --update userratings (get old value)
    select rating from userratings ur where ur.tconst = titleId and ur.userid = _userId into oldRating;
    update userratings set rating = _rating, ratingdate = CURRENT_DATE where userid = _userId and tconst = titleId;
    --update titleratings (needs old value)
    update titleratings set averagerating = (COALESCE(oldnumvotes,0)*COALESCE(oldaveragerating,0)-oldRating + _rating)/COALESCE(oldnumvotes,1) where tconst = titleId;
  ELSE
    --new rating
    --insert into userratings
    insert into userratings(userid, ratingid, tconst, rating, ratingdate)
    values (_userId, (_userId+_rating), titleId, _rating, CURRENT_DATE);
    --update titleratings
    update titleratings set numvotes = numvotes + 1,
    averagerating = (COALESCE(oldnumvotes,0)*COALESCE( oldaveragerating,0) + _rating)/(COALESCE(oldnumvotes)+1) where tconst = titleId;
  end if;
    --update nrating in namebasic
    update namebasic set nrating = (select round(sum(tr.averagerating*tr.numvotes)/sum(tr.numvotes),1) from titleprincipals tp inner join titleratings tr on tp.tconst = tr.tconst where namebasic.nconst = tp.nconst) where namebasic.nconst in (select nconst from titleprincipals where tconst = titleId);
else
  raise notice 'Input value must be between 1 and 10';
end if;
END;
$$;