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
| C6 | Restaurar los 3 emojis de estado (decisión "Mezclar ambos") | Hecho |
| C7 | Arreglar los `<span class="ico">` duplicados en los 18 botones de tab | Hecho |
| C8 | Iconos de campo del diseño 2 (inputs, selects, eye funcional) | Hecho |
| C9 | Verificación: paridad de textos + conteos + balance de tags | Hecho |

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

## Estado de la ejecución (2026-10-27, reanudación)

- **C6 — Mezcla de estilos (decisión del usuario: "Mezclar ambos")**: se restauran los
  3 emojis de estado que C3 había pasado a Lucide: `4 · Listo ✅`, `Importada ✅`,
  `Sin fecha ⚠`. Se mantienen Lucide en las 18 barras de tab y cabeceras. Quedan en la
  maqueta: `👋` (saludo, texto del diseño aprobado) + los 3 emojis de estado; cero
  emojis como icono de navegación.
- **C7 — Bug de markup**: los 18 botones de tab tenían `<span class="ico"><span class="ico">`
  (span duplicado) y su cierre `</svg></span></span>`; corregido con replaceAll y
  verificado: ocurrencias de span doble = 0.
- **C8 — Iconos de campo (diseño 2)**, mapeo exacto extraído de `pantallas.op`
  (inventario: user×9, lock×8, id-card×3, mail×3, phone×2, map-pin×1,
  graduation-cap×1, eye×1, chevron-down×4):
  - Login: `user` en "Usuario o correo"; `lock` + **ojo funcional** (único eye del
    diseño 2) en Contraseña — botón `.eye` que alterna `type password/text` vía JS.
  - Recuperar: `id-card` (D.N.I.), `mail` (Correo), `lock` ×2 (contraseñas).
  - Registro: `user` ×2 (Nombre/Apellido), `id-card`, `mail`, `phone`, `lock` ×2.
  - Perfil: `user` ×2 (ro), `id-card` (ro), `graduation-cap` + chevron en el select
    Tecnicatura, `map-pin` (Dirección), `mail`, `phone`, `lock` ×3.
  - Los 5 `<select>` (4 cond + Tecnicatura) reciben chevron derecho
    (`appearance:none` + data-URI), incluido el `:disabled`.
  - Iconos como **data-URI en CSS** (`background-image`), sin cambiar textos:
    `input.ico-user|ico-id|ico-mail|ico-phone|ico-pin|ico-grad|ico-lock`,
    color `#9CA3AF`, 16px, `padding-left:36px`.
  - **Nota de alcance**: el registro anterior enumeraba "(id-card, mail, lock, eye)";
    el diseño 2 usa además `user`, `phone`, `map-pin`, `graduation-cap` y `chevron-down`
    en campos — se aplicó el set completo por fidelidad a "como en el diseño 2".
    Si el usuario quiere recortar, es quitar clases (reversible).
- **C9 — Verificación (2026-10-27)**:
  - Diff de textos extraídos (método idéntico al snapshot previo): **delta visible =
    solo las 3 líneas de emoji** (`-4 · Listo`/`+4 · Listo ✅`, `-Importada`/
    `+Importada ✅`, `-Sin fecha`/`+Sin fecha ⚠`); el resto del diff son líneas de
    CSS/JS ( invisibles dentro de `<style>`/`<script>` ).
  - Conteos: SVGs Lucide **18** (solo tabs), spans dobles **0**, `type="password"` **8**
    (8 con `ico-lock`), botón eye **1**, selects **5**, emojis de estado **3/3**.
  - Balance de tags: span 48/48, div 110/110, section 8/8, button 80/80.
  - Limpieza: CSS huérfano `.mi` (quedó sin uso al restaurar los emojis) eliminado.
  - Snapshot de paridad: `%TEMP%\opencode\parity_before.txt` (previo) /
    `parity_after.txt` (post).

## Pendiente / opcional

- ~~Iconos de campos~~ → **C8 hecho (2026-10-27)**: aplicados los iconos de campo del
  diseño 2 (ver "Estado de la ejecución (2026-10-27)").
