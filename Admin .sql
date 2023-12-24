create directory POSTER_DIR as  'C:\bd\poster';
create directory TRAILER_DIR as 'C:\bd\trailer';
drop directory POSTER_DIR;
drop directory TRAILER_DIR;


create role admin_role;
grant DBA to admin_role;
grant admin_role to ADMIN_DATABASE;

create public synonym user_action for ADMIN_DATABASE.user_package;

BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'DELETE_OLD_SESSIONS_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN DELETE_OLD_SESSIONS; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE
  );
END;

CREATE OR REPLACE PROCEDURE DELETE_OLD_SESSIONS IS
BEGIN
  DELETE FROM Sessions WHERE StartTime < SYSDATE;
  COMMIT;
END DELETE_OLD_SESSIONS;

delete from MOVIES;

    CREATE OR REPLACE PROCEDURE AddManyMovies AS
    v_Title VARCHAR2(255);
    v_Genre VARCHAR2(100);
    v_Director VARCHAR2(100);
    v_Description VARCHAR2(100);
    v_Duration NUMBER;
    v_Poster VARCHAR2(255);
    v_Trailer VARCHAR2(255);
BEGIN
    FOR i IN 1..80000 LOOP
        v_Title := 'Movie' || TO_CHAR(i);
        v_Genre := 'Genre' || TO_CHAR(i);
        v_Director := 'Director' || TO_CHAR(i);
        v_Description := 'Description' || TO_CHAR(i);
        v_Duration := DBMS_RANDOM.VALUE(90, 180);
        v_Poster := 'foto.jpg';
        v_Trailer := 'video.mp4';

        admin_package.AddMovie(
            p_Title => v_Title,
            p_Genre => v_Genre,
            p_Director => v_Director,
            p_Description => v_Description,
            p_Duration => v_Duration,
            p_Poster => v_Poster,
            p_Trailer => v_Trailer
        );
        commit ;
    END LOOP;
    COMMIT;
END AddManyMovies;


begin
    AddManyMovies();
    end;

CREATE OR REPLACE PROCEDURE AddManyHalls AS
    v_HallName VARCHAR2(255);
    v_RowsCount NUMBER;
    v_SeatsCount NUMBER;
BEGIN
    FOR i IN 1..100000 LOOP
        v_HallName := 'Hall' || TO_CHAR(i);
        v_RowsCount := TO_NUMBER(DBMS_RANDOM.VALUE(5, 20));
        v_SeatsCount := TO_NUMBER(DBMS_RANDOM.VALUE(10, 30));

        admin_package.AddHall(
            p_HallName => v_HallName,
            p_RowsCount => v_RowsCount,
            p_SeatsCount => v_SeatsCount
        );
        COMMIT;
    END LOOP;
    COMMIT;
END AddManyHalls;

    delete from HALLS;
begin
    AddManyHalls();
    end;
commit;

select * from HALLS where ID > 10000;
select count(*) from MOVIES;
create profile PF_USER limit
    password_life_time 180
    sessions_per_user 3
    failed_login_attempts 7
    password_lock_time 1
    password_reuse_time 10
    password_grace_time default
    connect_time 180
    idle_time 30;

