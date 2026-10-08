/*
   Universidad Pontificia Bolivariana - Tópicos Avanzados de Base de Datos
   Periodo 202620 - Examen 02
   Motor: Microsoft SQL Server 2025 (Developer) sobre Docker
   Autor: tatiana fernanda suarez - ID SIGAA: 000550043
*/
USE master;
GO

IF DB_ID('BrechasDB') IS NOT NULL
BEGIN
    ALTER DATABASE BrechasDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BrechasDB;
END
GO

CREATE DATABASE BrechasDB COLLATE Latin1_General_100_CI_AI_SC_UTF8;
GO

/* 
   LOGINS, USUARIOS Y ESQUEMA  
*/
IF SUSER_ID('brechas_owner') IS NULL
    CREATE LOGIN brechas_owner WITH PASSWORD = 'Owner*Brechas2026', CHECK_POLICY = ON, DEFAULT_DATABASE = BrechasDB;
IF SUSER_ID('brechas_app') IS NULL
    CREATE LOGIN brechas_app   WITH PASSWORD = 'App*Brechas2026',   CHECK_POLICY = ON, DEFAULT_DATABASE = BrechasDB;
GO

USE BrechasDB;
GO

CREATE USER brechas_owner FOR LOGIN brechas_owner;
CREATE USER brechas_app   FOR LOGIN brechas_app;
GO

CREATE SCHEMA seguridad AUTHORIZATION brechas_owner;
GO

ALTER USER brechas_owner WITH DEFAULT_SCHEMA = seguridad;
ALTER USER brechas_app   WITH DEFAULT_SCHEMA = seguridad;

GRANT CREATE TABLE, CREATE VIEW, CREATE FUNCTION, CREATE PROCEDURE
    TO brechas_owner;
GO

/*
   SECUENCIAS (generan las claves primarias subrogadas)
*/
CREATE SEQUENCE seguridad.seq_organizaciones AS INT START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE seguridad.seq_brechas        AS INT START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE seguridad.seq_usuarios       AS INT START WITH 1 INCREMENT BY 1 NO CYCLE;
CREATE SEQUENCE seguridad.seq_tipos_dato     AS INT START WITH 1 INCREMENT BY 1 NO CYCLE;
GO

/*
   TABLAS DEL MODELO NORMALIZADO
*/
CREATE TABLE seguridad.organizaciones (
    organizacion_id  INT          NOT NULL
        CONSTRAINT organizaciones_id_df DEFAULT (NEXT VALUE FOR seguridad.seq_organizaciones),
    nombre           VARCHAR(100) NOT NULL,
    sector           VARCHAR(50)  NOT NULL,
    pais             VARCHAR(50)  NOT NULL,
    tamano_empleados INT          NOT NULL,
    CONSTRAINT organizaciones_pk        PRIMARY KEY CLUSTERED (organizacion_id),
    CONSTRAINT organizaciones_nombre_uk UNIQUE (nombre),
    CONSTRAINT organizaciones_tamano_ck CHECK (tamano_empleados > 0)
);

CREATE TABLE seguridad.brechas (
    brecha_id           INT           NOT NULL
        CONSTRAINT brechas_id_df DEFAULT (NEXT VALUE FOR seguridad.seq_brechas),
    codigo_brecha       VARCHAR(10)   NOT NULL,
    organizacion_id     INT           NOT NULL,
    fecha_ocurrencia    DATE          NOT NULL,
    fecha_deteccion     DATE          NOT NULL,
    vector_ataque       VARCHAR(60)   NOT NULL,
    severidad           VARCHAR(10)   NOT NULL,
    registros_afectados INT           NOT NULL,
    costo_estimado      DECIMAL(16,2) NOT NULL,
    CONSTRAINT brechas_pk               PRIMARY KEY CLUSTERED (brecha_id),
    CONSTRAINT brechas_codigo_uk        UNIQUE (codigo_brecha),
    CONSTRAINT brechas_organizacion_fk  FOREIGN KEY (organizacion_id)
        REFERENCES seguridad.organizaciones (organizacion_id),
    CONSTRAINT brechas_fechas_ck        CHECK (fecha_deteccion >= fecha_ocurrencia),
    CONSTRAINT brechas_registros_ck     CHECK (registros_afectados >= 0),
    CONSTRAINT brechas_costo_ck         CHECK (costo_estimado >= 0),
    CONSTRAINT brechas_severidad_ck     CHECK (severidad IN ('Baja', 'Media', 'Alta', 'Critica'))
);

