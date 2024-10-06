--D3 test
select * from add_user('testUser1', 'testUser@ruc.dk');
select * from add_user('testUser2', 'testUser@ruc.dk');
select * from add_user('testUser3', 'testUser@ruc.dk');
select * from titleratings where tconst = 'tt10061752';
select * from namebasic where nconst = 'nm5189091';
call rate('tt10061752', 1, 1);
call rate('tt10061752', 1, 2);
call rate('tt10061752', 1, 3);
select * from titleratings where tconst = 'tt10061752';
select * from namebasic where nconst = 'nm5189091';
select * from userratings;
call rate('tt10061752', 10, 1);
select * from titleratings where tconst = 'tt10061752';
select * from namebasic where nconst = 'nm5189091';
select * from userratings;
--D6 test
select * from coplayers('nm0331516');
--D7 test
select * from namebasic where nconst = 'nm0331516';
--D8 test
select * from ratingactors('tt3783958');
select * from ratingcoplayers('nm0331516');
select * from ratingactors('tt3783958');
--D9 test
select * from similarmovies('tt3783958');