# Informe para el colega — actualizaciones, conflicto de 0005 y reconciliación

**Para:** equipo backend (`feat/sdd-6-reset-email-pdf` / DiegoAle)
**De:** equipo backend (`feat/sdd-4-inscripciones`)
**Fecha:** 2026-11-12
**Motivo:** implementación paralela del flujo de recuperación de clave + cola de
email; hay **dos migraciones `0005` incompatibles** y dos variantes del mismo
feature. Hace falta reconciliar antes de merge a `main`.

---

## 1. Resumen ejecutivo

| Tema | Estado | Acción |
|---|---|---|
| Flujo de recuperación de clave | **Paralelo e incompatible** | Elegir implementación base (§3) |
| Migración `0005` | **Conflicto**: dos revisiones `0005` con esquemas distintos | Unificar en una (§2) |
| Cola de email (`ntf_envio`) | Uds: catálogo + worker stub · Nosotros: entrega SMTP real + purga de token | Fusionar esquema suyo + entrega nuestra (§4) |
| Rate limit `olvido-clave` (3/hora) | Uds: sí · Nosotros: **no** (gap nuestro) | Adoptar el suyo |
| Auditoría `password_reset_request` | Uds: sí · Nosotros: no | Adoptar el suyo |
| `POST /auth/restablecer-clave` + token real por correo | **Sólo nosotros** | Mantener (decisión 2026-11-12) |
| Anulación secretaría + templates PDF | **Sólo ustedes** (SDD-6 T3/T4) | Mantener; no lo tocamos |
| Informes obsoletos (nuestro repo) | Borrados: `recuperacion-clave`, `app-completa`, `modificaciones` | Queda este + `devolucion-colega-sdd4` + `INFORME-SISTEMA-COMPLETO` |

**Decisión de producto ya tomada (2026-11-12):** restauración **automática**
con verificación por correo. El usuario pide el token, lo recibe por email y
blanquea su propia clave. **No** interviene el admin. Eso exige que el token
real salga por el correo — un marcador en la BD no alcanza.

---

## 2. Conflicto: dos migraciones `0005`

Ambas ramas parten del merge-base `d3beed0` y crean **la misma revisión
alembic `0005`** con esquemas distintos. No pueden aplicarse ambas.

| | **Nuestra** `0005_ntf_envio.py` | **Suya** `0005_email_queue.py` |
|---|---|---|
| Tablas | sólo `ntf_envio` | `ntf_notificacion` + `ntf_envio` |
| `ntf_envio` | `destinatario`, `asunto`, `cuerpo`, `estado`, `reintentos`, `ultimo_error` | FK a catálogo, `intentos`/`max_intentos`, `proximo_reintento`, `enviado_en`, `payload_json`, índice de worker |
| Seed | no | catálogo RN-050 (5 email + 2 push) |
| Modelo SQLAlchemy | `app/features/notificaciones/models.py` (espejo simple) | equivalente más rico + `NtfNotificacion` |

**Recomendación:** tomar **su esquema** (catálogo + campos de reintento) y
adapatar **nuestra capa de servicio** encima (SMTP real + purga de `cuerpo` en
estado terminal). El seed RN-050 es valioso; el stub de worker se reemplaza
por el envío real que ya tenemos.

---

## 3. Flujo de recuperación: qué tiene cada lado

| Capa | Nosotros (`feat/sdd-4-inscripciones`, sin commitear al momento de escribir esto) | Ustedes (`feat/sdd-6-reset-email-pdf`, ya en el remoto) |
|---|---|---|
| `POST /auth/olvido-clave` | 202 siempre; genera `token_urlsafe(32)`, guarda SHA-256, devuelve correo a encolar | 202 siempre; **rate limit 3/h**; **auditoría** `password_reset_request`; `token_hash` = hash de bytes aleatorios (**marcador, no token real**); **no envía correo** |
| `POST /auth/restablecer-clave` | **Sí**: busca por hash, un solo uso, 24 h, sube `token_version`, `revoke_all_sessions`, limpia rate-limit de login | **No existe** (grep `restablecer` = 0 en su router) |
| Entrega del email | `BackgroundTasks` → `encolar_y_entregar` → SMTP real (`smtplib`), sesión propia, nunca lanza, purga `cuerpo` al llegar a `enviado`/`fallido` | `enqueue_email` + `process_email_queue` **stub** (marca `enviado` sin SMTP; `aiosmtplib` anotado, sin implementar) |
| Tests | 290 passed / ruff limpio (2026-11-12) | 298 passed en su informe |
| Exceso suyo que no tenemos | — | rate limit, auditoría, catálogo RN-050, anulación INS-03, templates PDF |

