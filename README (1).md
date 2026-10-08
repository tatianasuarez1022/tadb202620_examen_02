# tadb202620_examen_02

**Universidad Pontificia Bolivariana** · Facultad de Ingeniería en Energía, Computación y TIC
**Curso:** Tópicos Avanzados de Base de Datos · **Periodo:** 202620
**Docente:** Juan Darío Rodas M.
**Examen No. 2 (20%):** Índices y mejoras en el desempeño de consultas – Análisis de brechas de seguridad

## Integrante

| Nombre completo | ID SIGAA | Motor de base de datos |
|---|---|---|
| Tatiana Fernanda Suárez Díaz | 000550043 | Microsoft SQL Server 2025 (Developer Edition, versión 17.0) |

## Infraestructura

- SQL Server 2025 ejecutándose en un contenedor Docker (imagen `mcr.microsoft.com/mssql/server:2025-latest`), sobre Docker Desktop en Windows.
- Conexión desde SQL Server Management Studio (SSMS) a `localhost,1433`.
- El detalle del abastecimiento y la conectividad está en `docs/infraestructura_sqlserver.pdf`.

## Contenido del repositorio

| Ruta | Descripción |
|---|---|
| `diagrama/diagrama_relacional.png` | Diagrama relacional del modelo (5 tablas): nomenclatura, claves primarias y foráneas. |
| `scripts/sqlserver/01_modelo.sql` | Implementación del modelo: base de datos, logins/usuarios, esquema, privilegios mínimos, secuencias, tablas, restricciones, carga desde la sábana, índices, vista, función y procedimientos. |
| `scripts/sqlserver/02_consultas.sql` | Consultas de las Etapas 3 y 4 con los elementos de mejora de desempeño. |
| `docs/planes_ejecucion_sqlserver.docx` | Planes de ejecución de cada consulta, sin y con índices: árbol de operaciones, filas, costo y registros resultantes. |
| `docs/infraestructura_sqlserver.pdf` | Proceso de abastecimiento de la infraestructura y conectividad desde el IDE. |
| `docs/uso_ia.pdf` | Evidencia completa de la interacción con la herramienta de inteligencia artificial utilizada. |

## Modelo de datos

A partir de la sábana consolidada (40.000 filas, 19 columnas) se identificaron cuatro entidades y una tabla puente, todas en el esquema `seguridad`:

| Tabla | Filas | Clave primaria | Clave natural |
|---|---|---|---|
| `organizaciones` | 60 | `organizacion_id` | `nombre` |
| `brechas` | 800 | `brecha_id` | `codigo_brecha` |
| `usuarios` | 7.887 | `usuario_id` | `codigo_usuario` |
| `tipos_dato` | 10 | `tipo_dato_id` | `nombre` |
| `exposiciones` (puente) | 40.000 | (`brecha_id`, `usuario_id`, `tipo_dato_id`) | — |

Decisiones principales:

- Claves primarias subrogadas generadas con secuencias (`seq_*`); los códigos de negocio quedan como restricciones `UNIQUE`.
- La sábana no trae código de organización, por lo que el nombre es su clave natural.
- La fecha de notificación vive en la tabla puente, porque depende de la combinación brecha + usuario + tipo de dato.
- Privilegios mínimos: `brechas_owner` es dueño del esquema; `brechas_app` solo puede ejecutar los procedimientos y leer la vista y la función, sin acceso directo a las tablas (cadena de propiedad).

## Consultas

- **Etapa 3:** brechas de severidad Alta o Crítica detectadas en el último año que expusieron al menos un dato de sensibilidad crítica, con el total de usuarios distintos afectados (`seguridad.sp_brechas_criticas_ultimo_anio`).
- **Etapa 4:** historial de exposición de un usuario por su código, ordenado por fecha de notificación (`seguridad.fn_historial_usuario` y `seguridad.sp_historial_usuario`).

## Cómo reproducir

1. Copiar los cuatro archivos `sabana_brechas_seguridad_lote_#.csv` al contenedor en `/var/opt/mssql/carga/`.
2. Ejecutar `01_modelo.sql` como `sa`, desde el inicio hasta la marca `PAUSA` (crea y carga el modelo).
3. Ejecutar `02_consultas.sql` y capturar los planes **sin índices**.
4. Ejecutar el resto de `01_modelo.sql` (índices, vista, función, procedimientos y privilegios).
5. Ejecutar de nuevo `02_consultas.sql` y capturar los planes **con índices**.

Los archivos CSV de la sábana no se versionan en el repositorio (ver `.gitignore`).

## Uso de inteligencia artificial

Se utilizó Claude (Anthropic) como asistente para el diseño del modelo, la escritura de los scripts y la resolución de errores. La evidencia completa está en `docs/uso_ia.pdf`.