- Pregunta abierta: ¿el escudo va también en el header de las demás pantallas o solo
  en Login. **Default aplicado: solo Login** (marcado como supuesto; cambiar si el
  usuario pide lo contrario).

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
2. *(amendado 2026-10-27 — decisión "Mezclar ambos")* Los emojis solo quedan donde
   estaban en el diseño aprobado: saludo (`👋`) y estados (`✅` ×2, `⚠` ×1). La
   navegación (tabs) y cabeceras usan iconos vectoriales Lucide del diseño 2.
3. Los valores de color provienen de la paleta del diseño 2 (acento #2563EB).
4. El login muestra el escudo de la escuela (mientras no haya imagen, queda marcado).
5. Los textos y reglas del HTML aprobado están intactos (paridad 72/72); el único
   delta de texto visible autorizado tras la reanudación son los 3 emojis de estado.
6. El archivo abre en el navegador sin errores de sintaxis.
7. Los campos con icono del diseño 2 los muestran; los textos de ningún input cambian.

## Verificación aplicable

- Copia de seguridad verificada por tamaño/fecha antes de editar.
- Conteo de emojis restantes y de iconos agregados.
- Tokens de color leídos del CSS resultante.
- Apertura en navegador (revisión del usuario) + paridad de textos funcionales.

## Log

- **L1 — petición original (2026-10-15, verbatim):** "podríamos hacer una combinación
  de los 2 diseños, me gusta el formato de diseño 1 en tamaño y manejo, y del diseño 2
  me gusta los emoticones [y] manejo de colores" + "agreguemos el escudo de la escuela
  en la pantalla de login".
- **L2 — pausa del usuario (2026-10-15, verbatim):** "seguiremos modificando pero lo
  dejamos por hoy"; decisiones registradas: "Me gustaban los emojis" (a retomar:
  restaurar, mezclar o mantener Lucide) e "Iconos de campos sí" (id-card, mail, lock,
  eye) — pendientes.
- **L3 — reanudación (2026-10-27):** el usuario pidió retomar la tarea 1 con la regla
  **"no tocar backend ni BD"** (el backend es fuente de verdad en solo lectura) y
  respondió a la pregunta de estilo: **"Mezclar ambos"** — emojis donde estaban
  (saludos, estados, mensajes) y Lucide solo en la barra de tabs y cabeceras. F3 (rate
  limit) y la discrepancia de ruta de la landing quedan aparcados a pedido del usuario.
  Aplicado en C6–C9 (ver "Estado de la ejecución (2026-10-27)").
- **L4 — pedido de filtro (2026-10-28, verbatim):** "que el filtro este en materia
  disponibles tambien, y en el registro de lo que ya mi incribi no tenga filtro por año
  como tiene" + "materias disponibles debe tener ese filtro" + "guarde y seguimos
  despues". El tramo quedó sin cerrar.
- **L5 — decisión de aclaración (2026-11-02):** ante la ambigüedad de L4, el usuario
  eligió la opción **"Dividir en dos bloques"**: *"Separar la pantalla en 'Materias
  disponibles' (con filtro por año) y 'Mis inscripciones' (lista propia, siempre
  completa y sin filtro)."* Aplicado en `docs/prototipo/prototipo.html`: dos tablas
  (`#materias-disponibles` con `#anios`, `#mis-inscripciones` sin filtro),
  `actualizarTabla()` reubica cada fila según el estado y reaplica el filtro activo
  sólo al bloque disponible. Verificado: bloques JS compilan (`new Function`), 11 filas
  disponibles / 4 inscriptas.
- **L6 — informe del colega (2026-11-02):** leído `informes/informe-devolucion-colega-sdd4.md`
  (backend → frontend, 31/10). Correcciones pendientes para el prototipo: quitar el
  "Máximo 6 materias por permiso (RB-13)" (no existe en las fuentes) y el contador
  "X de 6 asignaturas", corregir citas RB desalineadas (RB-01/RB-16/RB-08), y decidir
  PD-A/PD-B (registro libre vs aprobación — contradicción que el informe remite al
  cliente). Límites por condición del prototipo (8/3/sin tope) confirmados correctos.
