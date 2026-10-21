# Feature: Combinación de los 2 diseños (maqueta pre-diseño)

## Objetivo

Unificar en una sola maqueta lo mejor de ambos diseños:

- **Diseño 1** (`docs/prototipo/prototipo.html`, aprobado 14/10): conservar su **formato,
  tamaño y manejo** — marco de teléfono 390×800 con scroll interno, tab bar fija,
  navegación entre pantallas, controles interactivos.
- **Diseño 2** (`docs/prototipo/pantallas.op`, rediseño OpenPencil 15/10): traer sus
  **iconos** (Lucide, en lugar de los emojis actuales 🏠➕📄👤🗂) y su **manejo de
  colores** (acento #2563EB, badge #DBEAFE, éxito #DCFCE7/#16A34A, aviso #FEF3C7/#B45309,
  borde #E5E7EB, tinta #111827/#6B7280, superficies blancas y #F9FAFB).
- Agregar el **escudo de la escuela** en la pantalla de Login (falta el asset: pendiente
  del usuario).

## Problema

Hoy hay dos diseños paralelos con reglas idénticas (paridad 72/72) pero lenguaje visual
distinto: uno tiene el formato/manejo que sirve para pasar a código, el otro tiene la
paleta y los iconos más prolijos.

## Por qué (alcance autorizado)

Pedido del usuario (2026-10-15): "podríamos hacer una combinación de los 2 diseños, me
gusta el formato de diseño 1 en tamaño y manejo, y del diseño 2 me gusta los emoticones
[y] manejo de colores" + "agreguemos el escudo de la escuela en la pantalla de login".

## Restricción de alcance (recordatorio del usuario)

**Esto es solo PRE-DISEÑO.** No hay backend ni base de datos todavía: la maqueta sigue
siendo un mock con datos de mentira y ninguna acción persiste. Nada de este trabajo
instala servicios, esquemas ni lógica de servidor; todo eso llega cuando el backend esté
listo y podamos manejarnos con una base de datos.

## Alcance

- Se modifica: `docs/prototipo/prototipo.html` (con copia de seguridad previa del estado
  aprobado del 14/10, porque el repo no tiene commits en git).
- NO se toca: `docs/diseno.md`, `docs/modelo/*`, `docs/prototipo/pantallas.op`,
  `docs/prototipo/v2/*.png`, `docs/prototipo/pantallas-diseno.docx`, `tools/generar_permiso.py`,
  reglas D1–D15 / RB-01..RB-19.
- Los textos funcionales NO cambian: sigue valiendo la paridad 72/72 contra el HTML
  original.

## Tareas

| ID | Tarea | Estado |
|----|-------|--------|
| C1 | Copia de seguridad del `prototipo.html` aprobado (14/10) | Hecho |
| C2 | Paleta del diseño 2 en los tokens CSS (acento, superficies, chips, estados) | Hecho |
| C3 | Reemplazar emojis por iconos Lucide (tab bars + cabeceras) | Hecho |
| C4 | Escudo de la escuela en la pantalla de Login | Hecho |
| C5 | Verificación: estructura, paridad de textos, apertura en navegador | Hecho |

## Estado de la ejecución (2026-10-15)

- **C1**: `docs/prototipo/prototipo-aprobado-14-10.html` = 40 557 B, fecha 14/10 intacta
  (el repo no tiene commits, así que este archivo es la única red de seguridad del
  diseño aprobado).
- **C2**: 14 pares de tokens/estilos reemplazados, cada uno verificado por conteo de
  ocurrencias y abortando si no calzaba. Paleta aplicada: `--brand #1d4ed8 → #2563eb`,
  `--ink #151a22 → #111827`, `--muted #66707f → #6b7280`, `--line #dfe4ec → #e5e7eb`,
  `--bg #eef1f6 → #f9fafb` (pantalla en blanco puro), `--ok → #16a34a`,
  `--danger → #ef4444`, `--chip → #dbeafe`, chips `#dcfce7`/`#fef3c7`, superficies
  inset `#f3f4f6`, estados seleccionados `#eff6ff`.
- **C3**: 18 iconos de tab bar + 3 marcas de estado = **21 SVG de Lucide**
  (house, plus, file-text, user, layout-grid, arrow-left, check, triangle-alert)
  incrustados en línea desde `lucide-static` (sin CDN: la maqueta anda sin internet).
  Los emojis 🏠➕📄👤🗂↩ ✅ ⚠ quedaron en **0**. Se mantiene el `👋` del saludo
  "Hola, María": es texto del diseño aprobado, no un icono de UI (avisar si se quiere
  quitar).
- **C4**: `docs/prototipo/logoepet.png` (187 802 B) copiado desde
  `D:\progamacion\Free-claude\logoepet.png`; `<img class="escudo">` + epígrafe
  "E.P.E.T. N°36" centrados arriba de la tarjeta del Login.
- **C5**: tamaño 40 201 → 47 903 caracteres; 8 secciones intactas; diff de textos
  visibles contra el aprobado = **solo se quitaron emojis** (21 líneas) y las líneas
  "4 · Listo" / "Importada" ahora sin su emoji; paridad **72/72**, mojibake 0,
  acentos OK; delta de textos ≥13 caracteres contra el aprobado = **0**.
- Iconos Lucide descargados en `%TEMP%\opencode\icons\` (16 archivos).
- Recordatorio del usuario: esto es **pre-diseño** — sin backend ni base de datos;
  ninguna acción persiste. La validación real llega cuando el backend esté listo.

## Pendiente / opcional

- Iconos de campos (id-card, mail, lock, eye, shield-check) como en el diseño 2:
  no se agregaron todavía porque exigen reestructurar el marcado de cada `<input>`.
- Pregunta abierta: ¿el escudo va también en el header de las demás pantallas o solo
  en Login.

## Decisión registrada al cerrar (2026-10-15, pausa del usuario)

- **"Me gustaban los emojis"**: el usuario le gustaba el diseño original con emojis
  (los que hoy fueron reemplazados por iconos Lucide). Al retomar hay que decidir:
  restaurarlos, mezclarlos con Lucide, o mantener solo Lucide.
- **Iconos de campos sí**: además pidió los iconos de campos del diseño 2
  (id-card, mail, lock, eye) — pendiente, no se hizo hoy.
- Trabajo **pausado a pedido del usuario** ("seguiremos modificando pero lo dejamos
  por hoy"); ninguna de las dos cosas se aplica hasta que él lo indique.

## Criterios de aceptación

1. El formato y el manejo del diseño 1 quedan idénticos: mismo marco 390×800, mismo
   scroll interno, misma navegación y controles.
2. Cero emojis como iconos en la maqueta; iconos vectoriales tipo diseño 2.
3. Los valores de color provienen de la paleta del diseño 2 (acento #2563EB).
4. El login muestra el escudo de la escuela (mientras no haya imagen, queda marcado).
5. Los textos y reglas del HTML aprobado están intactos (paridad 72/72).
6. El archivo abre en el navegador sin errores de sintaxis.

## Verificación aplicable

- Copia de seguridad verificada por tamaño/fecha antes de editar.
- Conteo de emojis restantes y de iconos agregados.
- Tokens de color leídos del CSS resultante.
- Apertura en navegador (revisión del usuario) + paridad de textos funcionales.