CREATE TABLE seguridad.usuarios (
    usuario_id      INT         NOT NULL
        CONSTRAINT usuarios_id_df DEFAULT (NEXT VALUE FOR seguridad.seq_usuarios),
    codigo_usuario  VARCHAR(10) NOT NULL,
    organizacion_id INT         NOT NULL,
    pseudonimo      VARCHAR(50) NOT NULL,
    email_hash      CHAR(32)    NOT NULL,   -- hash MD5 del correo (seudonimización)
    pais_residencia VARCHAR(50) NOT NULL,
    fecha_registro  DATE        NOT NULL,
    CONSTRAINT usuarios_pk              PRIMARY KEY CLUSTERED (usuario_id),
    CONSTRAINT usuarios_codigo_uk       UNIQUE (codigo_usuario),
    CONSTRAINT usuarios_organizacion_fk FOREIGN KEY (organizacion_id)
        REFERENCES seguridad.organizaciones (organizacion_id)
);

CREATE TABLE seguridad.tipos_dato (
    tipo_dato_id           INT         NOT NULL
        CONSTRAINT tipos_dato_id_df DEFAULT (NEXT VALUE FOR seguridad.seq_tipos_dato),
    nombre                 VARCHAR(50) NOT NULL,
    categoria_sensibilidad VARCHAR(10) NOT NULL,
    CONSTRAINT tipos_dato_pk           PRIMARY KEY CLUSTERED (tipo_dato_id),
    CONSTRAINT tipos_dato_nombre_uk    UNIQUE (nombre),
    CONSTRAINT tipos_dato_categoria_ck CHECK (categoria_sensibilidad IN ('Baja', 'Media', 'Alta', 'Critica'))
);

CREATE TABLE seguridad.exposiciones (
    brecha_id          INT  NOT NULL,
    usuario_id         INT  NOT NULL,
    tipo_dato_id       INT  NOT NULL,
    fecha_notificacion DATE NOT NULL,
    CONSTRAINT exposiciones_pk           PRIMARY KEY CLUSTERED (brecha_id, usuario_id, tipo_dato_id),
    CONSTRAINT exposiciones_brecha_fk    FOREIGN KEY (brecha_id)    REFERENCES seguridad.brechas (brecha_id),
    CONSTRAINT exposiciones_usuario_fk   FOREIGN KEY (usuario_id)   REFERENCES seguridad.usuarios (usuario_id),
    CONSTRAINT exposiciones_tipo_dato_fk FOREIGN KEY (tipo_dato_id) REFERENCES seguridad.tipos_dato (tipo_dato_id)
);
GO

/* 
   CARGA DE DATOS DESDE LA SÁBANA
 */
CREATE TABLE seguridad.staging_sabana (
    nombre_organizacion           VARCHAR(200),
    sector_organizacion           VARCHAR(100),
    pais_organizacion             VARCHAR(100),
    tamano_empleados_organizacion VARCHAR(100),
    codigo_brecha                 VARCHAR(100),
    fecha_ocurrencia              VARCHAR(100),
    fecha_deteccion               VARCHAR(100),
    vector_ataque                 VARCHAR(100),
    severidad_incidente           VARCHAR(100),
    registros_afectados_total     VARCHAR(100),
    costo_estimado_total          VARCHAR(100),
    codigo_usuario                VARCHAR(100),
    pseudonimo_usuario            VARCHAR(100),
    email_hash_usuario            VARCHAR(100),
    pais_residencia_usuario       VARCHAR(100),
    fecha_registro_usuario        VARCHAR(100),
    tipo_dato_expuesto            VARCHAR(100),
    categoria_sensibilidad_dato   VARCHAR(100),
    fecha_notificacion_usuario    VARCHAR(100)
);
GO