SELECT *
FROM USER_SYS_PRIVS;
SELECT *
FROM USER_ROLE_PRIVS;
SELECT *
FROM SESSION_ROLES;
drop package admin_package;
CREATE OR REPLACE PACKAGE admin_package AS
   FUNCTION IsMovieExists(p_ID IN NUMBER) RETURN BOOLEAN;
   FUNCTION IsHallExists(p_ID IN NUMBER) RETURN BOOLEAN;
   FUNCTION IsSessionExists(p_ID IN NUMBER) RETURN BOOLEAN;
   FUNCTION IsReservationExists(p_ID IN NUMBER) RETURN BOOLEAN;
   FUNCTION IsUserExists(p_ID IN NUMBER) RETURN BOOLEAN;

   PROCEDURE RegistrationUser(
        p_Login IN VARCHAR2,
        p_Password IN VARCHAR2,
        p_Email IN VARCHAR2);

   PROCEDURE AddMovie(
      p_Title IN VARCHAR2,
      p_Genre IN VARCHAR2,
      p_Director IN VARCHAR2,
      p_Description IN CLOB,
      p_Duration IN NUMBER,
      p_Poster IN VARCHAR2,
      p_Trailer IN VARCHAR2
   );

  PROCEDURE AddHall(
    p_HallName IN VARCHAR2,
    p_RowsCount IN NUMBER,
    p_SeatsCount IN NUMBER
  );

  PROCEDURE AddSession(
    p_MovieID IN NUMBER,

    p_HallID IN NUMBER,
    p_StartTime IN VARCHAR2
  );

  PROCEDURE DeleteMovie(
    p_MovieID IN NUMBER
  );

  PROCEDURE DeleteHall(
    p_HallID IN NUMBER
  );

  PROCEDURE DeleteSession(
    p_SessionID IN NUMBER
  );

  PROCEDURE DeleteReservation(
    p_ReservationID IN NUMBER
  );

  PROCEDURE DeleteUser(
    p_UserID IN NUMBER
  );


  PROCEDURE UpdateMovie(
    p_MovieID IN NUMBER,
    p_Title IN VARCHAR2,
    p_Genre IN VARCHAR2,
    p_Director IN VARCHAR2,
    p_Description IN CLOB,
    p_Duration IN NUMBER,
    p_Poster IN VARCHAR2,
    p_Trailer IN VARCHAR2
  );

  PROCEDURE UpdateHall(
    p_HallID IN NUMBER,
    p_HallName IN VARCHAR2,
    p_RowsCount IN NUMBER,
    p_SeatsCount IN NUMBER
  );

  PROCEDURE UpdateSession(
    p_SessionID IN NUMBER,
    p_MovieID IN NUMBER,
    p_HallID IN NUMBER,
    p_StartTime IN varchar2
  );
  FUNCTION IsDateValid(
    p_InputDate IN DATE,
    p_MovieID IN Number,
    p_HallID in Number) return boolean;

END admin_package;


    CREATE OR REPLACE PACKAGE BODY admin_package AS
        FUNCTION IsDateValid(
    p_InputDate IN DATE,
    p_MovieID IN Number,
    p_HallID in NUMBER
) RETURN BOOLEAN IS
    CURSOR c_SessionDates IS
        SELECT STARTTIME AS SessionDate
        FROM Sessions where HALLID = p_HallID
        ORDER BY SessionDate;
    v_Duration NUMBER;
    v_Hour NUMBER;
    v_Minute NUMBER;
    v_SessionDate DATE;
    v_Result DATE;
    v_duraction number;
    v_resultwitnDuraction DATE;
BEGIN
    OPEN c_SessionDates;
    LOOP
        FETCH c_SessionDates INTO v_SessionDate;
        EXIT WHEN c_SessionDates%NOTFOUND;

        IF v_SessionDate IS NOT NULL THEN
            SELECT DURATION into v_duraction from MOVIES where ID = p_MovieID;
            v_resultwitnDuraction := p_InputDate + (TRUNC(v_duraction / 60)) * INTERVAL '1' HOUR + (v_duraction - (TRUNC(v_duraction / 60)) * 60) * INTERVAL '1' MINUTE;
            SELECT Duration
            INTO v_Duration
            FROM Movies
            WHERE ID IN (SELECT MovieID FROM Sessions WHERE STARTTIME = v_SessionDate);
            v_Hour := TRUNC(v_Duration / 60);
            v_Minute := v_Duration - v_Hour * 60;
            v_Result := v_SessionDate + v_Hour * INTERVAL '1' HOUR + v_Minute * INTERVAL '1' MINUTE;
            if (v_resultwitnDuraction between v_SessionDate and v_Result) or (p_InputDate between v_SessionDate and v_Result) then
                return false;
        ELSE
            return true;
        END IF;
            else
            return true;
            end if;

    END LOOP;
    CLOSE c_SessionDates;
    RETURN true;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN FALSE;
    WHEN OTHERS THEN
        RETURN FALSE;
