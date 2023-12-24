CREATE OR REPLACE PACKAGE user_package AS
    FUNCTION IsMovieExists(p_ID IN NUMBER) RETURN BOOLEAN;
    FUNCTION IsSessionExists(p_ID IN NUMBER) RETURN BOOLEAN;
    FUNCTION IsReservationExists(p_ID IN NUMBER) RETURN BOOLEAN;
    PROCEDURE GetFreeSeatsForSession(
        p_SessionID IN NUMBER
    );
    procedure GetScheduleForNextWeek;
    PROCEDURE MakeReservation(
        p_SessionID IN NUMBER,
        p_RowNumber IN NUMBER,
        p_SeatNumber IN NUMBER
    );
        PROCEDURE BuyTicket(
        p_SessionID IN NUMBER,
        p_RowNumber IN NUMBER,
        p_SeatNumber IN NUMBER
    );
        PROCEDURE UpdateReservationStatus(
    p_ReservationID IN NUMBER);
    PROCEDURE GetMovieByID(
            p_ID IN NUMBER);
    PROCEDURE ViewUserReservations;
    PROCEDURE CancelReservation(
        p_ReservationID IN NUMBER
    );

    FUNCTION OpenPoster(
        p_movie_id IN NUMBER
    ) RETURN BLOB;

    FUNCTION OpenTrailer(
        p_movie_id IN NUMBER
    ) RETURN BLOB;

    CURSOR c_SessionsByDate(p_Date VARCHAR2) IS
        SELECT
            M.Title AS MovieTitle,
            S.StartTime AS SessionDate,
            H.HallName
        FROM
            Sessions S
            JOIN Movies M ON S.MovieID = M.ID
            JOIN Halls H ON S.HallID = H.ID
        WHERE
            TRUNC(S.StartTime) = TRUNC(TO_DATE(p_Date, 'YYYY-MM-DD'));

        PROCEDURE ViewSessionsByDate(
        p_Date IN VARCHAR2
    );
