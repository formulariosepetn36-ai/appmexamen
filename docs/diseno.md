# Diseño — App de Inscripción a Mesas de Examen
**Escuela Secundaria E.P.E.T. N°36 — Posadas, Misiones**

| | |
|---|---|
| Versión | 3 — borrador en revisión |
| Fecha | 2026-09-28 |
| Estado | **NO DEFINITIVO** — se itera con el usuario |

---

## 1. Alcance

App **para celular** que permite a los alumnos de las dos tecnicaturas de la E.P.E.T. N°36
registrarse, mantener su perfil e **inscribirse por sí mismos** a las mesas de examen, y
descargar el **Permiso de Examen** en PDF (el mismo formulario A4 de la escuela).

Fuera de alcance en v1 (se definen después):
- Elección de backend y base de datos (el diseño del modelo es agnóstico).
- Notificaciones push, chat, calificaciones, asistencia.

---

## 2. Roles y permisos

| Acción | Alumno | Administrador |
|---|:--:|:--:|
| Registrarse / iniciar sesión | ✅ | ✅ |
| Ver sus propios datos | ✅ | ✅ |
| Editar Tecnicatura, Dirección, Correo, Teléfono | ✅ (con verificación) | ✅ |
| Editar DNI, Nombre, Apellido | ❌ | ✅ |
| Cambiar su contraseña | ✅ (con contraseña actual) | ✅ |
| Resetear / asignar contraseña de otro usuario | ❌ | ✅ |
| Inscribirse a materias | ✅ (solo las suyas) | ❌ (solo supervisa) |
| Ver / editar inscripciones de cualquier alumno | ❌ | ✅ |
| Elegir la condición de cada materia al inscribirse | ✅ (por defecto REGULAR) | ✅ (solo corrige) |
| Completar LIBRO / FOLIO del permiso | ❌ | ✅ |
| Descargar Permiso de Examen | ✅ (el propio) | ✅ (cualquiera) |

**Credenciales iniciales:** `admin` / `admin`.
**Regla propuesta:** obligar cambio de contraseña en el primer ingreso.

---

## 3. Mapa de pantallas

### 3.1 Acceso (común)
```
PANTALLA DE LOGIN
├─ Usuario / Correo + Contraseña        → Iniciar sesión
├─ "Crear cuenta"                       → Registro del alumno
├─ "Olvidé mi contraseña"               → RECUPERAR ACCESO (ver §3.1.1)
└─ (solo si el usuario es admin)        → entra directo al panel de administración
```

### 3.1.1 Recuperar acceso (sección nueva)
Flujo en 4 pasos. La identidad se referencia por **D.N.I.** y se valida con un
código enviado al **correo oficial** del alumno (el que figura en su ficha).

```
1 · IDENTIFICAR
   ├─ D.N.I.                          (obligatorio → RB-19)
   ├─ Correo electrónico               (debe coincidir con el registrado)
   └─ Validar: si D.N.I. y correo no coinciden → error genérico (no filtrar si existe)
2 · VERIFICAR POR CORREO
   ├─ Envía un código de 6 dígitos al correo registrado
   │    ├─ Expira en 15 minutos, un solo uso (RB-07 / RB-19)
   │    ├─ Reenviar (con cooldown de 60 s)
   │    └─ 5 intentos fallidos → bloqueo temporal de 15 min
   └─ Ingresar el código
3 · NUEVA CONTRASEÑA
   ├─ Nueva contraseña / Repetir contraseña   (mismas políticas del registro)
   └─ Guardar → el token queda usado (no se puede reutilizar)
4 · CONFIRMAR
   └─ "Contraseña actualizada" → volver al login
```

**Reglas de seguridad del flujo:**
- El mensaje de error es **siempre el mismo** exista o no el D.N.I. / correo:
  *"No pudimos validar tus datos. Revisá el D.N.I. y el correo."*
  (así no se descubre qué D.N.I. está registrado — RB-01/RB-19).
- El correo debe estar **verificado** (`students.email_verified_at`): si no lo está,
  no se envía código y se pide a un admin que lo verifique a mano (RB-07).
- El código viaja por `password_resets` (token, `expires_at`, `used_at`) — misma
  tabla que ya existe en el modelo (§4).
- **El admin no recupera por este flujo**: su contraseña la resetea otro admin
  (§2) — el D.N.I. de un admin no está en `students`.


