
BEGIN
   user_action.MakeReservation(1, 12, 1);
END;

BEGIN
   user_action.BUYTICKET(61, 3, 4);
END;
BEGIN
   user_action.UPDATERESERVATIONSTATUS(2);
END;
BEGIN
    user_action.GETFREESEATSFORSESSION(1);
END;

begin
    user_action.CANCELRESERVATION(1);
end;

begin
    user_action.VIEWUSERRESERVATIONS();
end;
begin
   user_action.VIEWSESSIONSBYDATE('2023-12-19');
end;
BEGIN
    user_action.GETSCHEDULEFORNEXTWEEK();
end;
BEGIN
    user_action.GETMOVIEBYID(5);
end;

    select ADMIN_DATABASE.USER_PACKAGE.OPENPOSTER(5) from dual;

    select ADMIN_DATABASE.USER_PACKAGE.OPENTRAILER(8) from dual;
