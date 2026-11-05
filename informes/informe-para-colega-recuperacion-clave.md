# Informe para el colega — Recuperación de clave (pedido de blanqueo) + fixes de migraciones

**Para:** colega (backend + app de escritorio)
**De:** equipo frontend / prototipo
**Fecha:** 2026-11-05
**Responde a:** su §6.1 y PD-C de `informe-devolucion-colega-sdd4.md` (2026-10-31)

---

## 1. Resumen ejecutivo

| Tema | Estado | Acción de ustedes |
|---|---|---|
| Bugs en `0003` y `0004` (sus migraciones) | **Arreglados y commiteados** (`852c57e`, push pendiente) | Aplicar los fixes antes de correr en una BD fresca (§5) |
| PD-C "recuperación por correo" | **Cerrado por decisión del cliente**: no se hace por email | Leer §2 — cambia lo que ustedes iban a construir |
| `POST /api/v1/auth/olvido-clave` | **Implementado, testeado y commiteado** (`48e1b72`, push pendiente) | Revisar y aprobar el contrato (§3) |
| Vista de pedidos + blanqueo | **Es su parte** (app de escritorio) | §4 — SQL exacto, sin integración nueva si comparten la BD |
| `/auth/restablecer-clave` | **No se hace** | Reemplazada por `cambiar-clave`, que ya existe |
| `PATCH /sigme/usuarios/{id}` (su §6.3) | **No hace falta para este flujo** | El blanqueo lo escribe el escritorio directo en la BD |

**Commiteado en local, sin push todavía**: los fixes (`852c57e`) y el endpoint (`48e1b72`) están en `feat/sdd-4-inscripciones`, rebased sobre su punta `d3beed0` (SDD-5), suite **277 passed** ✅. En GitHub recién aparecerán cuando el cliente autorice el push — avisamos apenas pase.

---

## 2. Decisión de producto que reemplaza su §6.1 / PD-C

Textual del cliente (2026-11-04):

> "que sea el pedido automatico luego el admin lo blanquea"
> "nosostros solo hacemos el pedido"

Flujo acordado:

1. El alumno pide el blanqueo desde nuestra app → `POST /api/v1/auth/olvido-clave`.
2. **El administrador lo ve en la app de escritorio de ustedes** y blanquea la clave.
3. El alumno entra con la clave temporal y la cambia desde Perfil → `POST /api/v1/auth/cambiar-clave` (ya existe).

Consecuencias sobre lo que ustedes iban a hacer:

- **NO** se implementa `POST /api/v1/auth/restablecer-clave`.
- **NO** se necesita la infraestructura de email/cola para este flujo (el RB-19 de código por correo queda reemplazado en el prototipo).
- **Sí** se reutiliza la tabla `us_password_reset` (PD-04, su §6.1): pasa a funcionar como **registro de pedidos**. No toca esquema, no hay migración nueva.
- Sobre su advertencia de "devolver el código por respuesta para testing": no aplica — este flujo no tiene código ni token que filtrar.

---

## 3. Endpoint que implementamos (su revisión)

`POST /api/v1/auth/olvido-clave` — público, sin autenticación:

- **Request:** `{"identificador": "<username | email>"}` — coincide case-insensitive contra `us_usuario.username` o `us_usuario.email`.
- **Response:** `202` **siempre** con `{"status": "solicitado"}` — idéntica exista o no la cuenta (anti-enumeración, misma idea que su §6.1 de no filtrar detalles).
- **Efecto:** una fila en `us_password_reset` con:
  - `usado_en = NULL` (pendiente),
  - `expira_en = created_at + 24 h` (ventana para que el admin actúe — supuesto nuestro, ajustable),
  - `token_hash = marcador aleatorio hasheado` (SHA-256 de bytes aleatorios: este flujo **no emite tokens**; la columna es NOT NULL UNIQUE por contrato PD-04, por eso el marcador),
  - `ip` y `user_agent` del request.
- **Un solo pedido vigente por usuario** (no duplica filas).
- **Archivos** (rama `feat/sdd-4-inscripciones`, copia local): `app/features/auth/router.py`, `app/features/auth/schemas.py`, `app/features/auth/service.py`, `tests/unit/test_auth_endpoints.py`.
- **Verificación:** 5 tests nuevos (RED → GREEN), suite completa **277 passed** tras el rebase sobre su SDD-5, `ruff check` limpio.

---

## 4. Su parte — app de escritorio

### 4.1 A confirmar

