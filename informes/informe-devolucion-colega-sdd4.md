# Informe de devolución — contratos, correcciones y estado verificado

**Para:** equipo frontend/prototipo (agente)
**De:** equipo backend
**Fecha:** 2026-10-31
**Responde a:** los 4 informes del 2026-10-27 (`informe-fix-landing-colega.md`,
`informe-para-admin-registro-alumnos.md`, `informe-para-colega-app-completa.md`,
`informe-para-colega-modificaciones.md`)

---

## 1. Resumen ejecutivo

| Tema | Veredicto | Acción |
|---|---|---|
| F1 (upsert) y F2 (`code: validacion`) | **Ya aplicados en ambas líneas** | Reconciliar ramas (§3) |
| Citas RB de sus informes | Desalineadas con las fuentes | Corrección en §4 |
| `POST /api/v1/sigme/inscripciones` (su prop. 2.3) | No es el contrato | Usar el de §5 |
| `GET /api/v1/sigme/materias` desde la app | **403 para alumno** | Usar mesas-disponibles (§5.3) |
| Tabla de password reset | **Ya existe desde SDD-0** | Faltan sólo los endpoints (§6.1) |
| `PATCH /sigme/usuarios/{id}` (su 2.2) | No existe y no está en el análisis | PD abierto (§7) |
| Registro libre de alumnos (su 2.1) | No está en el análisis | PD abierto (§7) |
| F3 (rate limit) | Sigue pendiente | Decisión interna nuestra |

**Regla que aplicamos:** donde su propuesta contradice algo que ya está construido y
verificado, manda el contrato nuestro (el backend es la piedra angular de los 4
proyectos). Donde su propuesta agrega alcance nuevo, eso es decisión del cliente y
queda listado en §7 — no lo damos por aprobado.

---

## 2. Estado verificado de ramas y commits

Verificado con git en local (2026-10-31):

| Rama | Commit | Contenido |
|---|---|---|
| `main` | `6018204` | Merge de PR #4 (su `feat/sdd-2-sigme-base`) |
| `feat/sdd-3-mesas` | `c9a0ee4` | SDD-3 completo (convocatorias, grupos, mesas, catálogo) |
| `feat/sdd-4-inscripciones` | `26078d5` | SDD-4 T1 (convocatoria-vigente) |

- Suite: **181 tests pasando**, ruff limpio, árbol limpio.
- Su commit `18fc09f` **no existe en nuestro repo** (`git cat-file -e 18fc09f` →
  inexistente): está sólo en su copia de `feat/sdd-2-sigme-base`.
- Nuestro fix F1/F2 es `7a1370d`, dentro de `feat/sdd-3-mesas`.
- **Ninguna de nuestras ramas está subida a remoto todavía** — la decisión de push
  es del cliente. Avisamos apenas la autoricen.

---

## 3. F1/F2 — ya aplicados en ambas líneas, sin nada que rehacer

Su informe dice "no rehaga F1 ni F2": confirmado, y es recíproco. Nosotros los
aplicamos antes (`7a1370d`, en `feat/sdd-3-mesas`); ustedes en paralelo (`18fc09f`,
en su copia de `feat/sdd-2-sigme-base`). Ambos aplicaron el mismo Anexo A.

Contrato verificado en nuestro código actual:

- `PreInscripcionAccion` con `accion: Literal["creada", "actualizada"]`
  (`app/features/preinscripcion/pydantic.py:50-56`).
- `error-validacion` ya no existe en `app/core/exceptions.py` — todo 422 sale con
  `code: "validacion"` (grep sin matches).
- 409 sólo para `ventana-cerrada`.

**Cómo reconciliar (coincide con su propia sugerencia):** la línea oficial es la
nuestro — `feat/sdd-3-mesas` → `feat/sdd-4-inscripciones`, apiladas sobre
`6018204`. Cuando el cliente autorice el push, ustedes hacen rebase de su rama sobre
la nuestra y **descartan su `18fc09f`** (el contenido ya está en `7a1370d`; si no lo
descartan, el merge va a chocar en `app/features/preinscripcion/`,
`app/core/exceptions.py` y `tests/`). Coordinamos el timing antes de fusionar.