END user_package;
commit;
CREATE OR REPLACE PACKAGE BODY user_package AS
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

    PROCEDURE GetFreeSeatsForSession(
        p_SessionID IN NUMBER
    ) IS
        v_RowCount NUMBER;
        v_SeatCount NUMBER;
        v_count NUMBER;
    BEGIN
        if(IsSessionExists(p_SessionID)) then
        SELECT RowsCount INTO v_RowCount FROM Halls WHERE ID = (Select HALLID from SESSIONS where SESSIONS.ID = p_SessionID);
        SELECT SeatsCount INTO v_SeatCount FROM Halls WHERE ID = (Select HALLID from SESSIONS where SESSIONS.ID = p_SessionID);

        FOR v_RowNumber IN 1..v_RowCount LOOP
            DBMS_OUTPUT.PUT('Свободные места ряда ' || v_RowNumber || ': ');

            FOR v_SeatNumber IN 1..v_SeatCount LOOP
                SELECT COUNT(*)
                INTO v_count
                FROM Reservations
                WHERE SessionID = p_SessionID
                  AND RowNumber = v_RowNumber
                  AND SeatNumber = v_SeatNumber;

                IF v_count = 0 THEN
                    IF v_SeatNumber = v_SeatCount THEN
                        DBMS_OUTPUT.PUT(v_SeatNumber);
                    ELSE
                        DBMS_OUTPUT.PUT(v_SeatNumber || ', ');
                    END IF;
                END IF;
            END LOOP;
            DBMS_OUTPUT.NEW_LINE;
        END LOOP;
        else
            DBMS_OUTPUT.PUT_LINE('Сеанса с заданным ID не существует');
        end if;
    END GetFreeSeatsForSession;

    PROCEDURE MakeReservation(
        p_SessionID IN NUMBER,
        p_RowNumber IN NUMBER,
        p_SeatNumber IN NUMBER
    ) IS
        v_UserName VARCHAR2(50);
        v_UserID NUMBER;
        v_count NUMBER;
        v_maxrows NUMBER;
        v_maxseats Number;
    BEGIN
        if(IsSessionExists(p_SessionID)) then
        v_UserName := USER;
        SELECT ID INTO v_UserID FROM Users WHERE lower(Login) = lower(v_UserName);

        SELECT COUNT(*) INTO v_count FROM Reservations
        WHERE SessionID = p_SessionID AND ROWNUMBER = p_RowNumber AND SeatNumber = p_SeatNumber;

        select rowscount into v_maxrows from HALLS inner join SESSIONS on HALLS.ID = SESSIONS.HALLID
        where SESSIONS.ID = p_SessionID;

        select SEATSCOUNT into v_maxseats from HALLS inner join SESSIONS on HALLS.ID = SESSIONS.HALLID
        where SESSIONS.ID = p_SessionID;

        if v_maxrows < p_RowNumber then
                         DBMS_OUTPUT.PUT_LINE( 'Такого ряда не существует');
        ELSIF v_maxseats < p_SeatNumber THEN
                         DBMS_OUTPUT.PUT_LINE( 'Такого места не существует');
        ELSIF v_count > 0 THEN
                        DBMS_OUTPUT.PUT_LINE('Извините, это место уже занято, выберите другое');
        ELSE
            INSERT INTO Reservations (SessionID, UserID, ROWNUMBER, SeatNumber, STATUS)
            VALUES (p_SessionID, v_UserID, p_RowNumber, p_SeatNumber,'Забронирован');
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Билет успешно забронирован');
        END IF;
        else
            DBMS_OUTPUT.PUT_LINE('Сеанса с заданным ID не существует');
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка при бронировании: ' || SQLERRM);
            ROLLBACK;
            RAISE;
    END MakeReservation;

     PROCEDURE BuyTicket(
        p_SessionID IN NUMBER,
        p_RowNumber IN NUMBER,
        p_SeatNumber IN NUMBER
    ) IS
        v_UserName VARCHAR2(50);
        v_UserID NUMBER;
        v_count NUMBER;
        v_maxrows NUMBER;
        v_maxseats Number;
    BEGIN
        if(IsSessionExists(p_SessionID)) then
        v_UserName := USER;
        SELECT ID INTO v_UserID FROM Users WHERE lower(Login) = lower(v_UserName);

        SELECT COUNT(*) INTO v_count FROM Reservations
        WHERE SessionID = p_SessionID AND ROWNUMBER = p_RowNumber AND SeatNumber = p_SeatNumber;

        select rowscount into v_maxrows from HALLS inner join SESSIONS on HALLS.ID = SESSIONS.HALLID
        where SESSIONS.ID = p_SessionID;

        select SEATSCOUNT into v_maxseats from HALLS inner join SESSIONS on HALLS.ID = SESSIONS.HALLID
        where SESSIONS.ID = p_SessionID;

        if v_maxrows < p_RowNumber then
                         DBMS_OUTPUT.PUT_LINE( 'Такого ряда не существует');
        ELSIF v_maxseats < p_SeatNumber THEN
                         DBMS_OUTPUT.PUT_LINE( 'Такого места не существует');
        ELSIF v_count > 0 THEN
                        DBMS_OUTPUT.PUT_LINE('Извините, это место уже занято, выберите другое');
        ELSE
            INSERT INTO Reservations (SessionID, UserID, ROWNUMBER, SeatNumber, STATUS)
            VALUES (p_SessionID, v_UserID, p_RowNumber, p_SeatNumber,'Куплен');
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Билет успешно забронирован');
        END IF;
        else
            DBMS_OUTPUT.PUT_LINE('Сеанса с заданным ID не существует');
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка при бронировании: ' || SQLERRM);
            ROLLBACK;
            RAISE;
    END BuyTicket;

    PROCEDURE UpdateReservationStatus(
    p_ReservationID IN NUMBER
) IS
        v_satus varchar2(30);