### 3.2 Registro del alumno (Primer objetivo)
```
CREAR CUENTA
├─ Nombre
├─ Apellido
├─ D.N.I.                      (un solo registro por D.N.I. → ver RB-01)
├─ Correo electrónico           (se verifica con código)
├─ Teléfono
├─ Tecnicatura  [ ● TECNOLOGÍA DE LOS ALIMENTOS   ○ GESTIÓN ORGANIZACIONAL ]
├─ Contraseña / Repetir contraseña
└─ Crear cuenta → queda PENDIENTE DE VERIFICAR CORREO → entra a la app
```

### 3.3 Zona del alumno
```
HOME — Mis inscripciones
├─ Permisos con sus materias, cada uno con SU condición
└─ Botón "Inscribirme a una materia"

INSCRIPCIÓN A MESA
├─ Tecnicatura (la del alumno, bloqueada)
├─ Año [ 1° | 2° | 3° | 4° | 5° | 6° ]
├─ Materias del año, cada una con SU mesa única
│    ├─ Materia  →  Mesa [ fecha · horario · lugar ]   (una sola por materia)
│    ├─ Materia elegida → Condición [ ▼ REGULAR ]      (la elige el ALUMNO → D15)
│    ├─ Materia YA inscripta → queda marcada (puedo desinscribirme)
│    └─ Materia sin fecha cargada → deshabilitada, aviso "sin fecha"
├─ Contador: "4 de 6 asignaturas"        (máximo 6 por permiso → RB-13)
├─ Resumen: materia + fecha/horario + condición elegida
├─ Si hay condiciones DISTINTAS → aviso: "se generarán 2 permisos" (RB-18)
└─ Confirmar → genera 1 Permiso de Examen por condición (PDF, 1 copia en A4)

PERFIL
├─ Solo lectura: D.N.I. · Nombre · Apellido
├─ Editar: Tecnicatura · Dirección · Correo · Teléfono
│     └─ Verificación: contraseña O código al correo  →  guardar
├─ Cambiar contraseña
│     └─ Contraseña anterior · Nueva contraseña · Repita la nueva contraseña
└─ Cerrar sesión

PERMISOS
└─ Historial de permisos emitidos → Ver · Descargar PDF
```

### 3.4 Panel del administrador
```
ADMIN — Dashboard
├─ ALUMNOS
│  ├─ Buscar (D.N.I. · apellido · nombre · tecnicatura · año)
│  ├─ Ficha del alumno: datos + inscripciones
│  ├─ Editar cualquier dato
│  └─ Asignar / resetear contraseña
├─ INSCRIPCIONES
│  ├─ Filtros: tecnicatura · año · condición · fecha
│  ├─ Corregir la condición de una materia (el alumno la eligió; ver D15)
│  └─ Anular inscripción (con motivo)
├─ MESAS (fecha y horario — una por materia)
│  ├─ Sincronizar con el sistema externo que asigna las fechas
│  ├─ Ver estado: importada ✅ / sin datos ⚠
│  └─ Cargar o FORZAR fecha y horario manual (si la sync falla)
├─ PERMISOS
│  ├─ Completar LIBRO y FOLIO de cada fila
│  └─ Regenerar / reenviar / ver PDF emitidos
└─ USUARIOS
   ├─ Dar de baja alumno
   └─ Cambiar contraseña de admin
```

---

## 4. Modelo de datos

> Nombres de tablas y campos en inglés (son código). Contenidos en español.

