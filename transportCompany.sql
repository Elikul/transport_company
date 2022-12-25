--Установить расширение PostGIS

-- Включить PostGIS (начиная с 3.0 содержит только геометрию/географию)
CREATE EXTENSION postgis;
-- включить поддержку растра (для 3+)
CREATE EXTENSION postgis_raster;
-- Включить топологию
CREATE EXTENSION postgis_topology;
-- Включить PostGIS Advanced 3D
-- и другие алгоритмы геообработки
-- sfcgal доступен не во всех дистрибутивах
CREATE EXTENSION postgis_sfcgal;
-- нечеткое сопоставление, необходимое для Tiger
CREATE EXTENSION fuzzystrmatch;
-- стандартизатор на основе правил
CREATE EXTENSION address_standardizer;
-- пример набора данных правила
CREATE EXTENSION address_standardizer_data_us;
-- Включить US Tiger Geocoder
CREATE EXTENSION postgis_tiger_geocoder;


-- создание, удаление, изменение БД "Транспортное предприятие"

-- DROP DATABASE IF EXISTS "TransportCompany";

CREATE DATABASE "TransportCompany"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1252'
    LC_CTYPE = 'Russian_Russia.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

ALTER DATABASE "TransportCompany"
    SET search_path TO "$user", public, topology, tiger;

-- создание, удаление схемы и права

-- DROP SCHEMA IF EXISTS public ;

CREATE SCHEMA IF NOT EXISTS public
    AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public
    IS 'standard public schema';

GRANT USAGE ON SCHEMA public TO PUBLIC;

GRANT ALL ON SCHEMA public TO pg_database_owner;


-- создание, удаление и изменение последовательности для автоматического заполнения идентификатора водителя

-- DROP SEQUENCE IF EXISTS public."Drivers_id_seq";

CREATE SEQUENCE IF NOT EXISTS public."Drivers_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1
    OWNED BY "Drivers".id;

ALTER SEQUENCE public."Drivers_id_seq"
    OWNER TO postgres;


-- создание, удаление и изменение последовательности для автоматического заполнения идентификатора маршрута

-- DROP SEQUENCE IF EXISTS public."Route_id_seq";

CREATE SEQUENCE IF NOT EXISTS public."Route_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1
    OWNED BY "Route".id;

ALTER SEQUENCE public."Route_id_seq"
    OWNER TO postgres;



-- создание, удаление и изменение последовательности для автоматического заполнения идентификатора транспортного средства

-- DROP SEQUENCE IF EXISTS public."Vehicle_id_seq";

CREATE SEQUENCE IF NOT EXISTS public."Vehicle_id_seq"
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1
    OWNED BY "Vehicle".id;

ALTER SEQUENCE public."Vehicle_id_seq"
    OWNER TO postgres;


-- создание, удаление и изменение таблицы "Транспортное средство"

 -- DROP TABLE IF EXISTS public."Vehicle";

