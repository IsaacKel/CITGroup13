ALTER TABLE namebasic ADD IF NOT EXISTS nRating NUMERIC (5,1);
CREATE INDEX IF NOT EXISTS index_tp_nconst ON titleprincipals (nconst);
UPDATE namebasic
SET nRating=(
SELECT round(SUM (tr.averagerating*tr.numvotes)/SUM (tr.numvotes),1) FROM titleprincipals tp INNER JOIN titleratings tr ON tp.tconst=tr.tconst WHERE namebasic.nconst=tp.nconst);
CREATE INDEX IF NOT EXISTS index_tp_category ON titleprincipals (category);
CREATE INDEX IF NOT EXISTS index_nb_nrating ON namebasic (nrating);
CREATE INDEX IF NOT EXISTS index_tr_numvotes ON titleratings (numvotes);
CREATE INDEX IF NOT EXISTS index_tp_tconst ON titleprincipals (tconst);
CREATE INDEX IF NOT EXISTS index_tb_primarytitle ON titlebasic (primarytitle);
CREATE INDEX IF NOT EXISTS index_tl_languages ON titlelanguage (language);
CREATE INDEX IF NOT EXISTS index_tg_genre ON titlegenre (genre);