```
degrees                      (catálogo fijo: 2 filas)
  id, name

students
  id, user_id → users, degree_id → degrees,   -- "sector" = la tecnicatura (§4)
  dni (ÚNICO), first_name, last_name,
  phone, address, email (ÚNICO), email_verified_at,
  status (activo | baja), created_at, updated_at

users
  id, username (ÚNICO), password_hash, role (alumno | admin),
  status, must_change_password, last_login_at, created_at

subjects                     (catálogo: 153 materias, ver §6)
  id, degree_id → degrees, year (1..6), name

mesas                        (UNA sola mesa por materia — sin turnos)
  id, subject_id → subjects (ÚNICO), date, time (hora de inicio, "08:00"), location,
  date_source (externa | manual), external_ref, last_synced_at,
       -- La materia define su día y horario: UNA sola mesa por materia (D14).
       -- La FECHA/HORARIO lo asigna un sistema externo; la app lo toma de ahí (RB-17).
       -- Si la app no recibe los datos, el admin lo carga/fuerza a mano.
  registration_opens_at, registration_closes_at, status (abierta | cerrada)
  -- UNIQUE(subject_id): no existen dos mesas para la misma materia.

enrollments                  (inscripción a materia)
  id, student_id → students, subject_id → subjects, mesa_id → mesas (obligatoria),
       -- como hay UNA mesa por materia, mesa_id se deduce de subject_id: el alumno
       -- elige la MATERIA, no la mesa. Se guarda igual para no romper trazabilidad.
  condition,                      -- UNA por materia: la elige el ALUMNO al inscribirse
                                   -- (enum de 4, por defecto regular) → D15; el solo la
                                   -- corrige desde el panel admin (§2)
  status (pendiente | confirmada | anulada),
  requested_at, confirmed_at, confirmed_by → users, notes
  -- Las materias se AGRUPAN por condición al generar el permiso: un grupo = un
  -- permiso; si hay mezcla salen DOS permisos (RB-18). Ver permits.condition.

permits                      (Permiso de Examen, PDF — UNA copia por hoja)
  id, student_id → students, year,
  condition,                      -- condición del GRUPO (snapshot del impreso): todas
                                   -- las materias DE ESTE permiso la comparten porque
                                   -- nacieron agrupadas (RB-18). enum (4):
                                   -- regular | previa | completar_estudio | equivalencia
  title_text,                     -- "PERMISO DE EXAMEN - Alumno <Condición>" (dinámico, RB-18)
  libro, folio,                    -- los carga la escuela
  generated_at, generated_by → users
       -- El PDF NO se guarda en la BD: se genera bajo demanda y se DESCARGA
       -- DIRECTO AL CELULAR del alumno (RB-09, decisión 2026-09-29).

permit_enrollments            (qué materias lleva cada permiso)
  permit_id → permits, enrollment_id → enrollments
       -- PK compuesta (permit_id, enrollment_id); SIN id propio ni timestamps:
       -- en una junction o existe la fila o no (convención junction de analisis.txt 1.9)
       -- Reemplaza al arreglo de ids de la versión anterior, que no era una FK real.

password_resets                (código de recuperación y de verificación de correo)
  id, user_id → users, token (hash del código de 6 dígitos),
  purpose (reset_password | verify_email), sent_to (correo destino),
  attempts (int, máx. 5), expires_at (15 min), used_at,
       -- Un solo registro activo por usuario+purpose: reenviar invalida el anterior.
       -- RB-07 / RB-19: un solo uso, expira, 5 intentos → bloqueo 15 min.

audit_log                    (trazabilidad)
  id, actor_user_id, action, entity, entity_id, before, after, created_at
```

---

## 5. Reglas de negocio