BULK INSERT seguridad.staging_sabana FROM '/var/opt/mssql/carga/sabana_brechas_seguridad_lote_1.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', FIELDQUOTE = '"', ROWTERMINATOR = '0x0d0a', TABLOCK);
BULK INSERT seguridad.staging_sabana FROM '/var/opt/mssql/carga/sabana_brechas_seguridad_lote_2.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', FIELDQUOTE = '"', ROWTERMINATOR = '0x0d0a', TABLOCK);
BULK INSERT seguridad.staging_sabana FROM '/var/opt/mssql/carga/sabana_brechas_seguridad_lote_3.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', FIELDQUOTE = '"', ROWTERMINATOR = '0x0d0a', TABLOCK);
BULK INSERT seguridad.staging_sabana FROM '/var/opt/mssql/carga/sabana_brechas_seguridad_lote_4.csv'
    WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', FIELDQUOTE = '"', ROWTERMINATOR = '0x0d0a', TABLOCK);
GO


SELECT COUNT(*)                             AS filas_sabana,          -- esperado 40000
       COUNT(DISTINCT nombre_organizacion)  AS organizaciones,        -- esperado 60
       COUNT(DISTINCT codigo_brecha)        AS brechas,               -- esperado 800
       COUNT(DISTINCT codigo_usuario)       AS usuarios,              -- esperado 7887
       COUNT(DISTINCT tipo_dato_expuesto)   AS tipos_dato             -- esperado 10
FROM seguridad.staging_sabana;

SELECT severidad_incidente, COUNT(*) AS filas
FROM seguridad.staging_sabana GROUP BY severidad_incidente;

SELECT tipo_dato_expuesto, categoria_sensibilidad_dato, COUNT(*) AS filas
FROM seguridad.staging_sabana
GROUP BY tipo_dato_expuesto, categoria_sensibilidad_dato
ORDER BY categoria_sensibilidad_dato, tipo_dato_expuesto;

SELECT nombre_organizacion FROM seguridad.staging_sabana GROUP BY nombre_organizacion
HAVING COUNT(DISTINCT CONCAT(sector_organizacion, '|', pais_organizacion, '|', tamano_empleados_organizacion)) > 1;

SELECT codigo_brecha FROM seguridad.staging_sabana GROUP BY codigo_brecha
HAVING COUNT(DISTINCT CONCAT(nombre_organizacion, '|', fecha_ocurrencia, '|', fecha_deteccion, '|', vector_ataque, '|',
                             severidad_incidente, '|', registros_afectados_total, '|', costo_estimado_total)) > 1;

SELECT codigo_usuario FROM seguridad.staging_sabana GROUP BY codigo_usuario
HAVING COUNT(DISTINCT CONCAT(pseudonimo_usuario, '|', email_hash_usuario, '|', pais_residencia_usuario, '|',
                             fecha_registro_usuario, '|', nombre_organizacion)) > 1;

SELECT codigo_brecha, codigo_usuario, tipo_dato_expuesto FROM seguridad.staging_sabana
GROUP BY codigo_brecha, codigo_usuario, tipo_dato_expuesto HAVING COUNT(*) > 1;
GO


SELECT DISTINCT nombre_organizacion, sector_organizacion, pais_organizacion,
       CAST(tamano_empleados_organizacion AS INT) AS tamano_empleados
INTO #org FROM seguridad.staging_sabana;

INSERT INTO seguridad.organizaciones (nombre, sector, pais, tamano_empleados)
SELECT nombre_organizacion, sector_organizacion, pais_organizacion, tamano_empleados
FROM #org ORDER BY nombre_organizacion;

SELECT DISTINCT tipo_dato_expuesto, categoria_sensibilidad_dato
INTO #tip FROM seguridad.staging_sabana;

INSERT INTO seguridad.tipos_dato (nombre, categoria_sensibilidad)
SELECT tipo_dato_expuesto, categoria_sensibilidad_dato FROM #tip ORDER BY tipo_dato_expuesto;

SELECT DISTINCT s.codigo_brecha, o.organizacion_id,
       CAST(s.fecha_ocurrencia AS DATE)               AS fecha_ocurrencia,
       CAST(s.fecha_deteccion  AS DATE)               AS fecha_deteccion,
       s.vector_ataque, s.severidad_incidente,
       CAST(s.registros_afectados_total AS INT)       AS registros_afectados,
       CAST(s.costo_estimado_total AS DECIMAL(16,2))  AS costo_estimado
INTO #bre
FROM seguridad.staging_sabana s
JOIN seguridad.organizaciones o ON o.nombre = s.nombre_organizacion;

