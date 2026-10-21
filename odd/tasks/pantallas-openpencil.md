# Rediseño de pantallas en OpenPencil (v2, mismo alcance funcional)

## Objetivo

Producir las 8 pantallas de la app en OpenPencil con una vista más actualizada,
conservando EXACTAMENTE las mismas características, textos funcionales y reglas de
negocio de `docs/prototipo/prototipo.html`.

## Problema

La maqueta HTML actual cumple lo funcional (D14, D15, RB-13, RB-18, RB-19, límites
8/3) pero su aspecto no refleja el estado del arte de UI móvil.

## Por qué (alcance autorizado)

Pedido del usuario (2026-09-29): "revisa si está instalado OpenPencil" +
"modifica las pantallas con unas vistas más actualizadas pero con las mismas
características que estuvimos trabajando". Autoriza rediseñar lo visual; NO autoriza
cambiar reglas de negocio, alcance ni decisiones cerradas.

## Alcance

- Entrada: `docs/prototipo/prototipo.html` (fuente de features y textos).
- Salida: `docs/prototipo/pantallas.op` (documento OpenPencil, 8 frames de nivel 1)
  + PNG exportados en `docs/prototipo/v2/`.
- Estilo: guía `clean-blue-mobile-light` de OpenPencil (402px, acento #2563EB,
  SF Pro, radios 8-16, iconos Lucide vía `icon_font`).
- NO se toca: `tools/generar_permiso.py`, la BD (`prototipo-bd-adaptado.txt`),
  D1-D15, RB-01..RB-19.

## Restricciones

- Todo en español (textos de UI); sin emojis como iconos.
- Un solo server OpenPencil a la vez (ya está corriendo en el puerto 3100 ligado al
  archivo destino): NO ejecutar `op start` / `op stop` durante el trabajo.
- JSON estricto en los payloads; `fill` siempre como array; íconos con `iconFontName`.

## Tareas

| ID | Tarea | Estado |
|----|-------|--------|
| O1 | Verificar instalación OpenPencil (CLI + desktop + server headless) | Hecho |
| O2 | Crear `docs/prototipo/pantallas.op` y arrancar server ligado al archivo | Hecho |
| O3 | Construir las 8 pantallas respetando el estilo `clean-blue-mobile-light` | Hecho |
| O4 | Exportar 8 PNG a `docs/prototipo/v2/` | Hecho |
| O5 | Verificar paridad funcional pantalla por pantalla contra el HTML | Hecho |

## Estado de la ejecución (2026-10-15)

- 8 frames construidos y guardados: `n610` 1 Login (724), `n21` 2 Recuperar (1667),
  `n84` 3 Crear cuenta (1096), `n145` 4 Home (1036), `n642` 5 Inscripción (2093),
  `n773` 6 Mis permisos (1139), `n853` 7 Perfil (1584), `n941` 8 Panel admin (1454).
  Todos 402px de ancho, alto automático (`fit_content`), 622 nodos en total.
- O5 verificado con `paridad.py` (script de verificación): 72/72 textos y reglas
  clave presentes en el `.op`, 0 mojibake, acentos UTF-8 correctos.
