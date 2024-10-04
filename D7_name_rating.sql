alter table namebasic add IF NOT EXISTS nRating numeric(5,1);

create index IF NOT EXISTS index_tp_nconst on titleprincipals(nconst);

update namebasic set nRating = (select round(sum(tr.averagerating*tr.numvotes)/sum(tr.numvotes),1) from titleprincipals tp inner join titleratings tr on tp.tconst = tr.tconst where namebasic.nconst = tp.nconst);