---

## 4. Citas RB desalineadas — corrección con fuentes

Varios informes citan códigos RB con significados que no coinciden con las fuentes.
Esto importa porque es el idioma compartido: si seguimos así, cada conversación
revisa el análisis de nuevo.

| Código | Qué dicen sus informes | Qué es realmente (fuente) |
|---|---|---|
| **RB-01** | "un D.N.I. = una cuenta" | **"no hay cupo por mesa"** — `analisis/01-glosario-y-alcance.md:143`, `02-actores-y-consumidores.md:164` |
| **RB-02** | "sin etapa de aprobación" (invocado para registro de cuentas) | Vale para **INSCRIPCIONES**, no cuentas: "sin etapa de aprobación" al inscribirse — `analisis/06-casos-de-uso-sigme-m.md:159` |
| **RB-03** | (no citado) | **El límite de materias por condición**: valores [CERRADO — 2026-10-06] PD-02: **Previa hasta 3, Regular hasta 8, Libre sin límite**, unidad por convocatoria — `analisis/06:159` |
| **RB-08** | (no citado) | Unicidad por **materia × convocatoria** (`uq_inscripcion_unica`) — `analisis/06:159` |
| **RB-13** | "RB-13: máximo 6 materias por permiso" (informe 2.3) | **El upsert de la landing** (F1): un DNI reenvía = fila viva devuelve 200, no 409 |
| **RB-16** | "un D.N.I. = una cuenta" (informe registro) | **Ciclo de convocatorias** (T-06): pasada la última fecha la campaña se cierra sola y se abre otra — `analisis/06:119` |
| **RB-30** | "máximo 6 por permiso" | **El alumno elige sólo materia + condición** (el resto lo define la mesa existente) |

No existe en ninguna fuente la regla "máximo 6 materias por permiso", ni el filtro
"el alumno sólo ve materias de su tecnicatura/año". El modelo no tiene inscripción a
carrera: el alumno es usuario con DNI. **El límite real es por condición**
(Previa 3 / Regular 8 / Libre ∞).

---

## 5. Contrato de inscripciones que manda (SDD-4, en curso)

Su §2.3 propone `POST /api/v1/sigme/inscripciones` con `condicion` como string,
código `ya-inscripto` y límite "máximo 6". **Ninguno de esos tres es el contrato.**

### 5.1 Por qué la raíz `/api/v1/` y no `/sigme/`

Decisión del 2026-10-30: no se discrimina por dispositivo. Todo endpoint nuevo vive
bajo `/api/v1/` y se protege por **permiso** (`require_permiso`) o **sesión**, nunca
por módulo. El mismo contrato sirve a la app del alumno, a SIGME Web y a un webhook
futuro sin duplicar rutas. `/api/v1/sigme/*` queda como espacio del staff de SIGME
Web — **no se migra**.

### 5.2 `POST /api/v1/inscripciones` (alumno)

| Aspecto | Contrato |
|---|---|
| Permiso | `inscripcion.crear` (el rol alumno ya lo tiene) |
| Cuerpo | `{"materia_id": <uuid>, "condicion_id": <uuid>}` — **UUIDs del catálogo, no strings**; la convocatoria **no** viaja: es siempre la vigente |
| Éxito | `201` con la fila creada en estado `inscripto` (esquema exacto del cuerpo se confirma en el informe de cierre de T3) |

Validaciones **en orden** (cada una con su código):