| # | Regla |
|---|---|
| RB-01 | **Un solo registro por D.N.I.**: un D.N.I. = un alumno = una cuenta. No se puede crear un segundo registro con el mismo D.N.I. (constraint `UNIQUE` + validación en el formulario). |
| RB-02 | El alumno solo puede inscribirse en materias **de su propia tecnicatura**. |
| RB-03 | No se admite doble inscripción en la misma materia. Como cada materia tiene **una sola mesa**, no hay "cambiar de mesa": la inscripción se anula y se vuelve a hacer. |
| RB-04 | **La condición la pone el ALUMNO** al inscribirse: una por materia, nacida en `REGULAR`, con las 4 opciones del impreso. El admin solo puede **corregirla** (§2, D15). Las materias con la misma condición van en un mismo permiso; si hay condiciones distintas, se emiten **dos permisos** (RB-18). |
| RB-05 | Cambiar contraseña exige la **contraseña actual**. |
| RB-06 | Editar perfil exige **contraseña O código enviado al correo**. |
| RB-07 | Recuperar contraseña: solo mediante **correo verificado** (token con expiración, un solo uso). Si el correo no está verificado, no se envía el código. |
| RB-08 | El D.N.I., Nombre y Apellido **no los edita el alumno**: los corrige el admin. |
| RB-09 | El Permiso de Examen se genera al confirmar la inscripción y se **descarga directo al celular**; la BD **no guarda el archivo** (decisión 2026-09-29), solo conserva los datos de la emisión: año, condición, libro/folio, fecha y quién lo emitió. |
| RB-10 | Toda acción del admin queda registrada en `audit_log`. |
| RB-11 | Contraseñas guardadas **nunca** en texto plano (hash tipo bcrypt/argon2). |
| RB-12 | Solo se puede inscribir a materias cuya mesa esté dentro de la **ventana de inscripción** abierta (`registration_opens_at` … `registration_closes_at`). La ventana la fija el admin; por defecto se deriva de la fecha importada de la mesa. |
| RB-13 | **Máximo 6 asignaturas por Permiso de Examen** (el formulario A4 tiene 6 filas). Si un alumno necesita más, se emite un segundo permiso. |
| RB-14 | El PDF generado es un **borrador**: solo es válido con la **firma manuscrita del Secretario**. La app no lo firma. |
| RB-15 | **Libro, FOLIO, Calificación y Firma del Presidente de Mesa** no los carga ni el alumno ni la app en v1: son campos de la escuela sobre el impreso. |
| RB-16 | **Registro libre**: cualquiera puede darse de alta (no requiere aprobación del admin), pero **un D.N.I. = un alumno = una cuenta** (refuerzo de RB-01). |
| RB-17 | La **fecha y el horario de la mesa lo asigna un sistema externo** y la app lo importa. Si la app no recibe los datos, el admin puede **cargar / forzar fecha y horario manualmente** (`date_source = manual`). |
| RB-18 | El permiso se emite **una sola vez por conjunto de materias que compartan condición**; si hay condiciones distintas se generan **dos permisos**. El título del formulario es **dinámico**: *"PERMISO DE EXAMEN - Alumno \<Condición\>"*. |
| RB-19 | **Recuperar acceso por D.N.I. + correo**: el alumno ingresa su D.N.I. y su correo; ambos deben coincidir con la ficha. Se envía un código de 6 dígitos al correo (expira en 15 min, un solo uso, máximo 5 intentos). El error es **genérico** exista o no la cuenta, para no revelar qué D.N.I. está registrado. |

---

## 6. Catálogo de materias

| Tecnicatura | 1° | 2° | 3° | 4° | 5° | 6° | Total |
|---|--:|--:|--:|--:|--:|--:|--:|
| Tecnología de los Alimentos | 13 | 13 | 14 | 13 | 12 | 10 | **75** |
| Gestión Organizacional | 14 | 14 | 14 | 14 | 15 | 7 | **78** |
| | | | | | | | **153** |

⚠ **A revisar con la escuela:**
- 6° año de Gestión Organizacional tiene solo 7 materias frente a 14–15 de los demás
  años. ¿Faltan materias en el listado?
- El listado original tiene errores de tipeo que conviene corregir antes de cargarlo
  como datos semilla: *"Extrajera"*, *"Infromacion"*, *"Termdinamica"*, *"Sisitema"*,
  *"Equilavencia"*, *"Microbiogia"*, *"conversacion Frutihorticola"*, etc.

---

## 7. Permiso de Examen (PDF)

> Extraído de `Permiso de examen alumno 2026 - A4 - nuevo modelo.pdf`.
>
> El modelo actual imprime **3 copias idénticas** por hoja.
> **Cambio pedido a la escuela:** el formulario debe entregar **UNA sola copia**.
> La app genera el PDF con una sola copia (D8), **en el mismo lugar y del mismo
> tamaño que la primera copia del modelo** (tercio superior, resto en blanco).
>
> **Hoja: 612 × 792 pt (Carta)** — es el `MediaBox` real del modelo, aunque el
> archivo se llame "A4". El layout nuevo **reproduce el modelo tal cual**:
> párrafo y condición a la izquierda, tabla a la derecha (D12).

### 7.1 Encabezado
- Título **dinámico**: `PERMISO DE EXAMEN - Alumno <Condición>`
  (ej.: *…Alumno Regular*, *…Alumno con Previas*, *…Alumno con Completar Estudios*,
  *…Alumno con Equivalencias*) — RB-18
- Sello/logo: CONSEJO GENERAL DE EDUCACIÓN
- `APELLIDO Y NOMBRE` · `DNI` · `E.P.E.T. N° 36`
- **Condición:** `REGULAR` · `PREVIAS` · `COMPLETAR ESTUDIO` · `EQUIVALENCIA`  ← Q6 resuelta (4)
  - El modelo separa cada opción con una **casilla hueca** (glifo Wingdings, no la
    letra "o"). El PDF generado dibuja esa misma casilla y **marca en negro la
    casilla de la condición vigente**; las otras quedan huecas.
  - La etiqueta impresa es `PREVIAS` (plural) para coincidir con el modelo; el
    valor en la BD sigue siendo `previa`.