END IsDateValid;
        FUNCTION IsMovieExists(p_ID IN NUMBER) RETURN BOOLEAN IS
   v_Count NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Count FROM Movies WHERE ID = p_ID;
   if v_Count > 0 then
       return true;
   else
       return false;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IsMovieExists;

            FUNCTION IsHallExists(p_ID IN NUMBER) RETURN BOOLEAN IS
   v_Count NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Count FROM Halls WHERE ID = p_ID;
   if v_Count > 0 then
       return true;
   else
       return false;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IsHallExists;

            FUNCTION IsSessionExists(p_ID IN NUMBER) RETURN BOOLEAN IS
   v_Count NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Count FROM Sessions WHERE ID = p_ID;
   if v_Count > 0 then
       return true;
   else
       return false;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IsSessionExists;

            FUNCTION IsReservationExists(p_ID IN NUMBER) RETURN BOOLEAN IS
   v_Count NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Count FROM Reservations WHERE ID = p_ID;
   if v_Count > 0 then
       return true;
   else
       return false;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IsReservationExists;

            FUNCTION IsUserExists(p_ID IN NUMBER) RETURN BOOLEAN IS
   v_Count NUMBER;
BEGIN
   SELECT COUNT(*) INTO v_Count FROM Users WHERE ID = p_ID;
   if v_Count > 0 then
       return true;
   else
       return false;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IsUserExists;


 PROCEDURE RegistrationUser(
    p_Login IN VARCHAR2,
    p_Password IN VARCHAR2,
    p_Email IN VARCHAR2
) IS
    v_UserCount NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_UserCount
    FROM Users
    WHERE Login = p_Login;

    IF v_UserCount > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Пользователь с логином ' || p_Login || ' уже существует');
    ELSE
        EXECUTE IMMEDIATE 'CREATE USER ' || p_Login || ' IDENTIFIED BY ' || p_Password || ' PROFILE PF_USER';
        EXECUTE IMMEDIATE 'GRANT user_role TO ' || p_Login;
        INSERT INTO Users (Login, Password, Email)
        VALUES (p_Login, p_Password, p_Email);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Пользователь ' || p_Login || ' успешно зарегистрирован');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при регистрации пользователя: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END RegistrationUser;
      PROCEDURE AddMovie(
        p_Title IN VARCHAR2,
        p_Genre IN VARCHAR2,
        p_Director IN VARCHAR2,
        p_Description IN CLOB,
        p_Duration IN NUMBER,
        p_Poster IN VARCHAR2,
        p_Trailer IN VARCHAR2
    ) IS
          v_count number;
        file_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(file_exception, -22288);
         check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);
    BEGIN
        select count(*) into v_count from MOVIES where TITLE = p_Title;
        if v_count = 0 then
        INSERT INTO Movies (Title, Genre, Director, Description, Duration, Poster, Trailer)
        VALUES (p_Title, p_Genre, p_Director, p_Description, p_Duration,BFILENAME('POSTER_DIR', p_Poster), BFILENAME('TRAILER_DIR', p_Trailer));
        COMMIT;
                DBMS_OUTPUT.PUT_LINE('AddMovie: успешное добавление фильма');
        else
                DBMS_OUTPUT.PUT_LINE('AddMovie: фильм с таким названием уже есть');
         end if;
    EXCEPTION
    WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите параметры корректно');
     WHEN file_exception THEN
      DBMS_OUTPUT.PUT_LINE('Файл постера или трейлера не найден');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры AddMovie: ' || SQLERRM);
            ROLLBACK;
            RAISE;
    END AddMovie;
PROCEDURE AddHall(
    p_HallName IN VARCHAR2,
    p_RowsCount IN NUMBER,
    p_SeatsCount IN NUMBER
) IS
    v_count number;
  check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);