**Gap nuestro conocido:** no tenemos rate limit en `olvido-clave`. Con SMTP
configurado, un atacante puede forzar reenvíos y bomba de correos. En la
reconciliación hay que **adoptar el suyo** (3/hora por identificador).

**Gap suyo conocido:** sin `/restablecer-clave` el flujo no se puede cerrar:
el usuario nunca recibe un token utilizable ni puede blanquear solo.

---

## 4. Propuesta de reconciliación (orden sugerido)

1. **Base de código:** partir de **su rama** (`feat/sdd-6-reset-email-pdf`):
   esquema `0005` completo, anulación, PDFs, rate limit, auditoría.
2. **Traer encima nuestro flujo:**
   - `solicitar_recuperacion` con token real + correo en claro sólo en el email
   - `POST /auth/restablecer-clave` (o renombrar el suyo para que use el token
     real en lugar del marcador)
   - `encolar_y_entregar` (o adaptar `process_email_queue` a SMTP real con
     purga de `cuerpo` en estados terminales)
3. **Migración:** descartar **nuestra** `0005_ntf_envio.py`; renombrar/adaptar
   la suya si hace falta alinear columnas (`reintentos` vs `intentos`, etc.).
4. **Suite:** correr **ambas** (298 suyos + los nuestros de auth/notificaciones)
   sobre la rama unificada; ruff limpio.
5. **Neon:** `alembic upgrade head` **recién** después del merge — si alguien
   ya aplicó una de las dos `0005`, hay que inspeccionar `alembic_version` y
   posiblemente drop/recreate de `ntf_*` (no hay datos productivos todavía).

No hace falta que ustedes reescriban el flujo desde cero: el contrato de
endpoints ya está probado de nuestro lado; el de cola de ustedes es mejor
esquema. Es un merge de piezas, no una tercera implementación.

---

## 5. Qué queda de nuestro lado (repo raíz / frontend)

- `docs/prototipo/prototipo.html`: pantalla de recuperación actualizada a
  **2 pasos** (token del correo + clave nueva) contra
  `/auth/olvido-clave` y `/auth/restablecer-clave`.
- `docs/diseno.md` §3.1.1 + RB-19 + §4 (`us_password_reset`) alineados a la
  decisión 2026-11-12 (sin código de 6 dígitos).
- Informes borrados (obsoletos): `informe-para-colega-recuperacion-clave.md`,
  `informe-para-colega-app-completa.md`, `informe-para-colega-modificaciones.md`.
- Conservados: `informe-devolucion-colega-sdd4.md` (suyo), `INFORME-SISTEMA-COMPLETO.md`
  (snapshot histórico), este informe.

**Fuera de alcance de este informe (confirmar con ustedes):** F3 rate-limit
global de API, `GET /auth/yo` con `nombre`/`apellido`, reintento PD-04,
¿compartimos la misma BD Neon?

---

## 6. Estado git al momento de escribir (2026-11-12)

| Rama | Estado |
|---|---|
| `origin/feat/sdd-6-reset-email-pdf` | 8 commits sobre `d3beed0` (su SDD-6) |
| `feat/sdd-4-inscripciones` (nuestro local) | `852c57e` + `48e1b72` ahead de origin; **flujo completo de reset + cola en el working tree, por commitear/pushear** |
| `main` (ambos remotos) | sin esos cambios |

En cuanto commiteemos y pusheamos nuestra rama, el conflicto de `0005` será
visible para ambos en GitHub. Preferimos avisar **antes** del push si hay
preferencia por un orden distinto al de §4.

---

**Contacto:** responder por este informe o por issue en
`formulariosepetn36-ai/backend-epet-n36`. No fusionar a `main` sin cerrar §2–§4.