BEGIN
    if (IsReservationExists(p_ReservationID)) then
        select STATUS into v_satus from RESERVATIONS where ID = p_ReservationID;
        if(v_satus = 'Забронирован') then
    UPDATE Reservations
    SET Status = 'Куплен'
    WHERE RESERVATIONS.ID = p_ReservationID;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Вы успешно купили билет');
    else
        DBMS_OUTPUT.PUT_LINE('Вы уже купили билет');
        end if;
    else
    DBMS_OUTPUT.PUT_LINE('У вас нет заданной брони');
        end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error updating reservation status: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END UpdateReservationStatus;


    PROCEDURE CancelReservation(
        p_ReservationID IN NUMBER
    ) IS
        v_UserName VARCHAR2(50);
        v_UserID NUMBER;
        v_count NUMBER;
    BEGIN
        if IsReservationExists(p_ReservationID) then
        v_UserName := USER;
        SELECT ID INTO v_UserID FROM USERS WHERE lower(LOGIN) = lower(v_UserName);
        SELECT COUNT(*) INTO v_count FROM RESERVATIONS WHERE USERID = v_UserID AND RESERVATIONS.ID = p_ReservationID;

        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('У вас нет билета на данный сеанс');
        ELSE
            DELETE FROM RESERVATIONS WHERE ID = p_ReservationID;
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Билет успешно отменен');
        END IF;
        else
                DBMS_OUTPUT.PUT_LINE('Билет с заданным ID не найдено');
            end if;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка при отмене бронирования: ' || SQLERRM);
            ROLLBACK;
    END CancelReservation;


        PROCEDURE ViewUserReservations
    IS
            v_UserName VARCHAR2(50);
            v_count NUMBER;
            v_UserID NUMBER;
    BEGIN
        v_UserName := USER;
        SELECT ID INTO v_UserID FROM USERS WHERE lower(LOGIN) = lower(v_UserName);
        SELECT COUNT(*) INTO v_count FROM RESERVATIONS WHERE USERID = v_UserID;
        if v_count = 0 then
            DBMS_OUTPUT.PUT_LINE('У вас еще нет билетов');
        end if;
        FOR reservation IN (
            SELECT
                M.Title AS MovieTitle,
                S.StartTime AS SessionDate,
                R.RowNumber,
                R.SeatNumber,
                R.STATUS
            FROM
                Reservations R
                JOIN Sessions S ON R.SessionID = S.ID
                JOIN Movies M ON S.MovieID = M.ID
            WHERE
                R.UserID = v_UserID
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                reservation.MovieTitle ||
                '       ' || TO_CHAR(reservation.SessionDate, 'DD-MON-YYYY HH24:MI') ||
                '  Ряд: ' || reservation.RowNumber ||
                '  Место: ' || reservation.SeatNumber||
                '  Статус: ' || reservation.STATUS
            );
        END LOOP;
    END ViewUserReservations;

    FUNCTION OpenPoster(
        p_movie_id IN NUMBER
    ) RETURN BLOB IS
        v_poster BLOB;
    BEGIN
        if(IsMovieExists(p_movie_id)) then
        SELECT Poster INTO v_poster
        FROM Movies
        WHERE ID = p_movie_id;
        RETURN v_poster;
        else

        DBMS_OUTPUT.PUT_LINE('Ошибка OpenPoster:  Фильм с заданным ID не найден');
          return EMPTY_BLOB();
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка OpenPoster: ' || SQLERRM);
            RETURN NULL;
    END OpenPoster;

    FUNCTION OpenTrailer(
        p_movie_id IN NUMBER
    ) RETURN BLOB IS
        v_trailer BLOB;
    BEGIN
        if(IsMovieExists(p_movie_id)) then
        SELECT TRAILER INTO v_trailer
        FROM Movies
        WHERE ID = p_movie_id;
        RETURN v_trailer;
        else
            DBMS_OUTPUT.PUT_LINE('Ошибка OpenTrailer: фильм с заданным ID не найден');
             return EMPTY_BLOB();
        end if;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка OpenTrailer: ' || SQLERRM);
            RETURN NULL;
    END OpenTrailer;

  PROCEDURE ViewSessionsByDate(
    p_Date IN VARCHAR2
) IS
    data_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(data_exception, -1861);
      data_exception1 EXCEPTION;
    PRAGMA EXCEPTION_INIT(data_exception1, -1843);
        data_exception2 EXCEPTION;
    PRAGMA EXCEPTION_INIT(data_exception2, -1830);
    found_sessions BOOLEAN := FALSE;
BEGIN

    if (TO_DATE(p_Date, 'YYYY-MM-DD') > sysdate) then
    FOR session_info IN c_SessionsByDate(p_Date) LOOP
        IF session_info.MovieTitle IS NOT NULL AND
           session_info.SessionDate IS NOT NULL AND
           session_info.HallName IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE(
                session_info.MovieTitle ||
                '     ' || TO_CHAR(session_info.SessionDate, 'DD-MON-YYYY HH24:MI') ||
                '  Зал: ' || session_info.HallName
            );
            found_sessions := TRUE;
        END IF;
    END LOOP;
    IF NOT found_sessions THEN
        DBMS_OUTPUT.PUT_LINE('В данную день сеансов не запланировано');
    END IF;
 else
                DBMS_OUTPUT.PUT_LINE('Заданная дата уже прошла');
     end if;
