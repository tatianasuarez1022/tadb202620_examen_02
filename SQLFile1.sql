USE BrechasDB;
DROP INDEX IF EXISTS brechas_severidad_fecha_ix       ON seguridad.brechas;
DROP INDEX IF EXISTS brechas_organizacion_ix          ON seguridad.brechas;
DROP INDEX IF EXISTS usuarios_organizacion_ix         ON seguridad.usuarios;
DROP INDEX IF EXISTS exposiciones_tipo_dato_brecha_ix ON seguridad.exposiciones;
DROP INDEX IF EXISTS exposiciones_usuario_fecha_ix    ON seguridad.exposiciones;