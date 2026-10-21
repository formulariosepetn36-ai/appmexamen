# Feature: Insumos v1 — Formulario de Permiso y Catálogo de Materias

| | |
|---|---|
| Estado | **COMPLETADA** (2026-09-28) — pendiente de visto bueno del usuario (iterativo) |
| Fecha | 2026-09-28 |
| Alcance autorizado | Ítems 1 y 3 de los pendientes externos de `docs/diseno.md` §9 |
| TDD | No aplica — no hay framework de tests. Verificación por ejecución real. |
| Método del PDF | **Plantilla original** de la escuela + purga de texto + overlay (`docs/diseno.md` §7.5) |

## Objetivo

Generar dos insumos listos para usar:

1. El **nuevo formulario de Permiso de Examen** (PDF imprimible) con los cambios
   decididos en D8/D9/D7: **1 copia por hoja**, **título dinámico** según la condición
   y **las 4 condiciones**.
2. El **catálogo de 153 materias** con los tipeos corregidos, listo para cargar como
   datos semilla en la base de datos.

## Por qué

- El formulario impreso actual de la escuela imprime **3 copias** por hoja, tiene el
  título fijo *"Alumno Regular"* y ofrece **5 condiciones** que no coinciden con las
  decisiones D7–D9.
- El listado de materias de `pront app.txt` tiene errores de tipeo que terminarían
  tanto en la base de datos como en el PDF del permiso.

## Fuera de alcance

- Ítem 2 (sistema externo que asigna las fechas): **pospuesto por el usuario**.
- Backend y base de datos (se asignan después).
- Modificar `pront app.txt` — queda como registro original de los requisitos.

## Checklist

- [x] **T1** · `tools/generar_permiso.py` genera el PDF **sobre la plantilla original**
      de la escuela: purga el texto viejo (título, opciones de condición, líneas 3–4 del
      párrafo, fecha y copias 2/3) y pinta un overlay con 1 copia, título dinámico y
      las 4 condiciones (`REGULAR · PREVIA · COMPLETAR ESTUDIO · EQUIVALENCIA`).
      Valida el máximo de 6 materias por permiso (RB-13).
- [x] **T1b** · Muestra generada en `docs/muestras/permiso-muestra.pdf`.
- [x] **T3** · Verificación del PDF contra la plantilla: texto (pypdf) + píxeles
      (pypdfium2 @300dpi) + 6 validaciones de error.
- [x] **T2** · `data/materias.csv` con las 153 materias corregidas, columnas
      `tecnicatura,anio,materia`.
- [x] **T2b** · `docs/correcciones-materias.md` con la tabla *original → corregido → motivo*
      para que el usuario pueda revisar y veto cada cambio.

## Criterios de aceptación

- **AC-1** — El PDF de muestra tiene **exactamente 1 página**, conserva el layout de la
  plantilla (612 × 792) y muestra las 6 filas de la tabla de materias.
- **AC-1b** — **0 textos** por debajo de `y = 522` (las copias 2 y 3 quedaron vacías) y
  **0 restos** del texto original (`REVINCULACIÓN`, `EQUIVALENCIAS`, `año de`…).
- **AC-1c** — Las 6 validaciones de error (`condicion` inválida, 7 materias, plantilla
  inexistente, alumno/DNI/carrera vacíos) lanzan excepción con mensaje claro.
- **AC-2** — El CSV tiene **exactamente 153 filas** (75 Alimentos + 78 Gestión
  Organizacional) y **cero** de las palabras mal tipeadas.
- **AC-3** — Cada corrección del catálogo aparece documentada y es justificable.
- **AC-4** — 6° año de Gestión Organizacional se mantiene con **7 materias**: el usuario
  confirmó *"las materias están bien"*.

## Verificación

```bash
python tools/generar_permiso.py
python -c "import csv;r=list(csv.DictReader(open('data/materias.csv',encoding='utf-8')));print(len(r))"
rg -i "extrajera|infromacion|termdinamica|sisitema|equilavencia|microbiogia" data/materias.csv
```

La verificación texto/píxeles contra la plantilla se hizo con los scripts
temporales `verificar.py`, `render.py`, `comparar.py` y `diff_*.py` de
`%TEMP%\opencode` (son de análisis, no forman parte del repo).

## Progreso

- [x] T1 / T1b — generador sobre plantilla + PDF de muestra
- [x] T3 — verificación texto/píxeles + validaciones de error
- [x] T2 / T2b — catálogo corregido + lista de correcciones

### Evidencia de verificación (2026-09-28)

| Comando | Resultado observado |
|---|---|
| `python tools/generar_permiso.py` | `D:\...\docs\muestras\permiso-muestra.pdf` ✅ |
| recuento de páginas (pypdf) | `pages: 1`, `MediaBox: [0, 0, 612, 792]` ✅ AC-1 |
| textos con `y < 522` | `0` ✅ AC-1b |
| fantasmas (`REVINCULACIÓN`, `EQUIVALENCIAS`, `año de`…) | `[]` ✅ AC-1b |
| valores rellenados (16 campos) | cada uno aparece **1 sola vez** ✅ |
| textos estáticos vs. copia 1 original | `16/16` idénticos (x, y, cuerpo) ✅ |
| diff por píxeles (pypdfium2 @300dpi) | 78364 px distintos (2.88%), **todos explicados** (campos rellenados + recortes ≤2.4 pt de copias 2/3); fila firma y borde superior: `0` px distintos |
| recuento de filas del CSV | `rows: 153` ✅ AC-2 |
| reparto por tecnicatura/año | Alimentos 13·13·14·13·12·10 = 75 · Gestión 14·14·14·14·15·7 = 78 ✅ AC-2, AC-4 |
| regex de tipeos sobre el CSV | `typos: []` ✅ AC-2 |
| validación de condición inválida | `ValueError: condicion invalida: 'libres' (esperado: completar_estudio, equivalencia, previa, regular)` ✅ AC-1c |
| validación de 7 materias | `ValueError: RB-13: maximo 6 materias por permiso, recibidas 7` ✅ AC-1c |
| validación de plantilla inexistente | `FileNotFoundError: no se encuentra la plantilla: ...` ✅ AC-1c |
| validaciones alumno/DNI/carrera vacíos | `ValueError: alumno vacio / dni vacio / carrera vacia` ✅ AC-1c |
| caso feliz | `SIN ERROR` ✅ |

**Checks fallidos / omitidos:** ninguno.
**Revisión nativa (`gentle-ai review`):** NO DISPONIBLE en este runtime —
`immutable_review_transport_unsupported` (`next_action: stop`, `retry_safe: false`).
Se preserva el resultado tipeado; no se emite ningún veredicto de aprobación.