EXCEPTION
    WHEN data_exception THEN
        DBMS_OUTPUT.PUT_LINE('Введите значение даты корректно');
         WHEN data_exception1 THEN
        DBMS_OUTPUT.PUT_LINE('Введите значение даты корректно.');
         WHEN data_exception2 THEN
        DBMS_OUTPUT.PUT_LINE('Введите значение даты корректно');
END ViewSessionsByDate;



            PROCEDURE GetScheduleForNextWeek IS
            v_StartDate DATE;
            v_EndDate DATE;
        BEGIN
            v_StartDate := TRUNC(SYSDATE);
            v_EndDate := TRUNC(SYSDATE) + 6;
                    DBMS_OUTPUT.PUT_LINE('РАСПИСАНИЕ');
                    DBMS_OUTPUT.PUT_LINE(RPAD('—', 29, '—'));

           FOR movie_rec IN (
        SELECT DISTINCT M.Title
        FROM Movies M
        JOIN Sessions S ON M.ID = S.MovieID
        WHERE TRUNC(S.StartTime) BETWEEN v_StartDate AND v_EndDate
        ORDER BY M.Title
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(movie_rec.Title);
        if movie_rec.TITLE is not null then
        FOR session_rec IN (
            SELECT S.StartTime
            FROM Sessions S
            WHERE S.MovieID = (SELECT ID FROM Movies WHERE Title = movie_rec.Title)
                AND TRUNC(S.StartTime) BETWEEN v_StartDate AND v_EndDate
            ORDER BY S.StartTime
        ) LOOP
            DBMS_OUTPUT.PUT(TO_CHAR(session_rec.StartTime, 'Day')||'  ');
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(session_rec.StartTime, 'DD.MM.YYYY HH24:MI:SS'));
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(RPAD('—', 32, '—'));
        DBMS_OUTPUT.NEW_LINE;
        else
            DBMS_OUTPUT.PUT_LINE(('Расписание не найдено'));
            end if;
    END LOOP;
        END GetScheduleForNextWeek;

              PROCEDURE GetMovieByID(
    p_ID IN NUMBER
) IS
    v_MovieID NUMBER;
    v_Title VARCHAR2(255);
    v_Genre VARCHAR2(100);
    v_Director VARCHAR2(100);
    v_Description CLOB;
    v_Duration NUMBER;
BEGIN
    if (IsMovieExists(p_ID)) then
    SELECT ID, TITLE, Genre, Director, Description, Duration
    INTO v_MovieID, v_Title, v_Genre, v_Director, v_Description, v_Duration
    FROM Movies
    WHERE Movies.ID = p_ID;

    IF v_MovieID IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_MovieID);
        DBMS_OUTPUT.PUT_LINE('Название: ' || v_Title);
        DBMS_OUTPUT.PUT_LINE('Жанр: ' || v_Genre);
        DBMS_OUTPUT.PUT_LINE('Режиссер: ' || v_Director);
        DBMS_OUTPUT.PUT_LINE('Описание: ' || v_Description);
        DBMS_OUTPUT.PUT_LINE('Продолжительность: ' || v_Duration || ' минут');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Фильм не найден');
    END IF;
    else
                DBMS_OUTPUT.PUT_LINE('Фильм c заданным ID не найден');
        end if;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END GetMovieByID;


END user_package;

BEGIN
    ADMIN_DATABASE.user_package.MakeReservation(1, 3, 4);
END;
BEGIN
    ADMIN_DATABASE.user_package.GETFREESEATSFORSESSION(1);
END;
begin
    ADMIN_DATABASE.USER_PACKAGE.CANCELRESERVATION(22);
end;
begin
    ADMIN_DATABASE.USER_PACKAGE.VIEWUSERRESERVATIONS();
end;
begin
    ADMIN_DATABASE.USER_PACKAGE.VIEWSESSIONSBYDATE('2023-12-04');
end;
BEGIN
    ADMIN_DATABASE.USER_PACKAGE.GETSCHEDULEFORNEXTWEEK();
end;
BEGIN
    ADMIN_DATABASE.USER_PACKAGE.GETMOVIEBYID(1);
end;

DECLARE
   deptno_remaining EXCEPTION;
   PRAGMA EXCEPTION_INIT(deptno_remaining, -00201);
begin
    admin_package.AddMovie('qqqqq','Genre','Director','Description','qq','foto.jpg', 'video.mp4');
    exception
    WHEN deptno_remaining THEN
      DBMS_OUTPUT.PUT_LINE('Нарушение ограничений целостности данных!');
    when others then
        DBMS_OUTPUT.PUT_LINE('Один или несколько параметров равны нулю');
end;






