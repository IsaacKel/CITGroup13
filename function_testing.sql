--D1 test
select * from add_user('testUser1', 'testUser@ruc.dk');
select * from add_user('testUser2', 'testUser@ruc.dk');
select * from add_user('testUser3', 'testUser@ruc.dk');
select * from bookmark_movie(1, 'tt10061752');
select * from bookmark_name(1, 'nm5189091');
select * from get_bookmarks(1);
--D2 test
select * from string_search('Inception');
select * from string_search('Inception', 1);
--D3 test
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
--D4 test
SELECT * FROM structured_string_search('Inception', 'Dream', 'Cobb', 'leonardo');
--D5 test
select * from search_names_by_text('Gosling');
--D6 test
select * from coplayers('nm0331516');
--D7 test
select * from namebasic where nconst = 'nm0331516';
--D8 test
select * from ratingactors('tt3783958');
select * from ratingcoplayers('nm0331516');
select * from ratingcrew('tt3783958');
--D9 test
select * from similarmovies('tt3783958');
--D10 test
SELECT * FROM person_words('Will Smith');
--D11 test
SELECT * FROM exact_match_query(ARRAY['inception', 'dream']);
--D12 test
SELECT * FROM best_match_query(ARRAY['inception', 'dream']);
--D13 test
SELECT * FROM word_to_words_query(ARRAY['inception', 'dream']);