- **L7 — corrección de errores propios (2026-11-02, verbatim):** "entonces corrige
  nuetros errores y ve comentando que se va midificando y como va ir quedando poarte
  por parte". Hecho parte por parte: (1) repo backend local sincronizado — `main`
  fast-forward +27 commits a `6018204`, rama `feat/sdd-2-sigme-base` local repuesta a
  origin (descartando el duplicado `18fc09f`, superado por `7a1370d`); solo queda
  sin push la línea abandonada `feat/m1-app-modelo` (decisión del usuario). (2)
  Prototipo: fuera "Máximo 6 materias (RB-13)" → límite por condición (RB-03: Previa
  3 / Regular 8 / Completar-Equivalencia sin tope); contador dinámico por condición
  (single "4 de 8", mixto "6 asignaturas · REGULAR 3/8 · PREVIA 2/3", sin límite
  oculta la barra); citas falsas RB-01/RB-16 y RB-08 eliminadas (3 en pantalla).
  (3) `cargarMaterias()` + `cascadaDesde()` creadas y conectadas a `ir('home')` —
  `GET /api/v1/mesas-disponibles` con manejo 409 `ventana-cerrada` / caída, cascada
  G-04 desde combinaciones únicas (contrato verificado en la rama sdd-4:
  `MesaDisponible`). (4) Informes conservados corregidos: `app-completa` (§2.1–2.5
  reescritos al contrato §5.2, nota PD-A/PD-B, §2.4 tabla `us_password_reset` ya
  existe, fix por `7a1370d`, orden §5 realineado) y `modificaciones` (push hecho →
  falta PR, reconciliación resuelta, firma/tests 181). Verificado: 2 bloques JS
  compilan, cero residuos de "6"/RB-13/RB-08/18fc09f-activo en ambos informes.
  Queda: revisión en navegador del split de tablas (Risk item 6) y decisión sobre
  PR #5 / `m1-app-modelo`.
- **L8 — Perfil y origen de materias (2026-11-02, verbatim):** "en perfil, porque
  aparece mis datos desde el backend, mis datos son tomados desde que creo mi cuenta,
  y el rol ya esta definido, porque solo hay dos roles en esta aplicacion para usarlos,
  admin y alumno el cual debe incribirse a las materias, no deberia aparecer eso, solo
  mis datos" + "las materias son sacadas cuando con la otra aplicacion son dadas de alta
  para incripcion atravez de la otra aplicacion la cual es de escritorio".
  Regla de diseño resultante: (a) Perfil muestra **solo mis datos** de cuenta — fuera
  la tarjeta "Mis datos (desde el backend)" (ID/Usuario/Roles/Permisos/Módulos) y fuera
  el "Roles: … · Módulos: …" del topbar de Home; el rol (admin/alumno, definido al
  crear la cuenta) no se muestra ni se edita en la vista del alumno. (b) El alta de
  materias para inscripción la hace la **aplicación de escritorio** del colegio; esta
  app solo las lee (GET), sin tocar backend ni BD — texto "Cómo funciona" de Home
  actualizado. Aplicado en `docs/prototipo/prototipo.html`: tarjeta eliminada,
  `cargarPerfil()` solo rellena el nombre de cuenta, sin rastro de `usuario-roles` /
  `home-datos` / "Roles: " / "desde el backend". Verificado: 2 bloques JS compilan.
- **L9 — Ficha de alumno en el panel admin (2026-11-02, verbatim):** "en el panel
  administrador debera poder modificar los datos del alumno con su contraseña si lo
  requiera, aparte de ver su ficha, y un registro de las materia que se incirbio
  anteriormente, podra tambien dar de baja al alumno si es requerido".
  Aplicado en `docs/prototipo/prototipo.html` (pestaña Alumnos): la lista queda envuelta
  en `#lista-alumnos` y se agrega la tarjeta `#ficha-alumno` que se abre con "Ver
  ficha" / "Editar" (por alumno: `data-ficha`): (a) **datos personales** en modo sólo
  lectura con botón "Modificar datos"; (b) **editar con contraseña**: el modo edición
  muestra "Contraseña del admin (requerida para guardar)" — guardar sin contraseña
  muestra el error y no aplica (supuesto: "su contraseña" = la del admin; si el usuario
  quiere otra cosa, se cambia); (c) **Inscripciones anteriores**: tabla materia / fecha
  / condición / estado con el histórico del alumno (actuales + convocatorias previas,
  datos mock: María 6 filas, Lucía 6); (d) **Dar de baja**: `confirm()` → chip "Dado de
  baja" en ficha y en la lista, botón queda inactivo, no persiste (mock, se revierte
  refrescando). Verificado: 2 bloques JS compilan, 0 ids duplicados, divs 132/132.