CREATE TABLE IF NOT EXISTS public."Vehicle"
(
    id integer NOT NULL DEFAULT nextval('"Vehicle_id_seq"'::regclass),
    "technicalPassport" jsonb NOT NULL,
    CONSTRAINT "Vehicle_pkey" PRIMARY KEY (id),
    CONSTRAINT "Vehicle_technicalPassport_key" UNIQUE ("technicalPassport")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."Vehicle"
    OWNER to postgres;



-- создание, удаление и изменение таблицы "Остановки"

-- DROP TABLE IF EXISTS public."BusStop";

CREATE TABLE IF NOT EXISTS public."BusStop"
(
    "busstopName" character varying(40) COLLATE pg_catalog."default" NOT NULL,
    coordinates geometry(Point,26910) NOT NULL,
    CONSTRAINT "BusStop_pkey" PRIMARY KEY ("busstopName")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."BusStop"
    OWNER to postgres;


-- создание и удаление индекса для координат остановок

-- DROP INDEX IF EXISTS public.busstop_gix;

CREATE INDEX IF NOT EXISTS busstop_gix
    ON public."BusStop" USING gist
    (coordinates)
    TABLESPACE pg_default;



-- создание, удаление и изменение таблицы "Маршруты"

-- DROP TABLE IF EXISTS public."Route";

CREATE TABLE IF NOT EXISTS public."Route"
(
    id integer NOT NULL DEFAULT nextval('"Route_id_seq"'::regclass),
    "numberRoute" character varying(5) COLLATE pg_catalog."default" NOT NULL,
    length real NOT NULL,
    "numberOfBusstop" integer NOT NULL,
    CONSTRAINT "Route_pkey" PRIMARY KEY (id),
    CONSTRAINT "Route_numberRoute_key" UNIQUE ("numberRoute"),
    CONSTRAINT "positiveLength" CHECK (length > 0::double precision),
    CONSTRAINT "minBusstop" CHECK ("numberOfBusstop" >= 2)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."Route"
    OWNER to postgres;



-- создание, удаление и изменение таблицы "Остановки на маршрутах"

-- DROP TABLE IF EXISTS public."BusStopOnTheRoute";

CREATE TABLE IF NOT EXISTS public."BusStopOnTheRoute"
(
    "idRoute" integer NOT NULL,
    "busStopName" character varying(40) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "busStopOnTheRoute_pkey" PRIMARY KEY ("idRoute", "busStopName"),
    CONSTRAINT "busStopOnTheRoute_busStopName_fkey" FOREIGN KEY ("busStopName")
        REFERENCES public."BusStop" ("busstopName") MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT "busStopOnTheRoute_idRoute_fkey" FOREIGN KEY ("idRoute")
        REFERENCES public."Route" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."BusStopOnTheRoute"
    OWNER to postgres;


-- создание, удаление и изменение таблицы "Водители"


 -- DROP TABLE IF EXISTS public."Drivers";

CREATE TABLE IF NOT EXISTS public."Drivers"
(
    id integer NOT NULL DEFAULT nextval('"Drivers_id_seq"'::regclass),
    "fullName" character varying(60) COLLATE pg_catalog."default" NOT NULL,
    birthday date,
    category character varying(3)[] COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "Drivers_pkey" PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."Drivers"
    OWNER to postgres;



-- создание, удаление и изменение таблицы "Рейсы"

-- DROP TABLE IF EXISTS public."BusTrips";

CREATE TABLE IF NOT EXISTS public."BusTrips"
(
    timing timestamp without time zone NOT NULL,
    "vehicleId" integer NOT NULL,
    "driverId" integer NOT NULL,
    "routeId" integer NOT NULL,
    revenue numeric,
    CONSTRAINT "BusTrips_pkey" PRIMARY KEY ("vehicleId", "driverId", "routeId"),
    CONSTRAINT "BusTrips_driverId_fkey" FOREIGN KEY ("driverId")
        REFERENCES public."Drivers" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT "BusTrips_routeId_fkey" FOREIGN KEY ("routeId")
        REFERENCES public."Route" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT "BusTrips_vehicleId_fkey" FOREIGN KEY ("vehicleId")
        REFERENCES public."Vehicle" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT "positiveRevenue" CHECK (revenue >= 0::numeric)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public."BusTrips"
    OWNER to postgres;



-- создание, удаление и изменение процедуры добавления одной остановки в таблицу "Остановки"

-- DROP PROCEDURE IF EXISTS public.addbusstop(character varying, geometry);

CREATE OR REPLACE PROCEDURE public.addbusstop(
	IN "_busstopName" character varying,
	IN _coordinates geometry)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    insert into public."BusStop"("busstopName", coordinates)
    values ("_busstopName", _coordinates);
END;
$BODY$;

ALTER PROCEDURE public.addbusstop(character varying, geometry)
    OWNER TO postgres;



-- создание, удаление, изменение процедуры заполнения таблицы "Остановки" данными

-- DROP PROCEDURE IF EXISTS public.filltablebusstop();

CREATE OR REPLACE PROCEDURE public.filltablebusstop(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    CALL AddBusStop('ЯМЗ', ST_GeomFromText('POINT(57.646997 39.850673)', 26910));
    CALL AddBusStop('Областная онкологическая больница', ST_GeomFromText('POINT(57.640081 39.856833)', 26910));
    CALL AddBusStop('Площадь Карла Маркса', ST_GeomFromText('POINT(57.636343 39.866502)', 26910));
    CALL AddBusStop('Советская улица', ST_GeomFromText('POINT(57.639914 39.875262)', 26910));
    CALL AddBusStop('Октябрьская площадь', ST_GeomFromText('POINT(57.638169 39.884107)', 26910));
    CALL AddBusStop('Дачная улица', ST_GeomFromText('POINT(57.644224 39.910436)', 26910));
    CALL AddBusStop('Школа № 50', ST_GeomFromText('POINT(57.644233 39.910403)', 26910));
    CALL AddBusStop('Школа № 46', ST_GeomFromText('POINT(57.638172 39.925519)', 26910));
    CALL AddBusStop('8-й переулок Маяковского', ST_GeomFromText('POINT(57.638208 39.925519)', 26910));
    CALL AddBusStop('Медсанчасть ЯЗДА', ST_GeomFromText('POINT(57.629571 39.936309)', 26910));
    CALL AddBusStop('Университетский городок', ST_GeomFromText('POINT(57.626590 39.940127)', 26910));
    CALL AddBusStop('Шоссейная улица', ST_GeomFromText('POINT(57.613302 39.942262)', 26910));
    CALL AddBusStop('Средний посёлок', ST_GeomFromText('POINT(57.607061 39.950427)', 26910));
    CALL AddBusStop('Школа № 47', ST_GeomFromText('POINT(57.607560 39.959325)', 26910));
    CALL AddBusStop('1-я Больничная улица', ST_GeomFromText('POINT(57.608251 39.972216)', 26910));
    CALL AddBusStop('Школа № 51', ST_GeomFromText('POINT(57.608627 39.979204)', 26910));
    CALL AddBusStop('Нижний посёлок', ST_GeomFromText('POINT(57.608877 39.983189)', 26910));
    CALL AddBusStop('Студенческий городок', ST_GeomFromText('POINT(57.621780 39.927338)', 26910));
    CALL AddBusStop('Красная площадь', ST_GeomFromText('POINT(57.632453 39.887929)', 26910));
    CALL AddBusStop('Линейная улица', ST_GeomFromText('POINT(57.648001 39.926475)', 26910));
    CALL AddBusStop('Красноборская улица', ST_GeomFromText('POINT(57.652541 39.936034)', 26910));
    CALL AddBusStop('Проспект Машиностроителей', ST_GeomFromText('POINT(57.654151 39.941497)', 26910));
    CALL AddBusStop('Проезд Доброхотова', ST_GeomFromText('POINT(57.653346 39.944228)', 26910));
    CALL AddBusStop('Кинотеатр Аврора', ST_GeomFromText('POINT(57.651003 39.947779)', 26910));
    CALL AddBusStop('Улица Саукова', ST_GeomFromText('POINT(57.647635 39.951876)', 26910));
    CALL AddBusStop('Улица Папанина', ST_GeomFromText('POINT(57.645219 39.955017)', 26910));
    CALL AddBusStop('Улица Сахарова', ST_GeomFromText('POINT(57.639141 39.962527)', 26910));
    CALL AddBusStop('Школа № 48', ST_GeomFromText('POINT(57.642436 39.958704)', 26910));
    CALL AddBusStop('Хутор', ST_GeomFromText('POINT(57.636285 39.966078)', 26910));
    CALL AddBusStop('ЯЗДА', ST_GeomFromText('POINT(57.621193 39.967717)', 26910));
    CALL AddBusStop('Машприбор', ST_GeomFromText('POINT(57.615624 39.963620)', 26910));
    CALL AddBusStop('Залесская улица', ST_GeomFromText('POINT(57.614525 39.953241)', 26910));
    CALL AddBusStop('Торговый переулок', ST_GeomFromText('POINT(57.625101 39.885419)', 26910));
    CALL AddBusStop('Республиканская улица', ST_GeomFromText('POINT(57.633595 39.878915)', 26910));
    CALL AddBusStop('Улица Победы', ST_GeomFromText('POINT(57.634505 39.873826)', 26910));
    CALL AddBusStop('Ярославль-Главный', ST_GeomFromText('POINT(57.625935 39.835948)', 26910));
    CALL AddBusStop('Полиграфкомбинат', ST_GeomFromText('POINT(57.627215 39.843961)', 26910));
    CALL AddBusStop('Дом обуви', ST_GeomFromText('POINT(57.629410 39.849416)', 26910));
    CALL AddBusStop('Улица Кудрявцева', ST_GeomFromText('POINT(57.630964 39.853166)', 26910));
    CALL AddBusStop('Юбилейная площадь', ST_GeomFromText('POINT(57.633433 39.860326)', 26910));
    CALL AddBusStop('Сабанеевская улица', ST_GeomFromText('POINT(57.629371 39.968558)', 26910));
END;
$BODY$;

ALTER PROCEDURE public.filltablebusstop()
    OWNER TO postgres;

 -- заполнить данными таблицу "Остановки"
 CALL filltablebusstop();


-- создание, удаление и изменение процедуры добавления одного маршрута в таблицу "Маршруты"

 -- DROP PROCEDURE IF EXISTS public.addroute(character varying, integer, real);

CREATE OR REPLACE PROCEDURE public.addroute(
	IN "_numberRoute" character varying,
	IN "_numberOfBusstop" integer,
	IN _length real)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	insert into public."Route"("numberRoute", "numberOfBusstop", length) 
    values ("_numberRoute", "_numberOfBusstop", _length)
	ON CONFLICT DO NOTHING;
END;
$BODY$;

ALTER PROCEDURE public.addroute(character varying, integer, real)
    OWNER TO postgres;



-- создание, удаление, изменение процедуры заполнения таблицы "Маршруты" данными

-- DROP PROCEDURE IF EXISTS public.filltableroute();

CREATE OR REPLACE PROCEDURE public.filltableroute(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    CALL AddRoute('22', 17, 12.80);
	CALL AddRoute('22c', 9, 7.10);
	CALL AddRoute('12', 18, 12.20);
	CALL AddRoute('39', 25, 14.90);
	CALL AddRoute('30', 23, 12.80);
END;
$BODY$;

ALTER PROCEDURE public.filltableroute()
    OWNER TO postgres;

 -- заполнить данными таблицу "Маршруты"
 CALL filltableroute();



-- создание, удаление и изменение процедуры добавления одной остановке на маршруте в таблицу "Остановки на маршрутах"

 -- DROP PROCEDURE IF EXISTS public.addbusstopontheroute(integer, character varying);

CREATE OR REPLACE PROCEDURE public.addbusstopontheroute(
	IN "_idRoute" integer,
	IN "_busStopName" character varying)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    insert into public."BusStopOnTheRoute"("idRoute", "busStopName") 
    values ("_idRoute", "_busStopName")
    ON CONFLICT DO NOTHING;                                          
END;
$BODY$;
ALTER PROCEDURE public.addbusstopontheroute(integer, character varying)
    OWNER TO postgres;



-- создание, удаление, изменение процедуры заполнения таблицы "Остановки на маршрутах" данными

-- DROP PROCEDURE IF EXISTS public.filltablebusstopontheroute();

CREATE OR REPLACE PROCEDURE public.filltablebusstopontheroute(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    CALL AddBusStopOnTheRoute(31, 'ЯМЗ');
    CALL AddBusStopOnTheRoute(31, 'Областная онкологическая больница');
    CALL AddBusStopOnTheRoute(31, 'Площадь Карла Маркса');
    CALL AddBusStopOnTheRoute(31, 'Советская улица');
    CALL AddBusStopOnTheRoute(31, 'Октябрьская площадь');
    CALL AddBusStopOnTheRoute(31, 'Дачная улица');
    CALL AddBusStopOnTheRoute(31, 'Школа № 50');
    CALL AddBusStopOnTheRoute(31, 'Школа № 46');
    CALL AddBusStopOnTheRoute(31, '8-й переулок Маяковского');
    CALL AddBusStopOnTheRoute(31, 'Медсанчасть ЯЗДА');
    CALL AddBusStopOnTheRoute(31, 'Университетский городок');
    CALL AddBusStopOnTheRoute(31, 'Шоссейная улица');
    CALL AddBusStopOnTheRoute(31, 'Средний посёлок');
    CALL AddBusStopOnTheRoute(31, 'Школа № 47');
    CALL AddBusStopOnTheRoute(31, '1-я Больничная улица');
    CALL AddBusStopOnTheRoute(31, 'Школа № 51');
    CALL AddBusStopOnTheRoute(31, 'Нижний посёлок');
    CALL AddBusStopOnTheRoute(32, 'Красная площадь');
    CALL AddBusStopOnTheRoute(32, 'Октябрьская площадь');
    CALL AddBusStopOnTheRoute(32, 'Дачная улица');
    CALL AddBusStopOnTheRoute(32, 'Школа № 50');
    CALL AddBusStopOnTheRoute(32, 'Школа № 46');
    CALL AddBusStopOnTheRoute(32, '8-й переулок Маяковского');
    CALL AddBusStopOnTheRoute(32, 'Медсанчасть ЯЗДА');
    CALL AddBusStopOnTheRoute(32, 'Университетский городок');
    CALL AddBusStopOnTheRoute(32, 'Студенческий городок');
    CALL AddBusStopOnTheRoute(33, 'Торговый переулок');
    CALL AddBusStopOnTheRoute(33, 'Красная площадь');
    CALL AddBusStopOnTheRoute(33, 'Республиканская улица');
    CALL AddBusStopOnTheRoute(33, 'Улица Победы');
    CALL AddBusStopOnTheRoute(33, 'Октябрьская площадь');
    CALL AddBusStopOnTheRoute(33, 'Дачная улица');
    CALL AddBusStopOnTheRoute(33, 'Школа № 50');
    CALL AddBusStopOnTheRoute(33, 'Школа № 46');
    CALL AddBusStopOnTheRoute(33, '8-й переулок Маяковского');
    CALL AddBusStopOnTheRoute(33, 'Медсанчасть ЯЗДА');
    CALL AddBusStopOnTheRoute(33, 'Университетский городок');
    CALL AddBusStopOnTheRoute(33, 'Шоссейная улица');
    CALL AddBusStopOnTheRoute(33, 'Средний посёлок');
    CALL AddBusStopOnTheRoute(33, 'Школа № 47');
    CALL AddBusStopOnTheRoute(33, '1-я Больничная улица');
    CALL AddBusStopOnTheRoute(33, 'Школа № 51');
    CALL AddBusStopOnTheRoute(33, 'Нижний посёлок');
    CALL AddBusStopOnTheRoute(34, 'Школа № 50');
    CALL AddBusStopOnTheRoute(34, 'Школа № 46');
    CALL AddBusStopOnTheRoute(34, '8-й переулок Маяковского');
    CALL AddBusStopOnTheRoute(34, 'Медсанчасть ЯЗДА');
    CALL AddBusStopOnTheRoute(34, 'Университетский городок');
    CALL AddBusStopOnTheRoute(34, 'Студенческий городок');                                           
    CALL AddBusStopOnTheRoute(34, 'Линейная улица');
    CALL AddBusStopOnTheRoute(34, 'Красноборская улица');
    CALL AddBusStopOnTheRoute(34, 'Проспект Машиностроителей'); 
    CALL AddBusStopOnTheRoute(34, 'Проезд Доброхотова');
    CALL AddBusStopOnTheRoute(34, 'Кинотеатр Аврора');
    CALL AddBusStopOnTheRoute(34, 'Улица Саукова');
    CALL AddBusStopOnTheRoute(34, 'Улица Папанина');
    CALL AddBusStopOnTheRoute(34, 'Улица Сахарова');
    CALL AddBusStopOnTheRoute(34, 'Школа № 48');
    CALL AddBusStopOnTheRoute(34, 'Хутор'); 
    CALL AddBusStopOnTheRoute(34, 'Сабанеевская улица');    
    CALL AddBusStopOnTheRoute(34, 'ЯЗДА');
    CALL AddBusStopOnTheRoute(34, 'Машприбор'); 
    CALL AddBusStopOnTheRoute(34, 'Залесская улица');       
    CALL AddBusStopOnTheRoute(34, 'Средний посёлок');
    CALL AddBusStopOnTheRoute(34, 'Школа № 47');
    CALL AddBusStopOnTheRoute(34, '1-я Больничная улица');
    CALL AddBusStopOnTheRoute(34, 'Школа № 51');
    CALL AddBusStopOnTheRoute(34, 'Нижний посёлок');
    CALL AddBusStopOnTheRoute(35, 'Ярославль-Главный');
    CALL AddBusStopOnTheRoute(35, 'Полиграфкомбинат');
    CALL AddBusStopOnTheRoute(35, 'Дом обуви'); 
    CALL AddBusStopOnTheRoute(35, 'Улица Кудрявцева');
    CALL AddBusStopOnTheRoute(35, 'Юбилейная площадь');
    CALL AddBusStopOnTheRoute(35, 'Площадь Карла Маркса');
    CALL AddBusStopOnTheRoute(35, 'Советская улица');
    CALL AddBusStopOnTheRoute(35, 'Октябрьская площадь');
    CALL AddBusStopOnTheRoute(35, 'Дачная улица');
    CALL AddBusStopOnTheRoute(35, 'Школа № 50');
    CALL AddBusStopOnTheRoute(35, 'Линейная улица');
    CALL AddBusStopOnTheRoute(35, 'Красноборская улица');
    CALL AddBusStopOnTheRoute(35, 'Проспект Машиностроителей'); 
    CALL AddBusStopOnTheRoute(35, 'Проезд Доброхотова');
    CALL AddBusStopOnTheRoute(35, 'Кинотеатр Аврора');
    CALL AddBusStopOnTheRoute(35, 'Улица Саукова');
    CALL AddBusStopOnTheRoute(35, 'Улица Папанина');
    CALL AddBusStopOnTheRoute(35, 'Улица Сахарова');
    CALL AddBusStopOnTheRoute(35, 'Школа № 48');
    CALL AddBusStopOnTheRoute(35, 'Хутор'); 
    CALL AddBusStopOnTheRoute(35, 'Сабанеевская улица');    
    CALL AddBusStopOnTheRoute(35, 'ЯЗДА');
    CALL AddBusStopOnTheRoute(35, 'Машприбор');                                          
END;
$BODY$;

ALTER PROCEDURE public.filltablebusstopontheroute()
    OWNER TO postgres;

 -- заполнить данными таблицу "Остановки на маршрутах"

 CALL filltablebusstopontheroute();


-- создание, удаление и изменение процедуры добавления одного водителя в таблицу "Водители"

 -- DROP PROCEDURE IF EXISTS public.adddriver(character varying, character varying[], date);

CREATE OR REPLACE PROCEDURE public.adddriver(
	IN "_fullName" character varying,
	IN _category character varying[],
	IN _birthday date DEFAULT NULL::date)
LANGUAGE 'sql'
AS $BODY$
    insert into public."Drivers"("fullName", category, birthday) 
    values ("_fullName", _category, _birthday)
$BODY$;

ALTER PROCEDURE public.adddriver(character varying, character varying[], date)
    OWNER TO postgres;



-- создание, удаление, изменение процедуры заполнения таблицы "Водители" данными

-- DROP PROCEDURE IF EXISTS public.filltabledrivers();

CREATE OR REPLACE PROCEDURE public.filltabledrivers(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    CALL AddDriver('Иванов Олег Васильевич', '{"B", "D"}', 'January 8, 1989');
	CALL AddDriver('Петрова Елизавета Игоревна', '{"D", "Tm"}', 'August 23, 1994');
	CALL AddDriver('Каталов Василий Петрович', '{"D"}');
	CALL AddDriver('Носков Илья Владимирович', '{"D", "Tb"}', 'September 12, 1974');
	CALL AddDriver('Кириллова Эмма Игнатьевна', '{"B", "D"}', 'May 10, 1990');
	CALL AddDriver('Шубин Вячеслав Евгеньевич', '{"D"}');
END;
$BODY$;

ALTER PROCEDURE public.filltabledrivers()
    OWNER TO postgres;


 -- заполнить данными таблицу "Водители"

 CALL filltabledrivers();



-- создание, удаление и изменение процедуры добавления одного транспортного средства в таблицу "Транспортное средство"

 -- DROP PROCEDURE IF EXISTS public.addvehicle(jsonb);

CREATE OR REPLACE PROCEDURE public.addvehicle(
	IN "_technicalPassport" jsonb)
LANGUAGE 'sql'
AS $BODY$
	insert into public."Vehicle"("technicalPassport") 
	values ("_technicalPassport")
$BODY$;
ALTER PROCEDURE public.addvehicle(jsonb)
    OWNER TO postgres;


-- создание, удаление, изменение процедуры заполнения таблицы "Транспортное средство" данными

-- DROP PROCEDURE IF EXISTS public.filltablevehicle();

CREATE OR REPLACE PROCEDURE public.filltablevehicle(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	CALL AddVehicle('{"passportNumber": "76 YX 933716", "registerSine": "X342XM76RUS", "release": 1990, "VIN": "XTA210530L1152417", "brend": "ВАЗ 21053", "engineNumber": "5020 YT4201", "color": "white", "isOnGIBDD": true}'::jsonb);
	CALL AddVehicle('{"passportNumber": "61 КА 417463", "registerSine": "C104VU76RUS", "release": 1995, "VIN": "WMAH06ZZX6M451416", "brend": "ЛИАЗ 677", "engineNumber": "4664 BT1588", "color": "blue", "isOnGIBDD": true}'::jsonb);
	CALL AddVehicle('{"passportNumber": "37 46 815308", "registerSine": "H238UV76RUS", "release": 2022, "VIN": "VVCSORXRCS4X00526", "brend": "ЛИАЗ 5292", "engineNumber": "4664 BT1588", "color": "white", "isOnGIBDD": true}'::jsonb);
	CALL AddVehicle('{"passportNumber": "82 26 066388", "registerSine": "A383BO76RUS", "release": 2008, "VIN": "XTC5320000H026879", "brend": "ЛИАЗ 6213", "engineNumber": "4664 BT1588", "color": "white", "isOnGIBDD": true}'::jsonb);
	CALL AddVehicle('{"passportNumber": "42 KУ 258404", "registerSine": "H208OY76RUS", "release": 2002, "VIN": "XWB3K32CDAA056459", "brend": "ЛИАЗ 6212", "engineNumber": "4664 BT1588", "color": "gray", "isOnGIBDD": true}'::jsonb);
	CALL AddVehicle('{"passportNumber": "42 ТХ 126975", "registerSine": "K512RR76RUS", "release": 2015, "VIN": "JMBSREA3A1Z000286", "brend": "ЛИАЗ 4292", "engineNumber": "4664 BT1588", "color": "greeen", "isOnGIBDD": true}'::jsonb);
END;
$BODY$;

ALTER PROCEDURE public.filltablevehicle()
    OWNER TO postgres;

-- заполнить данными таблицу "Транспортное средство"

 CALL filltablevehicle();


-- создание, удаление и изменение процедуры добавления одного рейса в таблицу "Рейсы"

 -- DROP PROCEDURE IF EXISTS public.addbustrips(timestamp without time zone, integer, integer, integer, numeric);

CREATE OR REPLACE PROCEDURE public.addbustrips(
	IN _timing timestamp without time zone,
	IN "_vehicleId" integer,
	IN "_driverId" integer,
	IN "_routeId" integer,
	IN _revenue numeric)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	insert into public."BusTrips"(timing, "vehicleId", "driverId", "routeId", revenue) 
    values (_timing, "_vehicleId", "_driverId", "_routeId", _revenue)
	ON CONFLICT DO NOTHING;											 
END;
$BODY$;

ALTER PROCEDURE public.addbustrips(timestamp without time zone, integer, integer, integer, numeric)
    OWNER TO postgres;


-- создание, удаление, изменение процедуры заполнения таблицы "Рейсы" данными


-- DROP PROCEDURE IF EXISTS public.filltablebustrips();

CREATE OR REPLACE PROCEDURE public.filltablebustrips(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
    CALL AddBusTrips('2022-12-08 06:32:00', 2, 1, 31, 0.0);	
	CALL AddBusTrips('2022-12-08 07:50:00', 3, 4, 31, 0.0);
	CALL AddBusTrips('2022-12-08 09:04:00', 4, 2, 31, 0.0);
	CALL AddBusTrips('2022-12-08 12:15:00', 2, 2, 32, 0.0);
	CALL AddBusTrips('2022-12-08 14:05:00', 5, 5, 32, 0.0);
	CALL AddBusTrips('2022-12-08 15:10:00', 3, 4, 32, 0.0);
	CALL AddBusTrips('2022-12-08 17:40:00', 6, 3, 33, 0.0);
	CALL AddBusTrips('2022-12-08 17:28:00', 1, 1, 33, 0.0);
	CALL AddBusTrips('2022-12-08 19:28:00', 6, 2, 33, 0.0);
	CALL AddBusTrips('2022-12-08 21:00:00', 2, 5, 34, 0.0);
	CALL AddBusTrips('2022-12-08 22:05:00', 4, 4, 34, 0.0);
	CALL AddBusTrips('2022-12-08 22:35:00', 2, 3, 34, 0.0);
END
$BODY$;
ALTER PROCEDURE public.filltablebustrips()
    OWNER TO postgres;


-- заполнить данными таблицу "Рейсы"

 CALL filltablebustrips();



 -- создание, удаление и изменение представления (VIEW) для просмотра остановок на маршрутах

 -- DROP VIEW public.busstopsroute;

CREATE OR REPLACE VIEW public.busstopsroute
 AS
 SELECT "Route"."numberRoute" AS "Номер маршрута",
    count("Route"."numberOfBusstop") AS "Количество остановок",
    avg("Route".length) AS "Длина маршрута",
    array_agg("BusStopOnTheRoute"."busStopName") AS "Остановки",
    array_agg("BusStop".coordinates) AS "Координаты остановок"
   FROM "Route"
     LEFT JOIN "BusStopOnTheRoute" ON "Route".id = "BusStopOnTheRoute"."idRoute"
     LEFT JOIN "BusStop" ON "BusStopOnTheRoute"."busStopName"::text = "BusStop"."busstopName"::text
  GROUP BY "Route"."numberRoute";

ALTER TABLE public.busstopsroute
    OWNER TO postgres;



 -- создание, удаление и изменение представления (VIEW) для просмотра рейсов


 -- DROP VIEW public.bustrips;

CREATE OR REPLACE VIEW public.bustrips
 AS
 SELECT "BusTrips".timing AS "Дата рейса",
    busstopsroute."Номер маршрута",
    busstopsroute."Количество остановок",
    busstopsroute."Остановки",
    "Drivers"."fullName" AS "Водитель",
    busstopsroute."Длина маршрута",
    "Vehicle"."technicalPassport" ->> 'registerSine'::text AS "Номер машины"
   FROM "BusTrips"
     LEFT JOIN "Vehicle" ON "BusTrips"."vehicleId" = "Vehicle".id
     LEFT JOIN "Drivers" ON "BusTrips"."driverId" = "Drivers".id
     LEFT JOIN "Route" ON "BusTrips"."routeId" = "Route".id
     LEFT JOIN busstopsroute ON "Route"."numberRoute"::text = busstopsroute."Номер маршрута"::text;

ALTER TABLE public.bustrips
    OWNER TO postgres;



-- создание, удаление и изменение процедуры для записи дохода за рейс

-- DROP PROCEDURE IF EXISTS public.updaterevenue(timestamp without time zone, numeric);

CREATE OR REPLACE PROCEDURE public.updaterevenue(
	IN _timing timestamp without time zone,
	IN _revenue numeric)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	UPDATE public."BusTrips" SET "revenue" = _revenue WHERE "timing" = _timing;				 
END;
$BODY$;

ALTER PROCEDURE public.updaterevenue(timestamp without time zone, numeric)
    OWNER TO postgres;


-- обновить колонку дохода за определённый рейс

CALL updaterevenue('2022-12-08 17:28:00', 3028)



-- пример поиска по json

SELECT "technicalPassport"->'color' as color FROM public."Vehicle" WHERE "technicalPassport" ? 'color' = true AND "id" = 4;										 
SELECT "technicalPassport"->'VIN' as VIN FROM public."Vehicle" WHERE "technicalPassport" ? 'VIN' = true;	
SELECT "technicalPassport"->'brend' as brend, "technicalPassport"->'release' as "release" FROM public."Vehicle" WHERE "technicalPassport" ? 'brend' = true AND "technicalPassport"->>'brend'::text LIKE '%ЛИАЗ%';

-- пример обновления значение ключа json

UPDATE public."Vehicle" SET  "technicalPassport" = jsonb_set("technicalPassport", '{isOnGIBDD}', 'false') WHERE "technicalPassport" ? 'isOnGIBDD' = true AND "id" = 4;

-- пример удаление ключа из json

UPDATE public."Vehicle" SET  "technicalPassport" = "technicalPassport" - 'isOnGIBDD'  WHERE "technicalPassport" ? 'isOnGIBDD' = true AND "id" = 6;


-- пример удаления строки из таблицы "Транспортное средство"

-- DELETE FROM public."Vehicle" WHERE "technicalPassport" ->> 'color' = 'brown';


-- примеры запросов по VIEW просмотра рейсов

-- все рейсы маршрута номер 12 
SELECT * FROM public."bustrips" WHERE "Номер маршрута" = '12';
-- посмотреть все даты рейсов водителя 'Иванов Олег Васильевич'
SELECT "Водитель", array_agg("Дата рейса") FROM public."bustrips" WHERE "Водитель" = 'Иванов Олег Васильевич' GROUP BY "Водитель";
-- посмотреть сколько водителей будут в конкретную дату на определённой машине
SELECT "Номер машины", count("Водитель") from public."bustrips" WHERE "Номер машины"='C104VU76RUS' AND CAST("Дата рейса" AS DATE) = '2022-12-08' GROUP BY "Номер машины";
-- количество остановок, которые проедет водитель Петрова Елизавета Игоревна
SELECT sum("Количество остановок") FROM public."bustrips" WHERE "Водитель" = 'Петрова Елизавета Игоревна' GROUP BY "Водитель";


-- POSTGIS

-- ближайшие пять остановок к остановке 'Студенческий городок'
SELECT t2."busstopName", ST_Distance(t1.coordinates, t2.coordinates) AS nearest FROM "BusStop" t1, "BusStop" t2 WHERE t1."busstopName" = 'Студенческий городок'  and t2."busstopName" <>
t1."busstopName" ORDER BY ST_Distance(t1.coordinates, t2.coordinates) LIMIT 5;
-- пересечение точек двух маршрутов
SELECT ST_AsText(ST_Intersection(unnest(t1."Координаты остановок"), unnest(t2."Координаты остановок"))) AS "intersection" FROM public."busstopsroute" t1, public."busstopsroute" t2 WHERE t1."Номер маршрута" = '39'  and t2."Номер маршрута" =
'22c';


-- создание, удаление и изменение маршрута в формате KML (разметка для карт)

-- DROP FUNCTION IF EXISTS public.getkmlroute(character varying);

CREATE OR REPLACE FUNCTION public.getkmlroute(
	_routenumber character varying)
    RETURNS text
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
   SELECT ST_AsKML(ST_MakeLine("Координаты остановок"), 4326) as kml FROM public."busstopsroute" WHERE "Номер маршрута" = _routeNumber;
$BODY$;

ALTER FUNCTION public.getkmlroute(character varying)
    OWNER TO postgres;


-- формат KML для каждого маршрута

COPY(SELECT * FROM getkmlroute('22')) to 'D:/owl/demid/semestr3/bd/22.kml';
COPY(SELECT * FROM getkmlroute('22c')) to 'D:/owl/demid/semestr3/bd/22c.kml';
COPY(SELECT * FROM getkmlroute('12')) to 'D:/owl/demid/semestr3/bd/12.kml';
COPY(SELECT * FROM getkmlroute('30')) to 'D:/owl/demid/semestr3/bd/30.kml';
COPY(SELECT * FROM getkmlroute('39')) to 'D:/owl/demid/semestr3/bd/39.kml';


-- создание и удаление роли "Администратор"

-- DROP ROLE IF EXISTS administrator;

CREATE ROLE administrator WITH
  LOGIN
  SUPERUSER
  INHERIT
  CREATEDB
  CREATEROLE
  REPLICATION
  ENCRYPTED PASSWORD 'SCRAM-SHA-256$4096:u/zhpvwjKDS8DDmDplP2Pg==$SDO2uNG3IKuH1fm9SPtrcB6a/cvrxRBhzFTmHU3a9kc=:CS5z8eCeFip9R75uMmDGrxGBm7HZg9E0hfJI9eMSjZE='; (admin)


-- создание и удаление роли "Диспетчер автобуса"

-- DROP ROLE IF EXISTS bus_dispatcher;

CREATE ROLE bus_dispatcher WITH
  LOGIN
  NOSUPERUSER
  NOINHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION
  ENCRYPTED PASSWORD 'SCRAM-SHA-256$4096:/rim6RzEn3a1YkyBAzTGkQ==$iYMXTShBGi5YBbKk9IdEwWO8TFxqyO2gYJqj75YF0ng=:8UbM+fjp3vxdHlSCnvmRPpLYwwNASAXnSYiU7tYPkaM=';


-- создание и удаление роли "Гость"

-- DROP ROLE IF EXISTS guest;

CREATE ROLE guest WITH
  NOLOGIN
  NOSUPERUSER
  NOINHERIT
  NOCREATEDB
  NOCREATEROLE
  NOREPLICATION;



-- предоставить доступ на чтение таблиц и последовательностей гостю

GRANT SELECT ON SEQUENCE public."Drivers_id_seq", public."Route_id_seq", public."Vehicle_id_seq"  TO guest;

GRANT SELECT ON TABLE public."BusStop", public."BusStopOnTheRoute", public."BusTrips", public."Drivers", public."Route", public."Vehicle", public.busstopsroute, public.bustrips TO guest;


-- предоставить доступ на запуск функций и процедур, на чтение, удаление, обновление и заполнение таблиц диспетчеру автобусов

GRANT EXECUTE ON FUNCTION public.getkmlroute(_routenumber character varying) TO bus_dispatcher;

GRANT EXECUTE ON PROCEDURE public.addbusstop(IN "_busstopName" character varying, IN _coordinates geometry), 
public.addbusstopontheroute(IN "_idRoute" integer, IN "_busStopName" character varying), 
public.addbustrips(IN _timing timestamp without time zone, IN "_vehicleId" integer, IN "_driverId" integer, IN "_routeId" integer, IN _revenue numeric), 
public.adddriver(IN "_fullName" character varying, IN _category character varying[], IN _birthday date), 
public.addroute(IN "_numberRoute" character varying, IN "_numberOfBusstop" integer, IN _length real), 
public.addvehicle(IN "_technicalPassport" jsonb), public.updaterevenue(IN _timing timestamp without time zone, IN _revenue numeric) TO bus_dispatcher;

GRANT SELECT, UPDATE ON SEQUENCE public."Drivers_id_seq", public."Route_id_seq", public."Vehicle_id_seq" TO bus_dispatcher;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE public."BusStop", public."BusStopOnTheRoute", public."BusTrips", 
public."Drivers", public."Route", public."Vehicle", public.busstopsroute, public.bustrips TO bus_dispatcher;



-- предоставить весь доступ над функциями, процедурами, последовательностями и таблицами администратору (в том числе и POSTGIS) c правом самому давать доступ на эти действия

GRANT EXECUTE ON FUNCTION public.__st_countagg_transfn(agg agg_count, rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_overview_constraint(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, factor integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint(cn name, sql text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._add_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_overview_constraint(ovschema name, ovtable name, ovcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint(rastschema name, rasttable name, cn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_alignment(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_extent(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_nodata_values(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_num_bands(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_out_db(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_pixel_types(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_regular_blocking(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._drop_raster_constraint_srid(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._overview_constraint(ov raster, factor integer, refschema name, reftable name, refcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._overview_constraint_info(ovschema name, ovtable name, ovcolumn name, OUT refschema name, OUT reftable name, OUT refcolumn name, OUT factor integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_deprecate(oldname text, newname text, version text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_index_extent(tbl regclass, col text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_pgsql_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_scripts_pgsql_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom geometry, mode text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._postgis_stats(tbl regclass, att_name text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_alignment(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_blocksize(rastschema name, rasttable name, rastcolumn name, axis text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_coverage_tile(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_extent(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_index(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_nodata_values(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_num_bands(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_out_db(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_pixel_types(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_regular_blocking(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_scale(rastschema name, rasttable name, rastcolumn name, axis character) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_spatially_unique(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_info_srid(rastschema name, rasttable name, rastcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_nodata_values(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_out_db(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._raster_constraint_pixel_types(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_3ddwithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_3dintersects(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_asgml(integer, geometry, integer, integer, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_aspect4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_asraster(geom geometry, scalex double precision, scaley double precision, width integer, height integer, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_asx3d(integer, geometry, integer, integer, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_bestsrid(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_bestsrid(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_clip(rast raster, nband integer[], geom geometry, nodataval double precision[], crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_colormap(rast raster, nband integer, colormap text, method text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_contains(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_contains(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_containsproperly(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_containsproperly(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_convertarray4ma(value double precision[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_count(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_countagg_finalfn(agg agg_count) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, nband integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_countagg_transfn(agg agg_count, rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_coveredby(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_coveredby(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_coveredby(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_covers(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_covers(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_covers(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_crosses(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dfullywithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dfullywithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_distancetree(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_distancetree(geography, geography, double precision, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_distanceuncached(geography, geography, double precision, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_distanceuncached(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_distanceuncached(geography, geography, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dwithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dwithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dwithin(geog1 geography, geog2 geography, tolerance double precision, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dwithinuncached(geography, geography, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_dwithinuncached(geography, geography, double precision, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_equals(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_expand(geography, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_gdalwarp(rast raster, algorithm text, maxerr double precision, srid integer, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, width integer, height integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_geomfromgml(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_grayscale4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_hillshade4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_histogram(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, width double precision[], "right" boolean, min double precision, max double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_intersects(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_intersects(geom geometry, rast raster, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_intersects(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_linecrossingdirection(line1 geometry, line2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_longestline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_mapalgebra(rastbandargset rastbandarg[], expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_mapalgebra(rastbandargset rastbandarg[], callbackfunc regprocedure, pixeltype text, distancex integer, distancey integer, extenttype text, customextent raster, mask double precision[], weighted boolean, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_maxdistance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_neighborhood(rast raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_orderingequals(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_overlaps(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_overlaps(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_pixelascentroids(rast raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_pixelaspolygons(rast raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_pointoutside(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_quantile(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_rastertoworldcoord(rast raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_reclass(rast raster, VARIADIC reclassargset reclassarg[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_roughness4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_samealignment_finalfn(agg agg_samealignment) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_samealignment_transfn(agg agg_samealignment, rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], hasnosetvalue boolean, nosetvalue double precision, keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_slope4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_sortablehash(geom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_summarystats(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_summarystats_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_summarystats_transfn(internal, raster, integer, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_summarystats_transfn(internal, raster, integer, boolean, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_summarystats_transfn(internal, raster, boolean, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_tile(rast raster, width integer, height integer, nband integer[], padwithnodata boolean, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_touches(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_touches(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_tpi4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_tri4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_transfn(internal, raster, unionarg[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_transfn(internal, raster, integer, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_transfn(internal, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_transfn(internal, raster, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_union_transfn(internal, raster, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_valuecount(rast raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_voronoi(g1 geometry, clip geometry, tolerance double precision, return_polygons boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_within(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_within(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._st_worldtorastercoord(rast raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public._updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addauth(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addoverviewconstraints(ovschema name, ovtable name, ovcolumn name, refschema name, reftable name, refcolumn name, ovfactor integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addoverviewconstraints(ovtable name, ovcolumn name, reftable name, refcolumn name, ovfactor integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addrasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.addrasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2d(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2d_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2d_out(box2d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2df_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box2df_out(box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3d(box2d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3d(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3d_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3d_out(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.box3dtobox(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.bytea(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.bytea(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.bytea(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.checkauth(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.checkauth(text, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.contains_2d(geometry, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.contains_2d(box2df, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.contains_2d(box2df, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.difference(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.disablelongtransactions() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dmetaphone(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dmetaphone_alt(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropgeometrytable(table_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropoverviewconstraints(ovtable name, ovcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.dropoverviewconstraints(ovschema name, ovtable name, ovcolumn name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.droprasterconstraints(rasttable name, rastcolumn name, VARIADIC constraints text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, srid boolean, scale_x boolean, scale_y boolean, blocksize_x boolean, blocksize_y boolean, same_alignment boolean, regular_blocking boolean, num_bands boolean, pixel_types boolean, nodata_values boolean, out_db boolean, extent boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.droprasterconstraints(rastschema name, rasttable name, rastcolumn name, VARIADIC constraints text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.enablelongtransactions() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.equals(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.find_srid(character varying, character varying, character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography(geography, integer, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_analyze(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_cmp(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_distance_knn(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_eq(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_ge(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_compress(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_consistent(internal, geography, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_decompress(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_distance(internal, geography, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_penalty(internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_picksplit(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_same(box2d, box2d, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gist_union(bytea, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_gt(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_in(cstring, oid, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_le(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_lt(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_out(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_overlaps(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_recv(internal, oid, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_send(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_choose_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_compress_nd(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_config_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_spgist_picksplit_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_typmod_in(cstring[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geography_typmod_out(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(point) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(box2d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(geometry, integer, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(path) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(polygon) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_above(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_analyze(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_below(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_cmp(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_contained_3d(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_contained_by_raster(geometry, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_contains(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_contains_3d(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_contains_nd(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_distance_box(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_distance_centroid(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_distance_centroid_nd(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_distance_cpa(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_eq(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_ge(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_compress_2d(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_compress_nd(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_consistent_2d(internal, geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_consistent_nd(internal, geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_decompress_2d(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_decompress_nd(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_distance_2d(internal, geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_distance_nd(internal, geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_picksplit_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_picksplit_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_same_2d(geom1 geometry, geom2 geometry, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_same_nd(geometry, geometry, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_sortsupport_2d(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_union_2d(bytea, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gist_union_nd(bytea, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_gt(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_hash(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_le(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_left(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_lt(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_out(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overabove(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overbelow(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overlaps(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overlaps_3d(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overlaps_nd(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overleft(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_overright(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_raster_contain(geometry, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_raster_overlap(geometry, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_recv(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_right(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_same(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_same_3d(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_same_nd(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_send(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_sortsupport(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_choose_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_choose_3d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_choose_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_compress_2d(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_compress_3d(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_compress_nd(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_config_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_config_3d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_config_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_picksplit_2d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_picksplit_3d(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_spgist_picksplit_nd(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_typmod_in(cstring[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_typmod_out(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_within(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometry_within_nd(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometrytype(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geometrytype(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geomfromewkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.geomfromewkt(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.get_proj4_from_srid(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.getkmlroute(_routenumber character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gettransactionid() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gidx_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gidx_out(gidx) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.is_contained_2d(box2df, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.is_contained_2d(geometry, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.is_contained_2d(box2df, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.json(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.jsonb(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.key_exists(some_json jsonb, outer_key text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.key_exists(some_json json, outer_key text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.levenshtein(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.levenshtein(text, text, integer, integer, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.levenshtein_less_equal(text, text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.levenshtein_less_equal(text, text, integer, integer, integer, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.lockrow(text, text, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.lockrow(text, text, text, text, timestamp without time zone) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.lockrow(text, text, text, timestamp without time zone) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.lockrow(text, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.longtransactionsenabled() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.metaphone(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_2d(box2df, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_2d(box2df, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_2d(geometry, box2df) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_geog(gidx, gidx) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_geog(gidx, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_geog(geography, gidx) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_nd(gidx, gidx) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_nd(gidx, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.overlaps_nd(geometry, gidx) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.parse_address(text, OUT num text, OUT street text, OUT street2 text, OUT address1 text, OUT city text, OUT state text, OUT zip text, OUT zipplus text, OUT country text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.path(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asflatgeobuf_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asgeobuf_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_combinefn(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_deserialfn(bytea, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_serialfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_accum_transfn(internal, geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_accum_transfn(internal, geometry, double precision, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_accum_transfn(internal, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_collect_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_makeline_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_polygonize_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_finalfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_serialfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.pgis_geometry_union_parallel_transfn(internal, geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.point(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.polygon(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.populate_geometry_columns(use_typmod boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_addbbox(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_dropbbox(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_extensions_upgrade() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_full_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_gdal_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_geos_noop(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_geos_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_getbbox(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_hasbbox(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_index_supportfn(internal) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_lib_build_date() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_lib_revision() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_lib_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_libjson_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_liblwgeom_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_libprotobuf_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_libxml_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_noop(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_noop(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_proj_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_raster_lib_build_date() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_raster_lib_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_raster_scripts_installed() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_scripts_build_date() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_scripts_installed() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_scripts_released() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_sfcgal_full_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_sfcgal_noop(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_sfcgal_scripts_installed() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_sfcgal_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_svn_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_transform_geometry(geom geometry, text, text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_typmod_dims(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_typmod_srid(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_typmod_type(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_wagyu_version() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_above(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_below(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_contain(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_contained(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_contained_by_geometry(raster, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_eq(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_geometry_contain(raster, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_geometry_overlap(raster, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_hash(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_left(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_out(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_overabove(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_overbelow(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_overlap(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_overleft(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_overright(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_right(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.raster_same(raster, raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.soundex(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.spheroid_in(cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.spheroid_out(spheroid) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3darea(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dclosestpoint(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dconvexhull(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3ddifference(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3ddistance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3ddwithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dintersection(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dintersects(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dlength(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dlineinterpolatepoint(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dlongestline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dmakebox(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dmaxdistance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dperimeter(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dshortestline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_3dunion(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(rast raster, index integer, pixeltype text, initialvalue double precision, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(rast raster, addbandargset addbandarg[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(rast raster, pixeltype text, initialvalue double precision, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(torast raster, fromrast raster, fromband integer, torastindex integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(torast raster, fromrasts raster[], fromband integer, torastindex integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(rast raster, index integer, outdbfile text, outdbindex integer[], nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addband(rast raster, outdbfile text, outdbindex integer[], index integer, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addmeasure(geometry, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_alphashape(g1 geometry, alpha double precision, allow_holes boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_angle(line1 geometry, line2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_angle(pt1 geometry, pt2 geometry, pt3 geometry, pt4 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxcount(rast raster, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxcount(rast raster, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxcount(rast raster, nband integer, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxcount(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxhistogram(rast raster, nband integer, sample_percent double precision, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approximatemedialaxis(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, nband integer, sample_percent double precision, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, sample_percent double precision, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, exclude_nodata_value boolean, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, nband integer, sample_percent double precision, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, sample_percent double precision, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxquantile(rast raster, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxsummarystats(rast raster, nband integer, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxsummarystats(rast raster, nband integer, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxsummarystats(rast raster, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_approxsummarystats(rast raster, exclude_nodata_value boolean, sample_percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_area(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_area(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_area(geog geography, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_area2d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asbinary(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asbinary(raster, outasin boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asbinary(geometry, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asbinary(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asbinary(geography, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asencodedpolyline(geom geometry, nprecision integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkb(geometry, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkb(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkt(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkt(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkt(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkt(geography, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asewkt(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgdalraster(rast raster, format text, options text[], srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgeojson(r record, geom_column text, maxdecimaldigits integer, pretty_bool boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgeojson(geog geography, maxdecimaldigits integer, options integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgeojson(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgeojson(geom geometry, maxdecimaldigits integer, options integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgml(geom geometry, maxdecimaldigits integer, options integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgml(version integer, geog geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgml(version integer, geom geometry, maxdecimaldigits integer, options integer, nprefix text, id text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgml(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asgml(geog geography, maxdecimaldigits integer, options integer, nprefix text, id text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ashexewkb(geometry, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ashexewkb(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ashexwkb(raster, outasin boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asjpeg(rast raster, nband integer, quality integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asjpeg(rast raster, nbands integer[], quality integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asjpeg(rast raster, nband integer, options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asjpeg(rast raster, nbands integer[], options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asjpeg(rast raster, options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_askml(geom geometry, maxdecimaldigits integer, nprefix text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_askml(geog geography, maxdecimaldigits integer, nprefix text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_askml(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aslatlontext(geom geometry, tmpl text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asmarc21(geom geometry, format text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asmvtgeom(geom geometry, bounds box2d, extent integer, buffer integer, clip_geom boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspect(rast raster, nband integer, pixeltype text, units text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspect(rast raster, nband integer, customextent raster, pixeltype text, units text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspng(rast raster, options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspng(rast raster, nbands integer[], compression integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspng(rast raster, nband integer, options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspng(rast raster, nband integer, compression integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aspng(rast raster, nbands integer[], options text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, width integer, height integer, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, width integer, height integer, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, pixeltype text, value double precision, nodataval double precision, upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text[], value double precision[], nodataval double precision[], skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, scalex double precision, scaley double precision, gridx double precision, gridy double precision, pixeltype text, value double precision, nodataval double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, ref raster, pixeltype text[], value double precision[], nodataval double precision[], touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, ref raster, pixeltype text, value double precision, nodataval double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asraster(geom geometry, width integer, height integer, pixeltype text[], value double precision[], nodataval double precision[], upperleftx double precision, upperlefty double precision, skewx double precision, skewy double precision, touched boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_assvg(geom geometry, rel integer, maxdecimaldigits integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_assvg(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_assvg(geog geography, rel integer, maxdecimaldigits integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astext(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astext(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astext(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astext(geography, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astiff(rast raster, compression text, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astiff(rast raster, nbands integer[], options text[], srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astiff(rast raster, options text[], srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astiff(rast raster, nbands integer[], compression text, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astwkb(geom geometry, prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_astwkb(geom geometry[], ids bigint[], prec integer, prec_z integer, prec_m integer, with_sizes boolean, with_boxes boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_aswkb(raster, outasin boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_asx3d(geom geometry, maxdecimaldigits integer, options integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_azimuth(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_azimuth(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_band(rast raster, nbands integer[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_band(rast raster, nbands text, delimiter character) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_band(rast raster, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandfilesize(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandfiletimestamp(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandisnodata(rast raster, band integer, forcechecking boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandisnodata(rast raster, forcechecking boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandmetadata(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandmetadata(rast raster, band integer[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandnodatavalue(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandpath(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bandpixeltype(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bdmpolyfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_bdpolyfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_boundary(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_boundingdiagonal(geom geometry, fits boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_box2dfromgeohash(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(geography, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(text, double precision, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(text, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(text, double precision, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(geography, double precision, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(geography, double precision, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(geom geometry, radius double precision, quadsegs integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buffer(geom geometry, radius double precision, options text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_buildarea(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_centroid(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_centroid(geography, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_centroid(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_chaikinsmoothing(geometry, integer, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_cleangeometry(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, geom geometry, crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, geom geometry, nodataval double precision[], crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, geom geometry, nodataval double precision, crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, nband integer[], geom geometry, nodataval double precision[], crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, nband integer, geom geometry, nodataval double precision, crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clip(rast raster, nband integer, geom geometry, crop boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clipbybox2d(geom geometry, box box2d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_closestpoint(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_closestpointofapproach(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clusterintersecting(geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_clusterwithin(geometry[], double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_collect(geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_collect(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_collectionextract(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_collectionextract(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_collectionhomogenize(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_colormap(rast raster, colormap text, method text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_colormap(rast raster, nband integer, colormap text, method text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_combinebbox(box2d, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_combinebbox(box3d, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_combinebbox(box3d, box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_constraineddelaunaytriangles(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_contains(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_contains(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_contains(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_containsproperly(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_containsproperly(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_containsproperly(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_contour(rast raster, bandnumber integer, level_interval double precision, level_base double precision, fixed_levels double precision[], polygonize boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_convexhull(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_convexhull(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coorddim(geometry geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_count(rast raster, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_count(rast raster, nband integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coveredby(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coveredby(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coveredby(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coveredby(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_coveredby(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_covers(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_covers(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_covers(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_covers(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_covers(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_cpawithin(geometry, geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_createoverview(tab regclass, col name, factor integer, algo text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_crosses(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_curvetoline(geom geometry, tol double precision, toltype integer, flags integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_delaunaytriangles(g1 geometry, tolerance double precision, flags integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dfullywithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dfullywithin(rast1 raster, rast2 raster, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dfullywithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_difference(geom1 geometry, geom2 geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dimension(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_disjoint(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_disjoint(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_disjoint(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distance(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distance(geog1 geography, geog2 geography, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distancecpa(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distancesphere(geom1 geometry, geom2 geometry, radius double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distancesphere(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distancespheroid(geom1 geometry, geom2 geometry, spheroid) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distancespheroid(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distinct4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_distinct4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dump(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumpaspolygons(rast raster, band integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumppoints(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumprings(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumpsegments(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumpvalues(rast raster, nband integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dumpvalues(rast raster, nband integer[], exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dwithin(text, text, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dwithin(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dwithin(rast1 raster, nband1 integer, rast2 raster, nband2 integer, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dwithin(rast1 raster, rast2 raster, distance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_dwithin(geog1 geography, geog2 geography, tolerance double precision, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_endpoint(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_envelope(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_envelope(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_equals(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_estimatedextent(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_estimatedextent(text, text, text, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(box box3d, dx double precision, dy double precision, dz double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(box3d, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(box box2d, dx double precision, dy double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(box2d, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(geom geometry, dx double precision, dy double precision, dz double precision, dm double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_expand(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_exteriorring(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_extrude(geometry, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_filterbym(geometry, double precision, double precision, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_findextent(text, text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_findextent(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_flipcoordinates(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_force2d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_force3d(geom geometry, zvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_force3dm(geom geometry, mvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_force3dz(geom geometry, zvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_force4d(geom geometry, zvalue double precision, mvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcecollection(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcecurve(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcelhr(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcepolygonccw(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcepolygoncw(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcerhr(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcesfs(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_forcesfs(geometry, version text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_frechetdistance(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_fromflatgeobuf(anyelement, bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_fromflatgeobuftotable(text, text, bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_fromgdalraster(gdaldata bytea, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_gdaldrivers(OUT idx integer, OUT short_name text, OUT long_name text, OUT can_read boolean, OUT can_write boolean, OUT create_options text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_generatepoints(area geometry, npoints integer, seed integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_generatepoints(area geometry, npoints integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geogfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geogfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geographyfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geohash(geog geography, maxchars integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geohash(geom geometry, maxchars integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomcollfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomcollfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomcollfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomcollfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geometricmedian(g geometry, tolerance double precision, max_iter integer, fail_if_not_converged boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geometryfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geometryfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geometryn(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geometrytype(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromewkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromewkt(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgeohash(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgeojson(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgeojson(jsonb) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgeojson(json) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgml(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromgml(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromkml(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfrommarc21(marc21xml text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromtwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geomfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_georeference(rast raster, format text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_geotransform(raster, OUT imag double precision, OUT jmag double precision, OUT theta_i double precision, OUT theta_ij double precision, OUT xoffset double precision, OUT yoffset double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_gmltosql(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_gmltosql(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_grayscale(rast raster, redband integer, greenband integer, blueband integer, extenttype text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_grayscale(rastbandargset rastbandarg[], extenttype text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hasarc(geometry geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hasnoband(rast raster, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_height(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hexagongrid(size double precision, bounds geometry, OUT geom geometry, OUT i integer, OUT j integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hillshade(rast raster, nband integer, pixeltype text, azimuth double precision, altitude double precision, max_bright double precision, scale double precision, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_hillshade(rast raster, nband integer, customextent raster, pixeltype text, azimuth double precision, altitude double precision, max_bright double precision, scale double precision, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_histogram(rast raster, nband integer, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_histogram(rast raster, nband integer, exclude_nodata_value boolean, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_histogram(rast raster, nband integer, bins integer, width double precision[], "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_histogram(rast raster, nband integer, exclude_nodata_value boolean, bins integer, "right" boolean, OUT min double precision, OUT max double precision, OUT count bigint, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_interiorringn(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_interpolatepoint(line geometry, point geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_interpolateraster(geom geometry, options text, rast raster, bandnumber integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, rast2 raster, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, returnband text, nodataval double precision[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, rast2 raster, nodataval double precision[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(geom1 geometry, geom2 geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, rast2 raster, returnband text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, returnband text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(geography, geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, rast2 raster, returnband text, nodataval double precision[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, nodataval double precision[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast raster, band integer, geomin geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast raster, geomin geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(rast1 raster, band1 integer, rast2 raster, band2 integer, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersection(geomin geometry, rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(rast raster, geom geometry, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(geog1 geography, geog2 geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(rast raster, nband integer, geom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(geom geometry, rast raster, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_intersects(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_invdistweight4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isclosed(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_iscollection(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_iscoveragetile(rast raster, coverage raster, tilewidth integer, tileheight integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isempty(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isempty(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isplanar(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ispolygonccw(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ispolygoncw(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isring(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_issimple(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_issolid(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvalid(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvalid(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvaliddetail(geom geometry, flags integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvalidreason(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvalidreason(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_isvalidtrajectory(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_length(geog geography, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_length(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_length(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_length2d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_length2dspheroid(geometry, spheroid) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_lengthspheroid(geometry, spheroid) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_letters(letters text, font json) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linecrossingdirection(line1 geometry, line2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefrommultipoint(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linefromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_lineinterpolatepoint(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_lineinterpolatepoints(geometry, double precision, repeat boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linelocatepoint(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linemerge(geometry, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linemerge(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linestringfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linestringfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linesubstring(geometry, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_linetocurve(geometry geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_longestline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_m(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makebox2d(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeemptycoverage(tilewidth integer, tileheight integer, width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeemptyraster(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeemptyraster(width integer, height integer, upperleftx double precision, upperlefty double precision, pixelsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeline(geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makeline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepoint(double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepoint(double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepointm(double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepolygon(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makepolygon(geometry, geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makesolid(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makevalid(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_makevalid(geom geometry, params text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast1 raster, rast2 raster, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rastbandargset rastbandarg[], callbackfunc regprocedure, pixeltype text, extenttype text, customextent raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast raster, nband integer[], callbackfunc regprocedure, pixeltype text, extenttype text, customextent raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast raster, nband integer, callbackfunc regprocedure, pixeltype text, extenttype text, customextent raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast1 raster, nband1 integer, rast2 raster, nband2 integer, callbackfunc regprocedure, pixeltype text, extenttype text, customextent raster, distancex integer, distancey integer, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast raster, nband integer, callbackfunc regprocedure, mask double precision[], weighted boolean, pixeltype text, extenttype text, customextent raster, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast raster, nband integer, pixeltype text, expression text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast raster, pixeltype text, expression text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebra(rast1 raster, band1 integer, rast2 raster, band2 integer, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebraexpr(rast1 raster, band1 integer, rast2 raster, band2 integer, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebraexpr(rast raster, band integer, pixeltype text, expression text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebraexpr(rast raster, pixeltype text, expression text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebraexpr(rast1 raster, rast2 raster, expression text, pixeltype text, extenttype text, nodata1expr text, nodata2expr text, nodatanodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast1 raster, rast2 raster, tworastuserfunc regprocedure, pixeltype text, extenttype text, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast1 raster, band1 integer, rast2 raster, band2 integer, tworastuserfunc regprocedure, pixeltype text, extenttype text, VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, band integer, onerastuserfunc regprocedure) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, onerastuserfunc regprocedure) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, onerastuserfunc regprocedure, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, pixeltype text, onerastuserfunc regprocedure) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, band integer, onerastuserfunc regprocedure, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, band integer, pixeltype text, onerastuserfunc regprocedure) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafct(rast raster, band integer, pixeltype text, onerastuserfunc regprocedure, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mapalgebrafctngb(rast raster, band integer, pixeltype text, ngbwidth integer, ngbheight integer, onerastngbuserfunc regprocedure, nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_max4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_max4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_maxdistance(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_maximuminscribedcircle(geometry, OUT center geometry, OUT nearest geometry, OUT radius double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mean4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mean4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_memsize(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_memsize(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_metadata(rast raster, OUT upperleftx double precision, OUT upperlefty double precision, OUT width integer, OUT height integer, OUT scalex double precision, OUT scaley double precision, OUT skewx double precision, OUT skewy double precision, OUT srid integer, OUT numbands integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_min4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_min4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minconvexhull(rast raster, nband integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mindist4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minimumboundingradius(geometry, OUT center geometry, OUT radius double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minimumclearance(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minimumclearanceline(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minkowskisum(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_minpossiblevalue(pixeltype text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mlinefromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mlinefromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mlinefromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mlinefromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpointfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpointfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpointfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpointfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpolyfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpolyfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpolyfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_mpolyfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multi(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multilinefromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multilinestringfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multilinestringfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipointfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipointfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipointfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipolyfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipolyfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipolygonfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_multipolygonfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ndims(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_nearestvalue(rast raster, pt geometry, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_nearestvalue(rast raster, band integer, pt geometry, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_nearestvalue(rast raster, band integer, columnx integer, rowy integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_nearestvalue(rast raster, columnx integer, rowy integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_neighborhood(rast raster, band integer, pt geometry, distancex integer, distancey integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_neighborhood(rast raster, band integer, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_neighborhood(rast raster, pt geometry, distancex integer, distancey integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_neighborhood(rast raster, columnx integer, rowy integer, distancex integer, distancey integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_node(g geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_normalize(geom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_notsamealignmentreason(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_npoints(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_nrings(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numbands(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numgeometries(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numinteriorring(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numinteriorrings(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numpatches(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_numpoints(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_offsetcurve(line geometry, distance double precision, params text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_optimalalphashape(g1 geometry, allow_holes boolean, nb_components integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_orderingequals(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_orientation(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_orientedenvelope(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_overlaps(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_overlaps(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_overlaps(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_patchn(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_perimeter(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_perimeter(geog geography, use_spheroid boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_perimeter2d(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelascentroid(rast raster, x integer, y integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelascentroids(rast raster, band integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelaspoint(rast raster, x integer, y integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelaspoints(rast raster, band integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelaspolygon(rast raster, x integer, y integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelaspolygons(rast raster, band integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelheight(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelofvalue(rast raster, nband integer, search double precision, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelofvalue(rast raster, search double precision, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelofvalue(rast raster, search double precision[], exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelofvalue(rast raster, nband integer, search double precision[], exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pixelwidth(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_point(double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_point(double precision, double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointfromgeohash(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointinsidecircle(geometry, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointn(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointonsurface(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_points(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polyfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polyfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polyfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polyfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygon(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygon(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygonfromtext(text, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygonfromtext(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygonfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygonfromwkb(bytea, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_polygonize(geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_project(geog geography, distance double precision, azimuth double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, nband integer, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, nband integer, exclude_nodata_value boolean, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, exclude_nodata_value boolean, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, nband integer, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, quantile double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantile(rast raster, nband integer, exclude_nodata_value boolean, quantiles double precision[], OUT quantile double precision, OUT value double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_quantizecoordinates(g geometry, prec_x integer, prec_y integer, prec_z integer, prec_m integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_range4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_range4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastertoworldcoord(rast raster, columnx integer, rowy integer, OUT longitude double precision, OUT latitude double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastertoworldcoordx(rast raster, xr integer, yr integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastertoworldcoordx(rast raster, xr integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastertoworldcoordy(rast raster, xr integer, yr integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastertoworldcoordy(rast raster, yr integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastfromhexwkb(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rastfromwkb(bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reclass(rast raster, reclassexpr text, pixeltype text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reclass(rast raster, nband integer, reclassexpr text, pixeltype text, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reclass(rast raster, VARIADIC reclassargset reclassarg[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reduceprecision(geom geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_relate(geom1 geometry, geom2 geometry, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_relate(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_relate(geom1 geometry, geom2 geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_relatematch(text, text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_removepoint(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_removerepeatedpoints(geom geometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resample(rast raster, scalex double precision, scaley double precision, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resample(rast raster, width integer, height integer, gridx double precision, gridy double precision, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resample(rast raster, ref raster, usescale boolean, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resample(rast raster, ref raster, algorithm text, maxerr double precision, usescale boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rescale(rast raster, scalexy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rescale(rast raster, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resize(rast raster, percentwidth double precision, percentheight double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resize(rast raster, width integer, height integer, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_resize(rast raster, width text, height text, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reskew(rast raster, skewx double precision, skewy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reskew(rast raster, skewxy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_retile(tab regclass, col name, ext geometry, sfx double precision, sfy double precision, tw integer, th integer, algo text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_reverse(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotate(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotate(geometry, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotate(geometry, double precision, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotatex(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotatey(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotatez(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_rotation(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_roughness(rast raster, nband integer, customextent raster, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_roughness(rast raster, nband integer, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_samealignment(ulx1 double precision, uly1 double precision, scalex1 double precision, scaley1 double precision, skewx1 double precision, skewy1 double precision, ulx2 double precision, uly2 double precision, scalex2 double precision, scaley2 double precision, skewx2 double precision, skewy2 double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_samealignment(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scale(geometry, geometry, origin geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scale(geometry, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scale(geometry, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scale(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scalex(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scaley(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_scroll(geometry, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_segmentize(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_segmentize(geog geography, max_segment_length double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setbandindex(rast raster, band integer, outdbindex integer, force boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setbandisnodata(rast raster, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setbandnodatavalue(rast raster, nodatavalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setbandnodatavalue(rast raster, band integer, nodatavalue double precision, forcechecking boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setbandpath(rast raster, band integer, outdbpath text, outdbindex integer, force boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_seteffectivearea(geometry, double precision, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setgeoreference(rast raster, georef text, format text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setgeoreference(rast raster, upperleftx double precision, upperlefty double precision, scalex double precision, scaley double precision, skewx double precision, skewy double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setgeotransform(rast raster, imag double precision, jmag double precision, theta_i double precision, theta_ij double precision, xoffset double precision, yoffset double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setm(rast raster, geom geometry, resample text, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setpoint(geometry, integer, geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setrotation(rast raster, rotation double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setscale(rast raster, scale double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setscale(rast raster, scalex double precision, scaley double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setskew(rast raster, skew double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setskew(rast raster, skewx double precision, skewy double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setsrid(geog geography, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setsrid(geom geometry, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setsrid(rast raster, srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setupperleft(rast raster, upperleftx double precision, upperlefty double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalue(rast raster, nband integer, geom geometry, newvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalue(rast raster, geom geometry, newvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalue(rast raster, band integer, x integer, y integer, newvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalue(rast raster, x integer, y integer, newvalue double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalues(rast raster, nband integer, geomvalset geomval[], keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], noset boolean[], keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, newvalueset double precision[], nosetvalue double precision, keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalues(rast raster, nband integer, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setvalues(rast raster, x integer, y integer, width integer, height integer, newvalue double precision, keepnodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_setz(rast raster, geom geometry, resample text, band integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_sharedpaths(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_shiftlongitude(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_shortestline(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_simplify(geometry, double precision, boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_simplify(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_simplifypolygonhull(geom geometry, vertex_fraction double precision, is_outer boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_simplifypreservetopology(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_simplifyvw(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_skewx(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_skewy(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_slope(rast raster, nband integer, customextent raster, pixeltype text, units text, scale double precision, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_slope(rast raster, nband integer, pixeltype text, units text, scale double precision, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snap(geom1 geometry, geom2 geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(geometry, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(geometry, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(geometry, double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, algorithm text, maxerr double precision, scalex double precision, scaley double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_snaptogrid(rast raster, gridx double precision, gridy double precision, scalexy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_split(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_squaregrid(size double precision, bounds geometry, OUT geom geometry, OUT i integer, OUT j integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_srid(geom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_srid(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_srid(geog geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_startpoint(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_stddev4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_stddev4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_straightskeleton(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_subdivide(geom geometry, maxvertices integer, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_sum4ma(value double precision[], pos integer[], VARIADIC userargs text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_sum4ma(matrix double precision[], nodatamode text, VARIADIC args text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_summary(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_summary(rast raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_summary(geography) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_summarystats(rast raster, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_summarystats(rast raster, nband integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_swapordinates(geom geometry, ords cstring) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_symdifference(geom1 geometry, geom2 geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_symmetricdifference(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tesselate(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tile(rast raster, width integer, height integer, padwithnodata boolean, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tile(rast raster, nband integer[], width integer, height integer, padwithnodata boolean, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tile(rast raster, nband integer, width integer, height integer, padwithnodata boolean, nodataval double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds geometry, margin double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_touches(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_touches(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_touches(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tpi(rast raster, nband integer, customextent raster, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tpi(rast raster, nband integer, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(geom geometry, to_proj text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(rast raster, srid integer, scalexy double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(geom geometry, from_proj text, to_proj text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(geometry, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(rast raster, srid integer, algorithm text, maxerr double precision, scalex double precision, scaley double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(geom geometry, from_proj text, to_srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(rast raster, srid integer, scalex double precision, scaley double precision, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transform(rast raster, alignto raster, algorithm text, maxerr double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_translate(geometry, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_translate(geometry, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_transscale(geometry, double precision, double precision, double precision, double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tri(rast raster, nband integer, customextent raster, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_tri(rast raster, nband integer, pixeltype text, interpolate_nodata boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_triangulatepolygon(g1 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_unaryunion(geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_union(geometry[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_union(geom1 geometry, geom2 geometry, gridsize double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_union(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_upperleftx(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_upperlefty(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_value(rast raster, pt geometry, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_value(rast raster, x integer, y integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_value(rast raster, band integer, pt geometry, exclude_nodata_value boolean, resample text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_value(rast raster, band integer, x integer, y integer, exclude_nodata_value boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rast raster, nband integer, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuecount(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, nband integer, exclude_nodata_value boolean, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalues double precision[], roundto double precision, OUT value double precision, OUT percent double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, nband integer, exclude_nodata_value boolean, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rast raster, nband integer, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_valuepercent(rastertable text, rastercolumn text, nband integer, searchvalue double precision, roundto double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_volume(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_voronoilines(g1 geometry, tolerance double precision, extend_to geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_voronoipolygons(g1 geometry, tolerance double precision, extend_to geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_width(raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_within(rast1 raster, rast2 raster) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_within(rast1 raster, nband1 integer, rast2 raster, nband2 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_within(geom1 geometry, geom2 geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_wkbtosql(wkb bytea) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_wkttosql(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoord(rast raster, longitude double precision, latitude double precision, OUT columnx integer, OUT rowy integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoord(rast raster, pt geometry, OUT columnx integer, OUT rowy integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordx(rast raster, xw double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordx(rast raster, xw double precision, yw double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordx(rast raster, pt geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordy(rast raster, pt geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordy(rast raster, xw double precision, yw double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_worldtorastercoordy(rast raster, yw double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_wrapx(geom geometry, wrap double precision, move double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_x(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_xmax(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_xmin(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_y(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ymax(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_ymin(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_z(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_zmax(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_zmflag(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.st_zmin(box3d) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.standardize_address(lextab text, gaztab text, rultab text, address text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.standardize_address(lextab text, gaztab text, rultab text, micro text, macro text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.text(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.text_soundex(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.unlockrows(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.updategeometrysrid(character varying, character varying, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.updaterastersrid(schema_name name, table_name name, column_name name, new_srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.updaterastersrid(table_name name, column_name name, new_srid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.addbusstop(IN "_busstopName" character varying, IN _coordinates geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.addbusstopontheroute(IN "_idRoute" integer, IN "_busStopName" character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.addbustrips(IN _timing timestamp without time zone, IN "_vehicleId" integer, IN "_driverId" integer, IN "_routeId" integer, IN _revenue numeric) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.adddriver(IN "_fullName" character varying, IN _category character varying[], IN _birthday date) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.addroute(IN "_numberRoute" character varying, IN "_numberOfBusstop" integer, IN _length real) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.addvehicle(IN "_technicalPassport" jsonb) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltablebusstop() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltablebusstopontheroute() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltablebustrips() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltabledrivers() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltableroute() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.filltablevehicle() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON PROCEDURE public.updaterevenue(IN _timing timestamp without time zone, IN _revenue numeric) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.checkauthtrigger() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION public.postgis_cache_bbox() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.count_words(character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.create_census_base_tables() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.cull_null(character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.diff_zip(zip1 character varying, zip2 character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.drop_dupe_featnames_generate_script() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.drop_indexes_generate_script(tiger_data_schema text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.drop_nation_tables_generate_script(param_schema text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.drop_state_tables_generate_script(param_state text, param_schema text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.end_soundex(character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.geocode(in_addy norm_addy, max_results integer, restrict_geom geometry, OUT addy norm_addy, OUT geomout geometry, OUT rating integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.geocode(input character varying, max_results integer, restrict_geom geometry, OUT addy norm_addy, OUT geomout geometry, OUT rating integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.geocode_address(parsed norm_addy, max_results integer, restrict_geom geometry, OUT addy norm_addy, OUT geomout geometry, OUT rating integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.geocode_intersection(roadway1 text, roadway2 text, in_state text, in_city text, in_zip text, num_results integer, OUT addy norm_addy, OUT geomout geometry, OUT rating integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.geocode_location(parsed norm_addy, restrict_geom geometry, OUT addy norm_addy, OUT geomout geometry, OUT rating integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.get_geocode_setting(setting_name text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.get_last_words(inputstring character varying, count integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.get_tract(loc_geom geometry, output_field text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.greatest_hn(fromhn character varying, tohn character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.includes_address(given_address integer, addr1 integer, addr2 integer, addr3 integer, addr4 integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.install_geocode_settings() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.install_missing_indexes() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.install_pagc_tables() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.interpolate_from_address(given_address integer, in_addr1 character varying, in_addr2 character varying, in_road geometry, in_side character varying, in_offset_m double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.is_pretype(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.least_hn(fromhn character varying, tohn character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.levenshtein_ignore_case(character varying, character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_generate_census_script(param_states text[], os text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_generate_nation_script(os text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_generate_script(param_states text[], os text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_load_staged_data(param_staging_table text, param_target_table text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_load_staged_data(param_staging_table text, param_target_table text, param_columns_exclude text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.loader_macro_replace(param_input text, param_keys text[], param_values text[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.location_extract(fullstreet character varying, stateabbrev character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.location_extract_countysub_exact(fullstreet character varying, stateabbrev character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.location_extract_countysub_fuzzy(fullstreet character varying, stateabbrev character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.location_extract_place_exact(fullstreet character varying, stateabbrev character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.location_extract_place_fuzzy(fullstreet character varying, stateabbrev character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.missing_indexes_generate_script() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.normalize_address(in_rawinput character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.nullable_levenshtein(character varying, character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.numeric_streets_equal(input_street character varying, output_street character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.pagc_normalize_address(in_rawinput character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.pprint_addy(input norm_addy) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.rate_attributes(dirpa character varying, dirpb character varying, streetnamea character varying, streetnameb character varying, streettypea character varying, streettypeb character varying, dirsa character varying, dirsb character varying, locationa character varying, locationb character varying, prequalabr character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.rate_attributes(dirpa character varying, dirpb character varying, streetnamea character varying, streetnameb character varying, streettypea character varying, streettypeb character varying, dirsa character varying, dirsb character varying, prequalabr character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.reverse_geocode(pt geometry, include_strnum_range boolean, OUT intpt geometry[], OUT addy norm_addy[], OUT street character varying[]) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.set_geocode_setting(setting_name text, setting_value text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.setsearchpathforinstall(a_schema_name text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.state_extract(rawinput character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.topology_load_tiger(toponame character varying, region_type character varying, region_id character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.utmzone(geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION tiger.zip_range(zip text, range_start integer, range_end integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._asgmledge(edge_id integer, start_node integer, end_node integer, line geometry, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._asgmlface(toponame text, face_id integer, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._asgmlnode(id integer, point geometry, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._checkedgelinking(curedge_edge_id integer, prevedge_edge_id integer, prevedge_next_left_edge integer, prevedge_next_right_edge integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._st_adjacentedges(atopology character varying, anode integer, anedge integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._st_mintolerance(ageom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._st_mintolerance(atopology character varying, ageom geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._validatetopologyedgelinking(bbox geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._validatetopologygetfaceshellmaximaledgering(atopology character varying, aface integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._validatetopologygetringedges(starting_edge integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology._validatetopologyrings(bbox geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addedge(atopology character varying, aline geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addface(atopology character varying, apoly geometry, force_new boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addnode(atopology character varying, apoint geometry, allowedgesplitting boolean, setcontainingface boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addtopogeometrycolumn(character varying, character varying, character varying, character varying, character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addtopogeometrycolumn(toponame character varying, schema character varying, tbl character varying, col character varying, ltype character varying, child integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.addtosearchpath(a_schema_name character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, visitedtable regclass) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, visitedtable regclass, nsprefix text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, options integer, vis regclass) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, nsprefix_in text, precision_in integer, options_in integer, visitedtable regclass, idprefix text, gmlver integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, opts integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, options integer, visitedtable regclass, idprefix text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.asgml(tg topogeometry, nsprefix text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.astopojson(tg topogeometry, edgemaptable regclass) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.cleartopogeom(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.copytopology(atopology character varying, newtopo character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopogeom(toponame character varying, tg_type integer, layer_id integer, tg_objs topoelementarray) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopogeom(toponame character varying, tg_type integer, layer_id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopology(character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopology(character varying, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopology(toponame character varying, srid integer, prec double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.createtopology(atopology character varying, srid integer, prec double precision, hasz boolean) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.droptopogeometrycolumn(schema character varying, tbl character varying, col character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.droptopology(atopology character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.equals(tg1 topogeometry, tg2 topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findlayer(layer_table regclass, feature_column name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findlayer(topology_id integer, layer_id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findlayer(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findlayer(schema_name name, table_name name, feature_column name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findtopology(text) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findtopology(integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findtopology(name, name, name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findtopology(regclass, name) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.findtopology(topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.geometry(topogeom topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.geometrytype(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getedgebypoint(atopology character varying, apoint geometry, tol1 double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getfacebypoint(atopology character varying, apoint geometry, tol1 double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getfacecontainingpoint(atopology text, apoint geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getnodebypoint(atopology character varying, apoint geometry, tol1 double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getnodeedges(atopology character varying, anode integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.getringedges(atopology character varying, anedge integer, maxedges integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopogeomelementarray(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopogeomelementarray(toponame character varying, layer_id integer, tgid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopogeomelements(toponame character varying, layerid integer, tgid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopogeomelements(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopologyid(toponame character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopologyname(topoid integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.gettopologysrid(toponame character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.intersects(tg1 topogeometry, tg2 topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.polygonize(toponame character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.populate_topology_layer() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.postgis_topology_scripts_installed() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.removeunusedprimitives(atopology text, bbox geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_addedgemodface(atopology character varying, anode integer, anothernode integer, acurve geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_addedgenewfaces(atopology character varying, anode integer, anothernode integer, acurve geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_addisoedge(atopology character varying, anode integer, anothernode integer, acurve geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_addisonode(atopology character varying, aface integer, apoint geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_changeedgegeom(atopology character varying, anedge integer, acurve geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_createtopogeo(atopology character varying, acollection geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_geometrytype(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_getfaceedges(toponame character varying, face_id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_getfacegeometry(toponame character varying, aface integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_inittopogeo(atopology character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_modedgeheal(toponame character varying, e1id integer, e2id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_modedgesplit(atopology character varying, anedge integer, apoint geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_moveisonode(atopology character varying, anode integer, apoint geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_newedgeheal(toponame character varying, e1id integer, e2id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_newedgessplit(atopology character varying, anedge integer, apoint geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_remedgemodface(toponame character varying, e1id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_remedgenewface(toponame character varying, e1id integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_remisonode(character varying, integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_removeisoedge(atopology character varying, anedge integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_removeisonode(atopology character varying, anode integer) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_simplify(tg topogeometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.st_srid(tg topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topoelementarray_append(topoelementarray, topoelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeo_addgeometry(atopology character varying, ageom geometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeo_addlinestring(atopology character varying, aline geometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeo_addpoint(atopology character varying, apoint geometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeo_addpolygon(atopology character varying, apoly geometry, tolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeom_addelement(tg topogeometry, el topoelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeom_addtopogeom(tgt topogeometry, src topogeometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topogeom_remelement(tg topogeometry, el topoelement) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.topologysummary(atopology character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.totopogeom(ageom geometry, atopology character varying, alayer integer, atolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.totopogeom(ageom geometry, tg topogeometry, atolerance double precision) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.validatetopology(toponame character varying, bbox geometry) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.validatetopologyrelation(toponame character varying) TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.layertrigger() TO administrator WITH GRANT OPTION;

GRANT EXECUTE ON FUNCTION topology.relationtrigger() TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public."Drivers_id_seq" TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public."Route_id_seq" TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public."Vehicle_id_seq" TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public.us_gaz_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public.us_lex_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE public.us_rules_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.addr_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.addrfeat_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.bg_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.county_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.cousub_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.edges_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.faces_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.featnames_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.pagc_gaz_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.pagc_lex_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.pagc_rules_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.place_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.state_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.tabblock_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.tract_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE tiger.zcta5_gid_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON SEQUENCE topology.topology_id_seq TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."BusStop" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."BusStopOnTheRoute" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."BusTrips" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."Drivers" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."Route" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public."Vehicle" TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.is_key_exists TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.spatial_ref_sys TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.us_gaz TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.us_lex TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.us_rules TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.busstopsroute TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.bustrips TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.geography_columns TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.geometry_columns TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.raster_columns TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE public.raster_overviews TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.addr TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.addrfeat TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.bg TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.county TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.county_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.countysub_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.cousub TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.direction_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.edges TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.faces TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.featnames TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.geocode_settings TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.geocode_settings_default TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.loader_lookuptables TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.loader_platform TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.loader_variables TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.pagc_gaz TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.pagc_lex TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.pagc_rules TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.place TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.place_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.secondary_unit_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.state TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.state_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.street_type_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.tabblock TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.tabblock20 TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.tract TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zcta5 TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zip_lookup TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zip_lookup_all TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zip_lookup_base TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zip_state TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE tiger.zip_state_loc TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE topology.layer TO administrator WITH GRANT OPTION;

GRANT ALL ON TABLE topology.topology TO administrator WITH GRANT OPTION;