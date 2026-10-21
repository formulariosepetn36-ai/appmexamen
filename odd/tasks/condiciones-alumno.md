# Tareas — Condición elegida por el alumno + prototipo de BD

| | |
|---|---|
| Feature | `condiciones-alumno` |
| Estado | EN CURSO |
| Inicio | 2026-09-29 |
| Alcance | `docs/diseno.md`, `docs/prototipo/prototipo.html`, `docs/modelo/prototipo-bd.sql` (nuevo) |

## Objetivo

Pasar la **asignación de la condición** del admin al **ALUMNO** (una condición por
materia, elegida al inscribirse, por defecto `REGULAR`), y generar el **prototipo de
base de datos** de nuestro diseño con las convenciones técnicas del documento de
backend (`analisis.txt`).

## Por qué

El usuario eligió el lado "alumno" del **conflicto #2** de
`docs/comparativa-analisis-vs-diseno.txt`. RB-18 ya agrupa materias por condición:
si el alumno mezcla condiciones, salen dos permisos — el modelo lo soporta sin tocar
el PDF (`tools/generar_permiso.py` no cambia).

## Alcance autorizado

- `docs/diseno.md` — edición (§2, §3.3, §3.4, §4, §5 RB-04, §7.4, §10).
- `docs/prototipo/prototipo.html` — edición (selector de condición por materia).
- `docs/modelo/prototipo-bd.sql` — archivo nuevo.
- **Fuera de alcance:** `tools/generar_permiso.py`, `data/materias.csv`, los demás
  conflictos #1..#18 de la comparativa (siguen abiertos, salvo #2 que cierra esta
  tarea), inventar datos semilla de alumnos.

## Decisiones de diseño (fijadas para esta tarea)

- **D15 (nueva):** la condición la elige el ALUMNO al inscribirse: una por materia,
  por defecto `REGULAR`, con las 4 opciones del impreso
  (`regular | previa | completar_estudio | equivalencia`); vive en
  `enrollments.condition`. El admin solo puede corregirla.
- **D6 (revisada):** se mantiene **una condición por permiso** (una sola línea en el
  impreso): las materias elegidas se agrupan por condición y cada grupo genera su
  permiso; si hay mezcla, dos permisos (RB-18).
- **D1 (revisada):** el admin "supervisa y corrige" (ya no "asigna la condición").
- El prototipo de BD usa nuestras tablas (§4 de `diseno.md`) + las convenciones
  técnicas de `analisis.txt` (uuid, `timestamptz`, soft delete con índice parcial,
  `ON DELETE` explícito, trigger de `updated_at`, PK compuesta en junction). El
  idioma de los nombres (inglés vs prefijos `pe_/us_/es_/pr_`) **sigue abierto**
  (conflicto #1): se conservan los nuestros y se deja el mapeo en el encabezado.

## Checklist

- [ ] T1 `docs/diseno.md`: roles §2, pantalla de inscripción §3.3, panel admin §3.4,
      modelo §4 (`enrollments.condition` + `permit_enrollments`), RB-04, §7.4,
      decisiones D1/D6/D15.
- [ ] T2 `docs/prototipo/prototipo.html`: selector de condición por materia
      (default REGULAR), resumen con condición, aviso "se generarán 2 permisos" si
      hay mezcla, admin sigue pudiendo corregir.
- [ ] T3 `docs/modelo/prototipo-bd.sql`: esquema PostgreSQL completo + índice de
      conflicto #1 en el encabezado + seed de `degrees`.
- [ ] T4 Verificación estructural ejecutada y reportada (HTML balanceado, SQL sin
      FK huérfanas, marcadores del doc).

## Criterios de aceptación

1. En `diseno.md` ya no queda ninguna frase que diga que la condición la asigna el
   admin (salvo la capacidad de *corregirla*).
2. En la pantalla de inscripción del prototipo, cada materia elegida muestra su
   propio selector de condición y el resumen refleja la mezcla.
3. `prototipo-bd.sql` crea 10 tablas sin referencias a tablas inexistentes, toda FK
   con `ON DELETE`, toda tabla con `created_at/updated_at/deleted_at` + trigger,
   y `enrollments.condition` con CHECK de 4 valores.
4. `tools/generar_permiso.py` y `data/materias.csv` intactos.

## Checks / verificación

- `python <temp>\check_diseno.py` → marcadores T1 presentes.
- `python <temp>\check_html.py` → tags balanceados, `data-go` resueltos, ids únicos.
- `python <temp>\check_sql.py` → FK resolubles, cobertura de convenciones.
- Lectura de retorno de las secciones editadas por el orquestador.

## Progreso

- [x] T1..T4 — verificación en el cierre de la sesión (espejo Engram
  `odd/condiciones-alumno/tasks`).
