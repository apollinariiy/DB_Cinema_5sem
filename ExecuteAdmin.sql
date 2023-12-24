
BEGIN
    admin_package.RegistrationUser('user2', '1111', 'email');
END;
select * from USERS;
select * from dba_users where username = 'USER2';

BEGIN
    admin_package.AddHall('HallNameqwq1', 10, 20);
END;
select * from HALLS;

BEGIN
    admin_package.AddMovie(
        '',
        'Genre',
        'Director',
        'Description for Movie',
        120,
        'foto.jpg',
        'video.mp4'
    );
END;
select * from MOVIES;

BEGIN
    admin_package.AddSession(1, 334, '2023-12-25 21:00:00');
END;
select * from SESSIONS;

BEGIN
    admin_package.DeleteMovie(8);
END;

BEGIN
    admin_package.DeleteHall(222);
END;
select * from HALLS;

BEGIN
    admin_package.DeleteSession(4);
END;

BEGIN
    admin_package.UpdateMovie(
        4,
        'Updated Movie Title',
        'Updated Genre',
        'Updated Director',
        'Updated Description',
        150,
        'foto.jpg',
        'video.mp4'
    );
END;
select * from MOVIES;

BEGIN
    admin_package.UpdateHall(2, 'Updated Hall', 10, 25);
END;

BEGIN
    admin_package.UpdateSession(61, 4, 41, '2023-12-24 10:00:00');
END;

BEGIN
    admin_package.DeleteUser(1);
END;
select * from USERS;
select * from dba_users where username = 'USER1';

select * from RESERVATIONS;