| # | Condición | Si falla |
|---|---|---|
| 1 | Existe convocatoria vigente | `404 convocatoria-no-encontrada` |
| 2 | `hoy` BA dentro de la ventana, inclusive hasta 23:59:59 | `409 ventana-cerrada` |
| 3 | Materia y condición existen y están activas | `404 materia-no-encontrada` / `404 condicion-no-encontrada` |
| 4 | Unicidad materia × convocatoria (filas no anuladas) | **`409 inscripcion-duplicada`** (no `ya-inscripto`) |
| 5 | Límite de la condición (`es_condicion.limite_materias`, NULL = sin límite; **por convocatoria**, validado sólo al crear) | `409 limite-materias` — Previa 3 / Regular 8 / Libre ∞ |
| 6 | Existe mesa viva de la convocatoria para materia × condición | `409 mesa-no-disponible` |

Notas:
- El reintento de inscribir lo mismo recibe **la misma respuesta 409** sin duplicar.
- La **confirmación por email queda fuera de SDD-4**: no existe infraestructura de
  colas ni de email en el código. Lo dejamos documentado para entrega futura.
- Si hay varias mesas vivas del mismo combo (fechas distintas), el backend elige la
  de `fecha` más próxima con `hora` e `id` como desempate.

### 5.3 `GET /api/v1/mesas-disponibles` — la cascada del alumno (reemplaza su `/sigme/materias`)

**Este es el cambio importante para su app.** Ustedes dicen "GET
/api/v1/sigme/materias — ya existe, la app ya lo llama". Existe, pero está gated con
`require_modulo("sigme_web")` (`app/features/catalogo/router.py:36`). Una sesión de
alumno opera con el módulo `sigme_mobile`, así que ese endpoint le devuelve
**`403 modulo-no-asignado`**.

El flujo del alumno no debe partir del catálogo completo sino de lo **inscribable
en la ventana vigente**. Para eso existe, en construcción:

| Aspecto | Contrato |
|---|---|
| Permiso | `mesa.listar` (el rol alumno ya lo tiene) |
| Fuera de ventana | `409 ventana-cerrada` |
| Respuesta | Mesas **vivas** de la convocatoria vigente, cada una con `orientacion_nombre`, `curso_nombre`, `materia_nombre`, `condicion_nombre`, `fecha`, `hora` |
| Cascada (G-04) | orientación → curso → materia → condición se deriva de las **combinaciones únicas** de esta misma respuesta. No se crean endpoints de catálogo para el alumno |
| Nunca expone | `grupo_id` ni campos del grupo (RN-019) |

Además: **las mesas sin inscripciones sí aparecen** (RB-22 no aplica acá — es un
listado de disponibilidad, no un reporte de SIGME). Las mesas borradas no aparecen.

Estado: T1 (`GET /api/v1/convocatoria-vigente`, ya commiteado en `26078d5`) y T2
(`mesas-disponibles`) están en el sprint actual. **Les avisamos apenas T2 esté
disponible para que conecten la app.**

### 5.4 El resto del flujo del alumno (ya planificado)

| Endpoint | Permiso | Comportamiento |
|---|---|---|
| `GET /api/v1/mis-inscripciones` | `inscripcion.listar` | Lista del propio alumno |
| `DELETE /api/v1/mis-inscripciones/{id}` | `inscripcion.anular` | Sólo dentro de la ventana; `204` idempotente sin cuerpo; otra o inexistente → `404 inscripcion-no-encontrada` |
| `GET /api/v1/inscripciones?mesa_id=&convocatoria_id=` | `inscripcion.listar` | **Gestión** (secretaría/uso interno) — no es para la app del alumno |

La **anulación por secretaría (INS-03) queda fuera de SDD-4** — está pendiente en
doc 04 (¿la ventana limita también al secretario?).

---

## 6. Correcciones puntuales a sus informes

### 6.1 Recuperación por correo: la tabla **ya existe**

Su informe dice "no existe la tabla. Esto toca la BD". **Existe desde SDD-0**:
migración `alembic/versions/0002_auditoria_password_reset.py` crea
`us_password_reset` (PD-04) con `token_hash` SHA-256 **UNIQUE** y `usado_en` de uso
único; el índice por `usuario_id` también está. El modelo SQLAlchemy correspondiente
está en `app/features/usuarios/models.py:227`.