INSERT INTO seguridad.brechas (codigo_brecha, organizacion_id, fecha_ocurrencia, fecha_deteccion,
                               vector_ataque, severidad, registros_afectados, costo_estimado)
SELECT codigo_brecha, organizacion_id, fecha_ocurrencia, fecha_deteccion,
       vector_ataque, severidad_incidente, registros_afectados, costo_estimado
FROM #bre ORDER BY codigo_brecha;

SELECT DISTINCT s.codigo_usuario, o.organizacion_id, s.pseudonimo_usuario, s.email_hash_usuario,
       s.pais_residencia_usuario, CAST(s.fecha_registro_usuario AS DATE) AS fecha_registro
INTO #usu
FROM seguridad.staging_sabana s
JOIN seguridad.organizaciones o ON o.nombre = s.nombre_organizacion;

INSERT INTO seguridad.usuarios (codigo_usuario, organizacion_id, pseudonimo, email_hash, pais_residencia, fecha_registro)
SELECT codigo_usuario, organizacion_id, pseudonimo_usuario, email_hash_usuario, pais_residencia_usuario, fecha_registro
FROM #usu ORDER BY codigo_usuario;


INSERT INTO seguridad.exposiciones (brecha_id, usuario_id, tipo_dato_id, fecha_notificacion)
SELECT b.brecha_id, u.usuario_id, t.tipo_dato_id, CAST(s.fecha_notificacion_usuario AS DATE)
FROM seguridad.staging_sabana s
JOIN seguridad.brechas    b ON b.codigo_brecha  = s.codigo_brecha
JOIN seguridad.usuarios   u ON u.codigo_usuario = s.codigo_usuario
JOIN seguridad.tipos_dato t ON t.nombre         = s.tipo_dato_expuesto;

DROP TABLE #org, #tip, #bre, #usu;
GO

/*
   5. VALIDACIÓN DE LA CARGA
*/
SELECT 'organizaciones' AS tabla, COUNT(*) AS filas, 60    AS esperado FROM seguridad.organizaciones
UNION ALL SELECT 'brechas',      COUNT(*), 800   FROM seguridad.brechas
UNION ALL SELECT 'usuarios',     COUNT(*), 7887  FROM seguridad.usuarios
UNION ALL SELECT 'tipos_dato',   COUNT(*), 10    FROM seguridad.tipos_dato
UNION ALL SELECT 'exposiciones', COUNT(*), 40000 FROM seguridad.exposiciones;


DROP TABLE seguridad.staging_sabana;


EXEC sp_updatestats;
GO


/* 
  ÍNDICES PARA MEJORA DEL DESEMPEÑO
*/

CREATE NONCLUSTERED INDEX brechas_severidad_fecha_ix
    ON seguridad.brechas (severidad, fecha_deteccion)
    INCLUDE (codigo_brecha, vector_ataque, organizacion_id);

CREATE NONCLUSTERED INDEX brechas_organizacion_ix
    ON seguridad.brechas (organizacion_id);

CREATE NONCLUSTERED INDEX usuarios_organizacion_ix
    ON seguridad.usuarios (organizacion_id);

CREATE NONCLUSTERED INDEX exposiciones_tipo_dato_brecha_ix
    ON seguridad.exposiciones (tipo_dato_id, brecha_id);

CREATE NONCLUSTERED INDEX exposiciones_usuario_fecha_ix
    ON seguridad.exposiciones (usuario_id, fecha_notificacion)
    INCLUDE (brecha_id, tipo_dato_id);

GO

UPDATE STATISTICS seguridad.brechas      WITH FULLSCAN;
UPDATE STATISTICS seguridad.usuarios     WITH FULLSCAN;
UPDATE STATISTICS seguridad.exposiciones WITH FULLSCAN;
GO

/*
   7. VISTAS
*/
CREATE OR ALTER VIEW seguridad.v_exposiciones_detalle
AS
SELECT u.codigo_usuario,
       b.codigo_brecha,
       b.severidad,
       b.vector_ataque,
       b.fecha_ocurrencia,
       b.fecha_deteccion,
       o.nombre                 AS organizacion,
       t.nombre                 AS tipo_dato,
       t.categoria_sensibilidad,
       e.fecha_notificacion