- **L10 — Prueba de flujo con backend mock (2026-11-02):** el usuario dijo "si" a
  probar el flujo de Home con `cargarMaterias`. Antes de probar aparecieron **2 errores
  propios**: (1) `$inputModulo` se usaba en el handler de login pero nunca existió
  (ni variable ni `#input-modulo`) → "Iniciar sesión" tiraba ReferenceError y el login
  no podía funcionar jamás — corregido quitando la línea y el arg. extra de la llamada;
  (2) `estadoMaterias` se fetcheaba y guardaba pero **nadie lo mostraba** — agregado
  `#estado-sync` bajo "Materias disponibles" + `pintarEstadoSync()` que pinta: ✓ N
  mesas (verde) / ventana-cerrada / sin-conexion / HTTP error. Mock backend propio
  (temp, fuera del repo) con el contrato sdd-4 en `localhost:8000` (login, /auth/yo,
  GET mesas-disponibles con 6 mesas, control `/__modo` ok|409|500, CORS para file://).
  Test jsdom **21 OK / 0 FAIL**: login → home con token; ok → 6 mesas + cascada
  (2 orientaciones / 2 cursos / 6 materias / 3 condiciones, sin grupo_id RN-019) +
  estado verde; 409 → aviso; 500 → error rojo; sin-conexion → aviso + tabla estática
  intacta; cargarHome saludo con username y **sin "Roles:"** (regla L8). Dejado el mock
  corriendo para prueba manual en navegador.
- **L11 — Login de prueba y saludo con el nombre (2026-11-02, verbatim):** "acuerdate
  que es un login de prueba, el lgin lo aprueba el otro sistema" + "y en ves de decir
  hola y aparezca el numero de documento aparezca el mombre del alumno".
  (a) Copys de aprobación corregidas en `docs/prototipo/prototipo.html`: topbar de
  login → "Login de prueba · el acceso real lo aprueba el otro sistema"; nota de flujo
  → las credenciales reales las administra el otro sistema (aplicación de escritorio);
  registro paso 3 y "Cómo funciona" → la aprobación de la cuenta la hace el otro
  sistema, no el panel de nuestra app. (b) Saludo de Home y topbar de Perfil muestran
  el **nombre del alumno**: helper `nombreVisible(me)` (nombre+apellido, fallback
  username) y el mock `/auth/yo` ahora devuelve `nombre: 'María Soledad',
  apellido: 'Pérez'`. (c) Hallazgo de contrato (solo lectura, para informar al
  colega): el backend real NO expone el nombre al alumno — `/auth/yo` (§2.1) solo
  trae claims y `GET /personas` exige `persona.listar` que el alumno no tiene (seed:
  solo mesa.listar / inscripcion.*) → contra el backend real el saludo cae a username
  (DNI); hueco a proponer: sumar nombre/apellido a `YoResponse`. (d) `doLogin` ahora
  envía `modulo: 'sigme_web'` — §2.8: `LoginRequest.modulo` es obligatorio en el
  backend real (es constante de la app, no un input). Verificado: flow-test **22 OK /
  0 FAIL** (2 checks nuevos: saludo sin DNI + perfil con nombre), smoke **31 OK /
  0 FAIL**; mock relanzado en :8000 con nombre/apellido para la prueba manual.
- **L12 — Verificación total sistema (2026-11-04, verbatim del 02/11 17:06):**
  "verifica todo, ve si el sistem corre segun el backend y la base de datos, y si
  hay errores, comenta que falta y que sigue". Resultado: (a) prototipo: 2 bloques
  JS compilan (0 fail) y el mock de :8000 que quedó de la sesión anterior responde
  login/yo/mesas-disponibles (6 mesas); (b) backend real (`backend-epet-n36-main`,
  main @6018204): arranca OK, `/healthz` db=ok tras calentar (los primeros pings
  caen en el timeout de 2s con Neon frío — hallazgo menor), **120 tests passed**;
  (c) **endpoint faltante en main**: el OpenAPI no incluye
  `/api/v1/mesas-disponibles` ni `/api/v1/inscripciones` — están sólo en
  `origin/feat/sdd-3-mesas` / `origin/feat/sdd-4-inscripciones` (y ramas m3),
  pushadas SIN PR → contra main el prototipo no puede cargar mesas reales;
  (d) **BD Neon vacía**: 23 tablas (incl. es_mesa_examen/es_mesa_inscripcion) pero
  0 usuarios, 0 roles, 0 permisos, 0 materias, 0 mesas, 0 personas → login real
  siempre "credenciales-invalidas" y nada que listar; (e) **alembic desalineado**:
  `alembic_version=0001` en la BD mientras el repo llega a 0003 — faltan 0002
  (aud_evento, us_password_reset) y 0003 (seed) por aplicar; el seed de
  roles/permisos nunca corrió (0 filas) y no hay usuario de prueba;
  (f) contrato: `/auth/yo` real no trae nombre/apellido (hueco ya anotado en L11).
  Sigue: decidir merge de PR #5 y de sdd-3/sdd-4 (o usar ramas m3), alinear
  alembic + correr seed + crear usuario de prueba, y el destino de
  `feat/m1-app-modelo`.
- **L13 — BD Neon alineada + bug de la migración 0003 (2026-11-04):** la
  alineación pedida ("luego alinia BD") destapó que **la migración 0003 nunca
  pudo ejecutarse en ninguna máquina**: (1) coma de más después de la última
  fila de VALUES antes de `ON CONFLICT` (3 INSERT: roles, matriz, condiciones);
  (2) las columnas declaraban `activo, created_at` pero cada fila solo traía 2
  valores → "INSERT has more target columns than expressions". Los tests no lo
  veían porque `test_migration_ddl` solo lee el archivo, no corre la SQL contra
  una base real. Corrección local (sin commitear) en
  `backend-epet-n36-main/alembic/versions/0003_seed_roles_condiciones.py`:
  comas quitadas + columnas reducidas a `(codigo, descripcion)` y
  `(descripcion, limite_materias)` (los DEFAULTs de 0001 cubren el resto).
  Aplicado: `alembic upgrade head` → **0003 (head)**; 0002 creó
  `us_password_reset` + `aud_evento` (con trigger append-only). Seed de la app:
  3 módulos + 13 permisos; matriz rol×permiso = **42 pares** (0003 insertó
  roles=5 y condiciones=3, la matriz quedó en 0 porque corre contra us_permiso
  vacío — la completa `seed_roles` después). Lookup `pe_documento_tipo` insertado
  (DNI/LC/LE/Pasaporte, estaba vacío). Usuarios de prueba creados con Argon2id:
  `alumno01`/`Alumno1234` (rol alumno, módulos sigme_web+sigme_mobile) y
  `admin01`/`Admin1234` (rol administrador, sigme_web), cada uno con su
  `pe_persona`. Verificación en vivo (:8001): login de ambos OK con JWT
  (roles/permisos claims correctos), `/auth/yo` OK (confirma en vivo que NO
  trae nombre/apellido → hueco L11), `GET /mesas-disponibles` → **404**
  (confirmación en vivo del Error 1), healthz `db: ok`; suite backend
  **120 passed** tras la corrección.
- **L14 — Endpoints sin merge en GitHub + backend real sirviendo en :8000
  (2026-11-04, verbatim):** "resuelve y deja como el backend real lo requiera,
  resuelve endpoint sin marge". Resuelto SIN tocar GitHub: rama local
  `feat/sdd-4-inscripciones` creada desde `origin/feat/sdd-4-inscripciones`
  (contiene main + sdd-3 + 7 commits: convocatoria-vigente, mesas-disponibles,
  POST/GET/DELETE inscripciones, SIGME mesas, migración 0004) — cero merges,
  cero pushes. En el camino: (a) **bug #3 del colega** en 0004 — crea el enum
  `plataforma_dispositivo` con `create(checkfirst=True)` y `create_table`
  vuelve a emitir CREATE TYPE → "type already exists"; fix local con
  `postgresql.ENUM(..., create_type=False)` en la columna (sin commitear);
  `alembic upgrade head` → **0004 (head)**; (b) CORS de desarrollo:
  `CORS_ORIGINS=[] → ["*"]` en `.env` (la validación de `*` es solo
  producción) — verificado `access-control-allow-origin` con Origin `null`
  (file://) y preflight OPTIONS 200; (c) seed de demo en Neon (idempotente):
  2 orientaciones + 2 cursos + 6 materias (acentuadas) + convocatoria "Mesas
  Diciembre 2026" (2026-10-01→12-31, estado **abierta**) + 1 grupo (20/11
  08:00) + **6 mesas** con snapshots; se mató el mock de :8000 (PID 5300) y
  el backend **real** quedó corriendo ahí — el prototipo (API_BASE=:8000) ahora
  habla con el backend real, sin cambiar su código. E2E con `alumno01`:
  login 200 → convocatoria-vigente `abierta` → mesas-disponibles **6** con
  acentos → POST /inscripciones **201 `inscripto`** → mis-inscripciones OK →
  healthz `db: ok`; CORS OK; prototipo JS 2 bloques compilan; suite rama
  **235 passed** (con los fixes 0003+0004). Hueco conocido: `/auth/yo` real
  no trae nombre/apellido → el saludo de Home cae a username (`alumno01`);
  agregarlos a `YoResponse` es cambio de contrato del colega, pendiente de
  decisión.
- **L15 — Pedido automático de recuperación de clave (2026-11-04, verbatim):**
  "que sea el pedido automatico luego el admin lo blanquea"; "nosostros solo
  hacemos el pedido". Decisión de flujo: el alumno pide el blanqueo desde
  nuestra app (automático), el administrador lo ve y blanquea en la app de
  escritorio del colegio, y nuestra app ofrece poner la clave nueva después
  (Perfil → Contraseña → /auth/cambiar-clave). Implementado (todo SIN
  commitear): (a) backend rama local feat/sdd-4-inscripciones —
  **POST /api/v1/auth/olvido-clave** (202 siempre con {"status":"solicitado"},
  identificador = username O email case-insensitive, fila en us_password_reset
  con usado_en NULL y expira_en +24 h [supuesto], un solo pedido vigente por
  usuario, token_hash = marcador opaco hasheado porque la columna NOT NULL
  única es contrato PD-04 — este flujo NO emite tokens ni usa email, reemplaza
  el RB-19 de código por correo); tests RED→GREEN (5 nuevos) y **suite 240
  passed**; (b) prototipo — pantalla "Recuperar acceso" pasa de 4 pasos mock
  (código al correo) a **2 pasos con POST real**, copy del login actualizado,
  y la tarjeta "Contraseña" de Perfil cableada a /auth/cambiar-clave (valida
  12 caracteres, guarda el access nuevo); JS 2/2 bloques compilan; (c) E2E
  real contra :8000 — 202 idéntico exista o no la cuenta, fila verificada en
  Neon (pendiente, 24 h, hash 64), cadena login → cambiar-clave → login con la
  clave nueva → clave vieja 401; después restauré Alumno1234 y marqué la fila
  usada (simulando el blanqueo del admin). **Contrato para el colega** (lo que
  falta de SU lado): el escritorio debe listar us_password_reset WHERE
  usado_en IS NULL AND expira_en > now(), blanquear password_hash y marcar
  usado_en; confirmar que el escritorio comparte esta BD. Nota: Neon free tier
  suspende la compute — el primer arranque tardó ~11 s (ping 2 s expiró).
- **Commits de L15 (2026-11-05):** backend `634777e` fix(alembic 0003+0004) y
  `44128a5` feat(auth: olvido-clave) en `feat/sdd-4-inscripciones`; app `055a9f7`
  feat(prototipo: recuperación + informe colega). Sin push (queda decisión del
  usuario); informe para envío en `informes/informe-para-colega-recuperacion-clave.md`.
- **Rebase (2026-11-05):** las 2 commits de L15 se rebasearon sobre la punta
  remota `d3beed0` (SDD-5 reportes) — cero conflicto (sin solape de archivos).
  Nuevos hashes: `852c57e` (fix alembic) y `48e1b72` (olvido-clave); reemplazan
  a 634777e/44128a5. Verificación: 277 passed + ruff limpio. Sin push.
