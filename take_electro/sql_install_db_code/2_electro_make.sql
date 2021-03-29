
CREATE TABLE locations                  -- Объекты где установлен Electro
(
  ip          inet   NOT NULL,          -- IP-адрес SNMP-адаптера Electro
  location    text   NOT NULL UNIQUE,   -- Местонахождение Electro
  own         text   NOT NULL,          -- подведомственный Участок
  PRIMARY KEY ( ip )
);

UPDATE locations SET location = 'ПБ-45' WHERE location = 'ПБ-45 ';

INSERT INTO locations VALUES
('1.2.3.1','БКЭС-11','Узел-1'),
('1.2.3.2','БКЭС-12','Узел-2'),
('1.2.3.3','БКЭС-13','Узел-3'),
('1.2.3.4','БКЭС-14','Узел-4'),
('1.2.3.5','БКЭС-15','Узел-5');


  --~ to_char( current_timestamp, 'DD.MM.YYYY HH24:mi' ) timestamp NOT NULL, -- 
CREATE TABLE temp_current               -- Значения текущего времени
(
  location          text      NOT NULL, -- Местонахождение Electro
  time              timestamp NOT NULL, -- текущее время
  temp_sys          integer   NOT NULL, -- температура системы
  temp_akb          integer   NOT NULL, -- температура АКБ
  alarm_mains       integer,            -- Наличие питания на вводе (0 - есть, 1 - нет питания)
  out_volt          integer,            -- Выходное напряжение
  out_ampr          integer,            -- Потребляемый ток
  out_watt          integer,            -- Потребляемая мощность
  battery1v         integer,            -- Напряжение 1 группы батарей
  battery2v         integer,            -- Напряжение 2 группы батарей

  PRIMARY KEY ( location ),
  FOREIGN KEY  ( location )
    REFERENCES locations( location )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


INSERT INTO temp_current VALUES
('Узел-1',current_timestamp,35,20),
('Узел-2',current_timestamp,35,20),
('Узел-3',current_timestamp,35,20),
('Узел-4',current_timestamp,35,20),
('Узел-5',current_timestamp,35,20);


CREATE TABLE temp_critical              -- Журнал фиксации критических температур
(
  location          text      NOT NULL, -- Местонахождение Electro
  time              timestamp NOT NULL, -- Время
  temp_sys          integer   NOT NULL, -- Температура системы
  temp_akb          integer   NOT NULL, -- Температура АКБ  
  FOREIGN KEY  ( location )
    REFERENCES locations( location )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE temp_changes               -- Журнал фиксации изменения
(                                       -- (повышения и понижения) температур
  location  text       NOT NULL,        -- Местонахождение Electro
  time      timestamp  NOT NULL,        -- Время
  temp_sys  integer    NOT NULL,        -- Температура системы
  temp_akb  integer    NOT NULL,        -- Температура АКБ
  FOREIGN KEY  ( location )             -- из этой таблицы данные
    REFERENCES locations( location )    -- больше месяца удаляются функцией
    ON DELETE CASCADE                   -- remove_old_inserts()
    ON UPDATE CASCADE                   -- для старых данных есть таблица архив
);


CREATE TABLE public.temp_changes_archive (  -- архив фиксации изменений
  location  text      NOT NULL,
  "time"    timestamp without time zone NOT NULL,
  temp_sys  integer   NOT NULL,
  temp_akb  integer   NOT NULL,
  FOREIGN KEY  ( location )
    REFERENCES locations( location )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


CREATE TABLE temp_static                -- Журнал температур в определённые
(                                       -- часы: 0, 3, 6
  location  text       NOT NULL,        -- Местонахождение Electro
  time      timestamp  NOT NULL,        -- Время
  temp_sys  integer    NOT NULL,        -- Температура системы
  temp_akb  integer    NOT NULL,        -- Температура АКБ
  PRIMARY KEY  ( time ),
  FOREIGN KEY  ( location )
    REFERENCES locations( location )
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