FROM seguridad.exposiciones   e
JOIN seguridad.usuarios       u ON u.usuario_id      = e.usuario_id
JOIN seguridad.brechas        b ON b.brecha_id       = e.brecha_id
JOIN seguridad.organizaciones o ON o.organizacion_id = b.organizacion_id
JOIN seguridad.tipos_dato     t ON t.tipo_dato_id    = e.tipo_dato_id;
GO

/* 
   8. FUNCIONES Y PROCEDIMIENTOS
*/

CREATE OR ALTER PROCEDURE seguridad.sp_brechas_criticas_ultimo_anio
    @fecha_referencia DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @fecha_referencia IS NULL
        SET @fecha_referencia = CAST(GETDATE() AS DATE);

    DECLARE @fecha_inicio DATE = DATEADD(YEAR, -1, @fecha_referencia);

    SELECT o.nombre                     AS organizacion,
           b.codigo_brecha,
           b.fecha_deteccion,
           b.vector_ataque,
           COUNT(DISTINCT e.usuario_id) AS total_usuarios_afectados
    FROM seguridad.brechas        b
    JOIN seguridad.organizaciones o ON o.organizacion_id = b.organizacion_id
    JOIN seguridad.exposiciones   e ON e.brecha_id       = b.brecha_id
    WHERE b.severidad IN ('Alta', 'Critica')
      AND b.fecha_deteccion >  @fecha_inicio
      AND b.fecha_deteccion <= @fecha_referencia
      AND EXISTS (SELECT 1
                  FROM seguridad.exposiciones e2
                  JOIN seguridad.tipos_dato   t ON t.tipo_dato_id = e2.tipo_dato_id
                  WHERE e2.brecha_id = b.brecha_id
                    AND t.categoria_sensibilidad = 'Critica')
    GROUP BY o.nombre, b.codigo_brecha, b.fecha_deteccion, b.vector_ataque
    ORDER BY total_usuarios_afectados DESC, b.codigo_brecha
    OPTION (RECOMPILE);   
END
GO

CREATE OR ALTER FUNCTION seguridad.fn_historial_usuario (@codigo_usuario VARCHAR(10))
RETURNS TABLE
AS
RETURN
    SELECT b.codigo_brecha,
           t.nombre                 AS tipo_dato,
           t.categoria_sensibilidad,
           o.nombre                 AS organizacion,
           e.fecha_notificacion
    FROM seguridad.usuarios       u
    JOIN seguridad.exposiciones   e ON e.usuario_id      = u.usuario_id
    JOIN seguridad.brechas        b ON b.brecha_id       = e.brecha_id
    JOIN seguridad.organizaciones o ON o.organizacion_id = b.organizacion_id
    JOIN seguridad.tipos_dato     t ON t.tipo_dato_id    = e.tipo_dato_id
    WHERE u.codigo_usuario = @codigo_usuario;
GO


CREATE OR ALTER PROCEDURE seguridad.sp_historial_usuario
    @codigo_usuario VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM seguridad.usuarios WHERE codigo_usuario = @codigo_usuario)
        THROW 50001, 'El código de usuario no existe.', 1;

    SELECT codigo_brecha, tipo_dato, categoria_sensibilidad, organizacion, fecha_notificacion
    FROM seguridad.fn_historial_usuario(@codigo_usuario)
    ORDER BY fecha_notificacion, codigo_brecha, tipo_dato;
END
GO

/*
   PRIVILEGIOS MÍNIMOS DEL USUARIO DE APLICACIÓN
*/
GRANT EXECUTE ON OBJECT::seguridad.sp_brechas_criticas_ultimo_anio TO brechas_app;
GRANT EXECUTE ON OBJECT::seguridad.sp_historial_usuario            TO brechas_app;
GRANT SELECT  ON OBJECT::seguridad.fn_historial_usuario            TO brechas_app;
GRANT SELECT  ON OBJECT::seguridad.v_exposiciones_detalle          TO brechas_app;
GO


EXECUTE AS USER = 'brechas_app';
    BEGIN TRY
        SELECT TOP 1 * FROM seguridad.usuarios;
    END TRY
    BEGIN CATCH
        SELECT 'Acceso denegado a tablas base (correcto)' AS verificacion, ERROR_MESSAGE() AS detalle;
    END CATCH
    EXEC seguridad.sp_brechas_criticas_ultimo_anio;   -- sí debe funcionar
REVERT;
GO