BEGIN
    select count(*) into v_count from Halls where HallName = p_HallName;
        if v_count = 0 then
    INSERT INTO Halls (HallName, RowsCount, SeatsCount)
    VALUES (p_HallName,p_RowsCount, p_SeatsCount);
    COMMIT;
                DBMS_OUTPUT.PUT_LINE('AddHall: успешное добавление зала');
    else
                DBMS_OUTPUT.PUT_LINE('AddHall: зал с таким названием уже создан');
        end if;
EXCEPTION
    WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Ошибка. Введите корректное значение.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры AddHall: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END AddHall;

PROCEDURE AddSession(
    p_MovieID IN NUMBER,
    p_HallID IN NUMBER,
    p_StartTime IN VARCHAR2
) IS
check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);
date_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(date_exception, -01861);
BEGIN
    if IsMovieExists(p_MovieID)  and IsHallExists(p_HallID) then
        if (SYSDATE < TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS'))  then
            if ISDATEVALID(TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS'),p_MovieID, p_HallID) then
    INSERT INTO Sessions (MovieID, HallID, StartTime)
    VALUES (p_MovieID, p_HallID, TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS'));
    COMMIT;
                DBMS_OUTPUT.PUT_LINE('AddSession: успешное добавление сеанса');
            else
                DBMS_OUTPUT.PUT_LINE('AddSession: в это время в зале уже запланирован сеанс');
            end if;
        else
                                DBMS_OUTPUT.PUT_LINE('Заданная дата уже прошла');
        end if;
    else
                        DBMS_OUTPUT.PUT_LINE('Заданного MovieID и HallID не существует');
    end if;
EXCEPTION
WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Нарушено ограничение целостности');
      WHEN date_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите корректную дату');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры AddSession: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END AddSession;

  PROCEDURE DeleteMovie(
    p_MovieID IN NUMBER
) IS
BEGIN
    if IsMovieExists(p_MovieID) then
    DELETE FROM Movies WHERE ID = p_MovieID;
    COMMIT;
                DBMS_OUTPUT.PUT_LINE('DeleteMovie: успешное удаление фильма');
    else
        DBMS_OUTPUT.PUT_LINE('DeleteMovie: фильм с заданным ID не наден');
    end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры DeleteMovie: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END DeleteMovie;

  PROCEDURE DeleteHall(
    p_HallID IN NUMBER
) IS
BEGIN
    if IsHallExists(p_HallID) then
    DELETE FROM Halls WHERE ID = p_HallID;
    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('DeleteHall: успешное удаление зала');
    else
                    DBMS_OUTPUT.PUT_LINE('DeleteHall: зал с заданным ID не найден');
    end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры DeleteHall: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END DeleteHall;

  PROCEDURE DeleteSession(
    p_SessionID IN NUMBER
) IS
BEGIN
    if IsSessionExists(p_SessionID) then
    DELETE FROM Sessions WHERE ID = p_SessionID;
    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('DeleteSession: успешное удаление показа');
    else
                            DBMS_OUTPUT.PUT_LINE('DeleteSession: сеанс с заданным ID не найден');
    end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры DeleteSession: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END DeleteSession;

PROCEDURE DeleteReservation(
    p_ReservationID IN NUMBER
) IS
BEGIN
    if IsReservationExists(p_ReservationID) then
    DELETE FROM Reservations WHERE ID = p_ReservationID;
    COMMIT;
                        DBMS_OUTPUT.PUT_LINE('DeleteReservation: успешное удаление брони');
    else
        DBMS_OUTPUT.PUT_LINE('DeleteReservation: бронь с заданным ID не найдена');
        end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры DeleteReservation: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END DeleteReservation;

  PROCEDURE DeleteUser(
    p_UserID IN NUMBER
) IS
    v_User  varchar2(250);
          BEGIN
    if IsUserExists(p_UserID) then
        select Login  into v_User from USERS;
    EXECUTE IMMEDIATE 'drop USER ' || v_User || ' cascade';
    DELETE FROM Users WHERE ID = p_UserID;
    COMMIT;
                            DBMS_OUTPUT.PUT_LINE('DeleteUser: успешное удаление пользователя');
    else
        DBMS_OUTPUT.PUT_LINE('DeleteUser: пользователь с заданным ID не найден');
    end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры DeleteUser: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END DeleteUser;

      PROCEDURE UpdateMovie(
    p_MovieID IN NUMBER,
    p_Title IN VARCHAR2,
    p_Genre IN VARCHAR2,
    p_Director IN VARCHAR2,
    p_Description IN CLOB,
    p_Duration IN NUMBER,
    p_Poster IN VARCHAR2,
    p_Trailer IN VARCHAR2
) IS
         v_count NUMBER;
         file_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(file_exception, -22288);
         check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);

BEGIN
    if IsMovieExists(p_MovieID) then
        select count(*) into v_count from MOVIES where TITLE = p_Title;
        if v_count = 0 then
    UPDATE Movies
    SET
        Title = p_Title,
        Genre = p_Genre,
        Director = p_Director,
        Description = p_Description,
        Duration = p_Duration,
        Poster = BFILENAME('POSTER_DIR', p_Poster),
        Trailer = BFILENAME('TRAILER_DIR', p_Trailer)
    WHERE ID = p_MovieID;
    COMMIT;
    else
        DBMS_OUTPUT.PUT_LINE('Фильм с заданным названием уже существует');
        end if;
    else
        DBMS_OUTPUT.PUT_LINE('Фильм с заданным ID не найден');
    end if;
EXCEPTION
WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите параметры корректно');
     WHEN file_exception THEN
      DBMS_OUTPUT.PUT_LINE('Файл постера или трейлера не найден');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры UpdateMovie: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END UpdateMovie;

      PROCEDURE UpdateHall(
    p_HallID IN NUMBER,
    p_HallName IN VARCHAR2,
    p_RowsCount IN NUMBER,
    p_SeatsCount IN NUMBER
) IS
          v_count number;
           check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);
BEGIN
    if IsHallExists(p_HallID) then
        select count(*) into v_count from HALLS where HALLNAME = p_HallName;
        if v_count = 0 then
    UPDATE Halls
    SET
        HallName = p_HallName,
        RowsCount = p_RowsCount,
        SeatsCount = p_SeatsCount
    WHERE ID = p_HallID;
    COMMIT;
    else
            DBMS_OUTPUT.PUT_LINE('Зал с заданным названием уже существует');
        end if;
    else
            DBMS_OUTPUT.PUT_LINE('Зал с заданным ID не найден');
    end if;
EXCEPTION
        WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите параметры корректно');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры UpdateHall: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END UpdateHall;

      PROCEDURE UpdateSession(
    p_SessionID IN NUMBER,
    p_MovieID IN NUMBER,
    p_HallID IN NUMBER,
    p_StartTime IN varchar2
) IS
          check_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(check_exception, -02290);
date_exception EXCEPTION;
        PRAGMA EXCEPTION_INIT(date_exception, -01861);
BEGIN
    if IsSessionExists(p_SessionID) and IsMovieExists(p_MovieID) and IsHallExists(p_HallID) then
            if (SYSDATE < TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS'))  then
            if ISDATEVALID(TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS'),p_MovieID, p_HallID) then
    UPDATE Sessions
    SET
        MovieID = p_MovieID,
        HallID = p_HallID,
        StartTime = TO_DATE(p_StartTime, 'YYYY-MM-DD HH24:MI:SS')
    WHERE ID = p_SessionID;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Успешное обнавление сеанса');
    else
            DBMS_OUTPUT.PUT_LINE('В это время в зале уже заблокирован сеанс');
        end if;
    else
         DBMS_OUTPUT.PUT_LINE('Заданная дата уже прошла');
        end if;
    else
        DBMS_OUTPUT.PUT_LINE('Задайте корректные ID');
    end if;
EXCEPTION
WHEN check_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите параметры корректно');
      WHEN date_exception THEN
      DBMS_OUTPUT.PUT_LINE('Введите корректную дату');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка при выполнении процедуры UpdateSession: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END UpdateSession;

END admin_package;