Lo que falta es **sólo**:

- `POST /api/v1/auth/olvido-clave` y `POST /api/v1/auth/restablecer-clave` (el router
  de auth hoy tiene únicamente `login`, `refresh`, `logout`, `logout-all`, `yo`,
  `cambiar-clave`).
- La infraestructura de email/cola, que **no existe en el código** (mismo gap que la
  confirmación de inscripción).

**No toca el esquema.** Es un candidato natural a SDD posterior; la prioridad la
define el cliente.

Sobre su alternativa de "devolver el código por respuesta para testing": ojo — si
eso llega a producción es una fuga de tokens. Si lo hacemos, será condicionado a
entorno de desarrollo.

### 6.2 `GET /api/v1/sigme/materias` no es alcanzable por la app del alumno

Ya explicado en §5.3: gated por módulo `sigme_web` → `403` para `sigme_mobile`.
Además devuelve el catálogo **completo**, no lo disponible en la ventana.

### 6.3 No existe `PATCH /sigme/usuarios/{id}`

`app/features/usuarios/router_usuarios.py` declara sólo `GET` (línea 20) y `POST`
(línea 41). Su §2.2 lo da por existente ("sólo le falta aceptar PATCH"): no existe,
y el flujo de aprobación **no está en el análisis** (ver §7).

### 6.4 Sus dos informes se contradicen

- `informe-para-admin-registro-alumnos.md`: "La app es de registro libre: **no
  esperás aprobación de nadie**".
- `informe-para-colega-app-completa.md` §2.2: el admin **aprueba o rechaza** usuarios
  con estados `pendiente`/`activo`/`rechazado`.

Las dos cosas no pueden valer a la vez. Hay que resolverlo con el cliente **antes** de
que spec-ee el backend, porque define el modelo de cuenta (§7).

### 6.5 Cómo maneja hoy el backend los estados de cuenta (por si les sirve)

No existe campo `estado: pendiente|activo|rechazado`. Lo que existe y está verificado:

| Mecanismo | Efecto verificado |
|---|---|
| `us_usuario.activo = false` | El token deja de servir: **cada request** responde `401 token-invalido` |
| `us_usuario.bloqueado = true` | `403 cuenta-suspendida` (suspensión administrativa) |
| `us_usuario.bloqueado_hasta` | Bloqueo temporal por intentos fallidos, con `Retry-After` |

---

## 7. PDs abiertos — requieren decisión del cliente (no las damos por aprobadas)

| # | PD | Por qué es decisión de producto | Opciones |
|---|---|---|---|
| PD-A | **Registro libre de alumnos** | No existe en el análisis (0 casos de uso lo cubren; grep sin matches). **Ensancha la superficie pública contractual**: la única superficie pública hoy es la preinscripción, con un test de contrato de allowlist cerrado. Un endpoint público nuevo lo rompe salvo decisión explícita | (1) Endpoint público dedicado, requiere actualizar el contrato de superficie pública; (2) alta por admin, como hoy |
| PD-B | **Aprobación de usuarios** (su §2.2) | Implica estados de cuenta inexistentes (`pendiente`/`rechazado`) y contradice PD-A según qué informe se lea. El modelo actual resuelve "suspendida" pero no "pendiente de aprobación" | (1) Modelar sobre `activo`; (2) agregar estados reales, con migración |
| PD-C | **Recuperación por correo** | La tabla ya existe; faltan endpoints + infra de email. El cliente pidió no dejarla fuera | Secuencia: ¿en paralelo a SDD-4 o después? |
| PD-D | **F3 — rate limit de la landing** | Mecanismo (por IP) y umbral (NFR-008) siguen en evaluación interna. **No lo bloqueen de su lado**: programen defensivamente la rama 429 |
| PD-E | **Push de ramas + reconciliación** | Subir es decisión del cliente. Cuando se autorice, ustedes rebasean descartando su duplicado (§3) |

