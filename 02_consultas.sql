/*
   Universidad Pontificia Bolivariana - Tópicos Avanzados de Base de Datos
   Periodo 202620 - Examen 02
   Motor: Microsoft SQL Server 2025 (Developer) sobre Docker
   Autor: tatiana fernanda suarez - ID SIGAA: 000550043
 */

USE BrechasDB;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

SELECT MIN(fecha_deteccion) AS primera_deteccion,
       MAX(fecha_deteccion) AS ultima_deteccion
FROM seguridad.brechas;
GO

/* 
    Brechas críticas del último año con mayor impacto en usuarios
*/
DECLARE @fecha_referencia DATE = CAST(GETDATE() AS DATE);
DECLARE @fecha_inicio     DATE = DATEADD(YEAR, -1, @fecha_referencia);

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
GO

-- Misma consulta encapsulada en procedimiento (después de crear la sección 8)
EXEC seguridad.sp_brechas_criticas_ultimo_anio;
GO

/* Historial de exposición de un usuario específico
    */
SELECT TOP 5 u.codigo_usuario,
       COUNT(DISTINCT e.brecha_id) AS brechas,
       COUNT(*)                    AS exposiciones
FROM seguridad.exposiciones e
JOIN seguridad.usuarios     u ON u.usuario_id = e.usuario_id
GROUP BY u.codigo_usuario
ORDER BY brechas DESC, exposiciones DESC;
GO

DECLARE @codigo_usuario VARCHAR(10) = 'US-007235';

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
WHERE u.codigo_usuario = @codigo_usuario
ORDER BY e.fecha_notificacion, b.codigo_brecha, t.nombre;
GO

SELECT * FROM seguridad.fn_historial_usuario('US-007235') ORDER BY fecha_notificacion;
EXEC seguridad.sp_historial_usuario @codigo_usuario = 'US-007235';
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO