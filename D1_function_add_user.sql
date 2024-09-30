CREATE OR REPLACE FUNCTION "public"."add_user"("p_username" varchar, "p_email" varchar)
  RETURNS "pg_catalog"."void" AS $BODY$
BEGIN
    INSERT INTO users (username, email) 
    VALUES (p_username, p_email);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  