- *"Conste por la presente que el/la alumno/a está habilitado para rendir las asignaturas
  correspondientes a: ______ año de __________________, que se indican a continuación,
  evaluados en las fechas indicadas."* → **año + tecnicatura**
- Fecha de emisión: `______ de ______________ de 2026`

### 7.2 Tabla de materias — 6 filas
| N° | LIBRO | FOLIO | ASIGNATURA | FECHA | Calificación | Firma Presidente Mesa Exam. |
|--:|---|---|---|---|---|---|
| 1–6 | | | | | | |

> **Layout:** el formulario se usa **tal cual** (D5): párrafo a la izquierda,
> tabla a la derecha, misma tira angosta. La propuesta de poner el párrafo
> arriba y la tabla a todo el ancho fue **vetada por el usuario**.

### 7.3 Pie
- `Firma manuscrita del Secretario ______________________`
- Nota: *"Para poder rendir examen el alumno deberá presentar ante la comisión evaluadora
  este permiso (completo y firmado por el secretario) y su documento de identidad."*

### 7.4 ¿Qué llena cada quien?

| Campo | Quién lo llena |
|---|---|
| APELLIDO Y NOMBRE, D.N.I., año, tecnicatura | automático desde la ficha del alumno |
| ASIGNATURA, FECHA (de la mesa) | automático desde la inscripción |
| Condición | elegida por el ALUMNO al inscribirse (D15); se imprime desde `permits.condition` |
| N° LIBRO, FOLIO | el admin (la escuela) |
| Calificación, Firma del Presidente de Mesa | se completa el día del examen, a mano |
| Firma del Secretario | la escuela, **a mano** |

✅ **Q6 resuelta:** se usa el enum de **4 condiciones** —
`REGULAR · PREVIA · COMPLETAR ESTUDIO · EQUIVALENCIA` (D7).

### 7.5 Implementación: plantilla + purga de texto

`tools/generar_permiso.py` no redibuja el formulario: **usa el PDF de la
escuela como plantilla** y le hace dos cambios mínimos, ambos del mismo tipo
(se apaga un texto y se escribe otro encima):

1. **Purga de stream** (`_vaciar_texto`): los bloques `BT..ET` que hay que
   reescribir quedan **sin glifos** (`[] TJ` / `() Tj`), conservando `Tm`, `Tf`,
   `Tc`, `Tr`, `g` y `Q`. El texto viejo no queda oculto bajo un rectángulo
   blanco: **desaparece del stream** (no se puede recuperar seleccionándolo ni
   imprimiéndolo). Se vacían:
   - todo lo que está por debajo de `y = 522` (las copias 2 y 3 enteras);
   - el título (`y 745–753`);
   - las opciones de condición (`y 679–712`, `x < 265`), **menos** el rótulo
     `Condición` (`y 697–698`, `x < 47`), que se conserva byte a byte con su
     subrayado;
   - las líneas 3 y 4 del párrafo (las que llevan el año y la tecnicatura);
   - la línea de fecha de emisión.
2. **Overlay** (reportlab) con los valores rellenables: título dinámico,
   nombre, DNI, las 4 opciones de condición con su casilla, año, tecnicatura,
   fecha de emisión y las celdas `ASIGNATURA` / `FECHA` (vacías en la plantilla).

El único blanco pintado (`BLANQUEOS`) son **2 rectángulos** que tapan el
trazado vectorial de las copias 2 y 3 — hasta `y = 520.4` para no dañar el
borde inferior de la copia 1. Logo, encabezados, párrafo (líneas 1, 2 y 5),
nota, firma y todo el trazado son **bytes originales de la plantilla**.

Verificación hecha:
- pypdf: 1 página, `MediaBox 612×792`, **0 textos con `y < 522`**, sin
  fantasmas (`REVINCULACIÓN`, `EQUIVALENCIAS`, guiones, `año de` originales
  ausentes), cada valor rellenado aparece 1 sola vez, 16/16 textos estáticos
  idénticos (posición y cuerpo) a la copia 1 original.