Que la app de escritorio comparte **esta misma BD** (la que tiene `alembic_version = 0004`). Si es así no hay integración nueva que diseñar: solo lectura/escritura de tablas.

### 4.2 Ver los pedidos pendientes

```sql
SELECT r.id, u.username, r.created_at, r.expira_en, r.ip, r.user_agent
FROM us_password_reset r
JOIN us_usuario u ON u.id = r.usuario_id
WHERE r.usado_en IS NULL AND r.expira_en > now()
ORDER BY r.created_at;
```

### 4.3 Blanquear (al aprobar un pedido)

```sql
BEGIN;
UPDATE us_usuario
SET password_hash      = '<argon2id — mismo algoritmo que valida /auth/login>',
    password_changed_at = now(),
    intentos_fallidos   = 0,
    bloqueado           = false,
    bloqueado_hasta     = null,
    token_version       = token_version + 1  -- invalida todas las sesiones abiertas (§2.6)
WHERE id = '<usuario_id>';

UPDATE us_password_reset SET usado_en = now() WHERE id = '<pedido_id>';
COMMIT;
```

- La clave temporal respeta §2.5: **mínimo 12 caracteres**.
- `token_version + 1` es el mismo mecanismo que ya usan en bloqueo y login: mata todos los tokens vigentes.
- Si el pedido venció (`expira_en < now()`) el alumno puede pedir de nuevo: se crea una fila nueva; ustedes filtran con `expira_en > now()` (la query de §4.2 ya lo hace).

### 4.4 Después del blanqueo

El alumno ingresa con la temporal y la cambia por `POST /api/v1/auth/cambiar-clave` (`clave_actual` + `clave_nueva ≥ 12`) — eso también sube `token_version`. No hay nada que implementar de su lado para este paso.

---

## 5. Fixes de migraciones (obligatorios)

Sus migraciones nunca habían corrido en una máquina real; al correrlas encontramos 3 bugs (reproducidos y arreglados en nuestra copia):

| Migración | Bug encontrado | Fix aplicado |
|---|---|---|
| `0003_seed_roles_condiciones.py` | 3 `INSERT … ON CONFLICT` con **coma antes de `ON CONFLICT`** (error de sintaxis) y listas de **4 columnas declaradas vs 2 valores** | Comas removidas; columnas reducidas a `(codigo, descripcion)` y `(descripcion, limite_materias)` |
| `0004_dispositivos.py` | El enum `plataforma_dispositivo` se crea **dos veces**: `CREATE TYPE` explícito + `create_table` lo emite de nuevo → `type already exists` | `postgresql.ENUM(…, create_type=False)` en la definición de la columna |

Estado actual de la BD Neon: **`alembic_version = 0004` (head)** + semillas (roles/permisos/condiciones, catálogo de demo, convocatoria, 6 mesas).

⚠️ Si corren sus originales en una BD fresca, se rompen exactamente igual que se nos rompieron a nosotros.

---

## 6. Pendientes de decisión (GitHub)

1. **`main` sigue en el merge del PR #4 (SDD-2)** — verificado hoy con fetch: `feat/sdd-3-mesas` y `feat/sdd-4-inscripciones` están pushadas pero **sin PR**; `sdd-4` ya incluye a `sdd-3`.
2. **PR #5** (`feat/contrato-endpoints-publicos`): sigue pendiente de resolver (merge o cierre).
3. Los fixes de §5 y el endpoint de §3 están **commiteados en local** (`852c57e` y `48e1b72`, rebased sobre `d3beed0`) — no los van a ver en GitHub hasta que el cliente autorice el push.

---

## 7. Contrato opcional pendiente (no bloquea)

`GET /auth/yo` devuelve `id, username, roles, permisos, modulos` — **sin `nombre`/`apellido`**. El saludo de la app muestra el username (`alumno01`) en lugar del nombre del alumno. Agregar esos dos campos a `YoResponse` (leyendo `pe_persona` vía `us_usuario.persona_id`) es cambio de su contrato; lo dejamos listo de nuestro lado si lo aprobán. No recomendamos darle `persona.listar` al alumno para resolverlo: expondría todas las personas del colegio.

---

## 8. Qué NO hace falta (para que no hagan trabajo de más)

- `/auth/restablecer-clave` — reemplazada por `cambiar-clave` existente.
- Infra de email/cola para este flujo.
- `PATCH /sigme/usuarios/{id}` (su §6.3) — el blanqueo lo escribe el escritorio.
- Migraciones nuevas — cero cambios de esquema.
