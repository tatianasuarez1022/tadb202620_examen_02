# tadb202620_examen_02

## Examen 02 — Índices y Mejoras en el Desempeño de Consultas
### Análisis de Brechas de Seguridad

**Curso:** Tópicos Avanzados de Base de Datos  
**Periodo:** 202620  
**NRC:** 21720  
**Motor de base de datos:** Microsoft SQL Server

---

## Integrante

| Nombre completo | ID SIGAA | NRC | Motor de base de datos |
|---|---|---|---|
| Tatiana Fernanda Suárez Díaz | 000550043 | 21720 | Microsoft SQL Server |

---

## Descripción

Implementación de una base de datos para el análisis de brechas de seguridad, a partir de datos sintéticos relacionados con organizaciones, brechas de seguridad, usuarios y tipos de datos expuestos.

El examen incluye el diseño e implementación del modelo de datos, la creación de consultas SQL y el análisis de su desempeño mediante planes de ejecución e índices.

---

## Estructura del repositorio

- `docs/` - Documentos de evidencia, interacción con inteligencia artificial, conectividad e infraestructura y diagrama relacional.
- `sql/` - Scripts SQL para la implementación del modelo de datos y las consultas propuestas.
- `README.md` - Información general y descripción del repositorio.
- `.gitignore` - Archivos y carpetas excluidos del control de versiones.

---

## Consultas desarrolladas

### Brechas críticas del último año con mayor impacto en usuarios

Consulta orientada a identificar las brechas de seguridad de severidad alta o crítica que hayan expuesto al menos un tipo de dato con sensibilidad crítica durante el último año.

La consulta muestra:

- Organización afectada.
- Código de la brecha.
- Fecha de detección.
- Vector de ataque.
- Número de usuarios afectados.

Los resultados se ordenan de mayor a menor cantidad de usuarios afectados.

### Historial de exposición de un usuario específico

Consulta orientada a obtener el historial de brechas de un usuario a partir de su código.

La consulta muestra:

- Brechas en las que se vio afectado.
- Tipo de dato expuesto.
- Categoría de sensibilidad.
- Organización responsable.
- Fecha de notificación.

Los resultados se ordenan cronológicamente por fecha de notificación.

---

## Evidencias

En la carpeta `docs/` se incluyen las evidencias correspondientes al desarrollo del examen, incluyendo los documentos solicitados y los planes de ejecución de las consultas.

Las evidencias de los planes de ejecución incluyen el árbol de operaciones generado, las filas afectadas, el costo de la consulta y los registros resultantes.

---

## Herramientas utilizadas

- Microsoft SQL Server
- GitHub
- Herramienta de inteligencia artificial utilizada durante el desarrollo, documentada mediante capturas de pantalla.