- Límite 8/3 por condición representado en la pantalla 5 (bloque "Reglas al
  confirmar" con el mensaje exacto de validación de `prototipo.html`).
- Frame ajeno `n1` ("Formulario Inscripcion", no es de este proyecto): quitado del
  `.op` entregable con verificación de 0 referencias residuales. Sigue intacto en la
  sesión viva del editor; respaldo en `%TEMP%\opencode\pantallas_backup_con_ajeno.op`.
  ATENCIÓN: cualquier `save_document` posterior lo re-incluye → repetir `quitar_ajeno.py`.
- Lint: 40 avisos (37 warning + 3 info), 0 errores.
- Pendiente fuera de alcance: los paneles Alumnos, Mesas y Usuarios del admin
  (pantalla 8) no están diseñados como frames; sí lo están el control de tabs, el
  panel Inscripciones y la tarjeta Permisos.
- Hallazgo de diseño corregido: "Guardar cambios" del Perfil pasó de botón
  secundario a primario (la pantalla quedaba sin ancla visual: 436 px de acento).

## Criterios de aceptación

1. `pantallas.op` tiene 8 frames de nivel 1, uno por pantalla (Login, Recuperar,
   Crear cuenta, Home, Inscripción, Mis permisos, Perfil, Panel admin).
2. Cada pantalla conserva sus elementos funcionales: campos, botones, avisos y
   textos de reglas (RB-xx / Dxx) presentes en la maqueta HTML.
3. La inscripción mantiene: selector de condición por materia (D15), contador
   "X de 6 asignaturas" (RB-13), aviso de 2 permisos por mezcla de condiciones
   (RB-18) y el límite 8/3 por condición.
4. "Mis permisos" mantiene la descarga directa al celular (RB-09, sin PDF guardado
   en la BD) y la nota RB-14 (borrador hasta la firma del Secretario).
5. 8 PNG exportados y legibles (> 10 KB cada uno).

## Verificación aplicable

- `op get --depth 2` → 8 frames raíz.
- `op export-frames --output-dir docs/prototipo/v2 --format png` → 8 archivos.
- Lectura cruzada HTML vs diseño (paridad funcional).

## Estado para continuar (cierre 2026-10-15)

Entregable principal: `docs/prototipo/pantallas.op` (8 frames, sin el frame ajeno) +
8 PNG en `docs/prototipo/v2/`. Lint sin errores. Criterios 1-5 verdes.

Evidencias numéricas de esta sesión:

- PNG (804 px a 2x, alto = alto del frame): `01-login` 63961 B / 1448,
  `02-recuperar-acceso` 154618 / 3334, `03-crear-cuenta` 104857 / 2192,
  `04-home-alumno` 109067 / 2072, `05-inscripcion-materia` 226881 / 4186,
  `06-mis-permisos` 115090 / 2278, `07-perfil` 132750 / 3168,
  `08-panel-admin` 144398 / 2908.
- Acento (#2563EB) por PNG: 56044 / 223457 / 62871 / 64657 / 73807 / 42113 /
  58596 / 22354 px. La corrección del Perfil subió su acento de 436 a 58596 px.
- Paridad: 72/72 textos y reglas clave presentes; 290 textos en el `.op` (299 − 9 del
  frame ajeno); 0 mojibake. Los 181 fragmentos del HTML se auditaron: 52 ausentes,
  todos de *chrome* de la maqueta, emojis, tabs en MAYÚSCULAS o divisiones
  deliberadas de fechas en dos líneas. Brecha real: paneles Alumnos, Mesas y Usuarios
  del admin (pantalla 8) no diseñados como frames.

Decisiones pendientes del usuario (no bloquean lo hecho):

1. ¿Armar `docs/prototipo/pantallas-diseno-v2.docx` con las 8 capturas nuevas y la
   misma explicación por pantalla? El `.docx` actual (647909 B) documenta el prototipo
   HTML, no el rediseño, así que no está obsoleto; sería una versión adicional.
2. ¿Completar los 3 paneles del admin (Alumnos, Mesas, Usuarios) como frames extra?
   Está fuera del alcance original (8 pantallas) y requiere autorización.

Pendientes técnicos heredados (sin cambios):

- Los scripts de construcción viven solo en `%TEMP%\opencode\` (`opx_helpers.js`,
  `batch_a|b|c.js`, `build_a|b|c.js`, `paridad.py`, `verify_screens.py`,
  `quitar_ajeno.py`, `inspect_op.py`, `inspect_docx.py`, `diag_engram*.py`).
  Decisión pendiente: copiarlos al repo (por ejemplo `docs/prototipo/build/`).
- Cualquier `save_document` futuro re-incluye el frame ajeno → repetir
  `quitar_ajeno.py` y reexportar.
- Validación SQL contra PostgreSQL real sigue pospuesta (no hay motor local).

Bloqueo de memoria (resuelto en su causa): ver `odd/notas/engram-sesion-cerrada.md`.
Las memorias de Engram de esta sesión NO se pudieron guardar por el plugin; el
registro fiel de esta sesión es este archivo.