- Píxeles (pypdfium2 @300dpi): las diferencias de la copia 1 están todas
  explicadas (campos rellenados + recortes de las copias 2/3); fila de firma
  y borde superior: **0 píxeles distintos**.
- Validaciones: `condicion` inválida, >6 materias (RB-13), alumno/DNI/carrera
  vacíos y plantilla inexistente lanzan excepción con mensaje claro.

---

## 8. Seguridad

- Hash de contraseñas + políticas de longitud.
- Correo como factor de identidad: código de un solo uso con expiración.
- Autorización por **rol en el servidor**, no escondiendo botones en la UI.
- Registro de admin inicial `admin/admin` con cambio obligatorio en el primer ingreso.
- Sesión con expiración; cierre automático por inactividad.

---

## 9. Preguntas abiertas

✅ **Sin preguntas abiertas** — Q4, Q5, Q6 y Q8 quedaron resueltas (§10, D7–D11).

**Pendientes:**

| Ítem | Estado |
|---|---|
| Formulario impreso: 1 copia + título dinámico + 4 condiciones | ✅ **HECHO** — `tools/generar_permiso.py` genera el PDF sobre la plantilla original (§7.5). Muestra: `docs/muestras/permiso-muestra.pdf`. Falta que la escuela adopte el diseño. |
| Sistema externo que asigna las fechas de las mesas | ⏸ **Pospuesto** por el usuario (ítem 2). |
| 6° año de Gestión Organizacional (¿faltan materias?) | ✅ **CERRADO** — el usuario confirmó que las materias están bien: 7 materias. |
| Tipeos del catálogo de 153 materias | ✅ **HECHO** — `data/materias.csv` (153 filas) + `docs/correcciones-materias.md` con cada cambio para revisión. |

---

## 10. Decisiones tomadas

| # | Decisión | Fecha |
|---|---|---|
| D1 | La **inscripción la hace el alumno solo**; el admin supervisa y corrige. | 2026-09-28 |
| D2 | La inscripción es por **materia con su mesa (fecha y horario)**, no solo por nombre de materia. | 2026-09-28 |
| D14 | **Cada materia tiene UNA sola mesa** (día y horario fijos); **no hay turnos** (mañana/tarde) ni elección de mesa entre varias: el alumno elige materias, la mesa la define la materia. | 2026-09-28 |
| D3 | **"Sector" = tecnicatura**: no es un campo aparte, se deriva de `students.degree_id`. | 2026-09-28 |
| D4 | **Un solo registro por D.N.I.** — endurecido en RB-01. | 2026-09-28 |
| D5 | El PDF reproduce el **formulario A4 real de la escuela** (cantidad de copias: ver D8). | 2026-09-28 |
| D6 | **Una condición por permiso** (una sola línea en el impreso): las materias elegidas se agrupan por condición y cada grupo genera su permiso; si hay mezcla, se emiten dos permisos. Revisada por D15 (quién la asigna). | 2026-09-28 |
| D7 | Se usan **4 condiciones**: `REGULAR · PREVIA · COMPLETAR ESTUDIO · EQUIVALENCIA`. Se descarta la lista de 5 del formulario actual. | 2026-09-28 |
| D8 | El PDF se entrega con **UNA sola copia** por hoja (el modelo actual imprime 3). | 2026-09-28 |
| D9 | El **título del permiso es dinámico** según la condición: deja de ser fijo *"Alumno Regular"*. | 2026-09-28 |
| D10 | **Registro libre** para completar la BD, sin aprobación del admin; la unicidad la garantiza el **D.N.I.** | 2026-09-28 |
| D11 | Las **fechas de las mesas las asigna un sistema externo**; la app las importa y, si falla la sincronización, el admin **fuerza la fecha a mano**. | 2026-09-28 |
| D12 | El layout del permiso **reproduce el modelo real**: párrafo a la izquierda, tabla a la derecha (se vetó la variante "párrafo arriba, tabla a todo el ancho"). | 2026-09-28 |
| D13 | El PDF usa la **plantilla original de la escuela como base** (no se redibuja); solo se vacía el texto a reescribir y se pinta un overlay encima (§7.5). | 2026-09-28 |
| D15 | **La condición la elige el ALUMNO** al inscribirse: una por materia, por defecto `REGULAR`; vive en `enrollments.condition` y el admin solo puede corregirla. Reemplaza lo que D6 y RB-04 decían sobre el admin. | 2026-09-29 |