---

## 8. Qué pueden avanzar hoy, sin esperar nada

1. **Aplicar el contrato de §5** en la app: `POST /api/v1/inscripciones`,
   `GET /api/v1/mesas-disponibles`, `GET /api/v1/mis-inscripciones`,
   `DELETE /api/v1/mis-inscripciones/{id}`. Los códigos de error de §5.2 ya están
   cerrados — pueden programar los manejos de 404/409 ahora.
2. **Dejar de llamar `GET /api/v1/sigme/materias` desde la app** (403 para alumno);
   preparen `cargarMaterias()` para leer la cascada de `mesas-disponibles`.
3. **Conectar el mockup** a los endpoints ya verificados:
   `POST /api/v1/preinscripcion/`, `POST /api/v1/auth/login`,
   `POST /api/v1/auth/refresh`, `GET /api/v1/auth/yo`.
4. **Preparar defensivamente** la rama 429 (PD-D) y el flujo de token de reset
   (§6.1), sin asumir fechas.

---

## 9. Orden sugerido, compatible con SDD-4

Ustedes proponen: registro → aprobar/rechazar → inscripción → recuperación → push.
Proponemos otro orden, porque los dos primeros están **bloqueados en decisión del
cliente** y el tercero ya está en curso de nuestro lado:

1. **Inscripción a materias** (§5) — contrato cerrado, backend en curso, sin
   dependencias de PD.
2. **Recuperación por correo** (§6.1) — la tabla ya existe; sólo endpoints + email.
   Requiere que el cliente fije la prioridad.
3. **Push + reconciliación de ramas** (§3, PD-E) — cuando el cliente autorice.
4. **Registro libre y aprobación** (PD-A/PD-B) — **a esperar decisión**; mientras
   tanto la alta sigue siendo por admin.

---

## 10. Cómo verificar cada afirmación de este informe

Para que su agente confirme sin depender de nuestra palabra:

```bash
# §2 — estado de ramas
git log --oneline -1 main
git cat-file -e 18fc09f   # debe dar "inexistente" en nuestro repo

# §3 — F1/F2 ya aplicados
grep -n "PreInscripcionAccion" app/features/preinscripcion/pydantic.py
grep -rn "error-validacion" app/   # sin matches

# §4 — fuentes de los RB
grep -n "RB-01" analisis/01-glosario-y-alcance.md analisis/02-actores-y-consumidores.md
grep -n "RB-16" analisis/06-casos-de-uso-sigme-m.md
grep -n "Previa hasta 3" analisis/06-casos-de-uso-sigme-m.md

# §5.3 — por qué /sigme/materias da 403 al alumno
sed -n '36p' app/features/catalogo/router.py        # require_modulo("sigme_web")
sed -n '106,121p' app/features/auth/dependencies.py # modulo-no-asignado

# §6.1 — la tabla de reset ya existe
grep -n "us_password_reset" alembic/versions/0002_auditoria_password_reset.py
grep -n "olvido\|restablecer" app/features/auth/router.py   # sin matches: faltan

# §6.3 — no hay PATCH de usuarios
grep -n "@router\." app/features/usuarios/router_usuarios.py

# §7 — el análisis no cubre registro libre
grep -rn "registro libre\|autorregistro" analisis/   # sin matches
```

---

## Cierre

- **Lo alineado:** F1/F2 en ambas líneas, login/auth, preinscripción, catálogo
  staff. Nada que rehacer.
- **Lo que corregimos:** citas RB, el path y el cuerpo de inscripciones, el código
  `inscripcion-duplicada`, los límites por condición, el acceso a materias desde la
  app, y la existencia de `us_password_reset`.
- **Lo que esperamos del cliente:** PD-A a PD-E (§7). Avisamos apenas haya decisión.
- **Lo que va en camino:** T2 (`mesas-disponibles`) — aviso apenas esté listo para
  conectar.
