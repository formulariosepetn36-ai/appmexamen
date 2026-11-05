# Informe para el colega — Backend necesario para activar la app

**Para:** colega (backend)  
**De:** equipo frontend / prototipo  
**Fecha:** 2026-10-27  
**Estado de la app:** `docs/prototipo/prototipo.html` ya tiene login conectado a `POST /api/v1/auth/login`. Home, perfil y permisos ya intentan leer `GET /api/v1/auth/yo`. Inicio ya prepara `cargarMaterias()` para leer `GET /api/v1/mesas-disponibles` (ver §2.3). Falta que implementes los endpoints abajo para que la app funcione completa.

> **Corrección 2026-11-02:** ajustado según la devolución `informe-devolucion-colega-sdd4.md` — §4 (citas RB), §5 (contratos de inscripción) y §6.1–6.3.

---

## 1. Qué ya funciona (sin tocar nada del backend)

| Pantalla | Endpoint usado | Estado |
|---|---|---|
| Login | `POST /api/v1/auth/login` | ✅ Conectado en el prototipo |
| Home alumno | `GET /api/v1/auth/yo` | ⚠️ Conectado, necesita token válido |
| Perfil | `GET /api/v1/auth/yo` | ⚠️ Conectado, necesita token válido |
| Permisos | `GET /api/v1/auth/yo` | ⚠️ Conectado, necesita token válido |

---

## 2. Qué DEBE implementar el colega (sin tocar la base de datos)

### 2.1 Registro libre de alumnos (pantalla 3 de la app)

> **PD-A:** el registro libre **no está en el análisis congelado** — requiere decisión del cliente antes de construirlo (§7 de la devolución).

**Endpoint:** `POST /api/v1/auth/registro`  
**Público:** sin JWT, sin permiso previo. Cualquier alumno nuevo puede crear su cuenta.

**Payload:**
```json
{
  "nombre": "María Soledad",
  "apellido": "Pérez",
  "documento": "38456789",
  "correo_electronico": "maria.perez@correo.com",
  "telefono": "3764123456",
  "tecnicatura": "Gestión Organizacional",
  "password": "contraseña123456"
}
```

**Respuestas:**
- `201 Created` → `{ "accion": "creada", "usuario_id": "..." }`
- `409 Conflict` → `{ "code": "documento-duplicado" }` (el DNI ya tiene cuenta)
- `422 Unprocessable` → `{ "code": "validacion", "errors": [...] }` (PD-24)

**Requisito de negocio:** antes de crear, validar que el DNI no exista ya en `us_usuario`. Si existe, `409`. Si no, crear persona + usuario con rol `alumno` y estado `pendiente` (pendiente de verificación por correo, que se implementa después).

---

### 2.2 Admin aprueba o rechaza usuarios (panel admin / "otro sistema")

> **PD-B:** la aprobación de usuarios tampoco está en el análisis congelado — requiere decisión del cliente (§7 de la devolución).

El colega dijo en su devolución que el admin debe poder ver en el otro sistema los usuarios nuevos y autorizarlos o no.

**Necesario en el backend:**

**A) Listar usuarios pendientes de aprobación:**
```
GET /api/v1/sigme/usuarios?estado=pendiente
```
Devuelve lista de usuarios con rol `alumno` y estado `pendiente`, con sus datos de persona (DNI, nombre, apellido, correo).

**B) Aprobar o rechazar un usuario:**
```
PATCH /api/v1/sigme/usuarios/{id}
```
Body:
```json
{
  "estado": "activo"   // o "rechazado"
}
```
Cuando el admin aprueba, el usuario pasa a `activo` y puede loguearse. Cuando rechaza, pasa a `rechazado` y no puede loguearse.

**C) El alumno que aún no está aprobado no puede loguear.** En el login, si el usuario existe pero está `pendiente` o `rechazado`, devolver `403` con mensaje apropiado.

---

### 2.3 Inscripción a materias (creadas por el secretario)

**Contexto:** el secretario crea las materias y las asignaciones en el otro sistema (SIGME web). El alumno **solo ve** las materias disponibles y selecciona a la que asistirá.

**Endpoint para el alumno:** `GET /api/v1/mesas-disponibles` — mesas vivas de la convocatoria vigente dentro de la ventana (`409 ventana-cerrada` si la ventana está cerrada). Ojo: `GET /api/v1/sigme/materias` existe pero está gated con `require_modulo("sigme_web")` y devuelve **`403 modulo-no-asignado`** a una sesión de alumno; además muestra el catálogo completo, no lo disponible en la ventana (§6.2 de la devolución). La app lo lee con `cargarMaterias()` — ya preparada en el prototipo — derivando la cascada G-04 (orientación → curso → materia → condición) de las combinaciones únicas de la misma respuesta, sin endpoints de catálogo aparte (RN-019: nunca expone `grupo_id`).

**Falta: endpoint para que el alumno se inscriba:**
```
POST /api/v1/inscripciones
```
**Payload** (UUIDs del catálogo, no strings; la convocatoria no viaja — es siempre la vigente):
```json
{
  "materia_id": "uuid-de-la-materia",
  "condicion_id": "uuid-de-la-condicion"
}
```

**Validaciones en orden** (cada una con su código):
1. Existe convocatoria vigente → `404 convocatoria-no-encontrada`
2. Hoy (BA) dentro de la ventana, inclusive hasta 23:59:59 → `409 ventana-cerrada`
3. Materia y condición existen y están activas → `404 materia-no-encontrada` / `404 condicion-no-encontrada`
4. Unicidad materia × convocatoria (filas no anuladas) → `409 inscripcion-duplicada`
5. Límite de la condición (por convocatoria, sólo al crear) → `409 limite-materias` — Previa 3 / Regular 8 / Libre sin límite (RB-03)
6. Existe mesa viva de la convocatoria para materia × condición → `409 mesa-no-disponible`

**Éxito:** `201 Created` con la fila creada en estado `inscripto`. El reintento de inscribir lo mismo recibe el mismo `409` sin duplicar.

**Regla de negocio:** el alumno elige sólo materia + condición (RB-30); el resto lo define la mesa existente. **No existe filtro por tecnicatura/año en el modelo** — el alumno es usuario con DNI. El límite por condición se valida al crear la inscripción (RB-03).

---

### 2.4 Recuperación por correo (NO dejar fuera)

El usuario pidió explícitamente que no se deje fuera la recuperación por correo.

**Endpoints faltantes:**
```
POST /api/v1/auth/olvido-clave    → { email } → dispara email de reset
POST /api/v1/auth/restablecer-clave → { token, clave_nueva } → usa el token
```

**Estado real (§6.1 de la devolución):** la tabla de tokens **ya existe** — `us_password_reset`, creada por la migración `alembic/versions/0002_auditoria_password_reset.py` (token_hash SHA-256 UNIQUE, uso único). **No toca el esquema.** Lo que falta es sólo:
1. Los dos endpoints de arriba (el router de auth hoy tiene `login`, `refresh`, `logout`, `logout-all`, `yo`, `cambiar-clave`).
2. Infraestructura de email/cola — **no existe en el código** (mismo gap que la confirmación de inscripción).

**Recomendación:** devolver el código por respuesta **sólo en entorno de desarrollo** (en producción sería una fuga de tokens); en producción, enviar por correo cuando haya SMTP. El usuario dijo que no se deja fuera, así que debe estar en el plan aunque el envío de correo quede para después.

---

### 2.5 Vista admin (NO dejar fuera)

El panel admin ya existe en el prototipo (`#admin`). Debe poder:
- Ver lista de usuarios con su estado (activo, pendiente, rechazado, bloqueado)
- Aprobar/rechazar usuarios pendientes (PATCH /api/v1/sigme/usuarios/{id})
- Ver inscripciones de alumnos
- Ver permisos emitidos

Endpoints que ya existen y puede usar:
- `GET /api/v1/sigme/usuarios` (requiere `usuario.gestionar`)
- `GET /api/v1/sigme/personas` (requiere `persona.listar`)

Falta el PATCH para aprobar/rechazar (ver punto 2.2).

---

## 3. Contrato de error (PD-24) — ya corregido

Después del fix F1/F2 (`7a1370d`, rama `feat/sdd-3-mesas`), el 422 responde `code: "validacion"` en toda la API. El colega debe mantener este formato en cualquier endpoint nuevo:
```json
{ "code": "validacion", "detail": "...", "errors": [ { "field": "...", "message": "..." } ] }
```

---

## 4. Qué NO hace falta para activar la app (pero se deja para después)

| Qué | Por qué no es bloqueante |
|---|---|
| Panel admin completo | Ya existe la maqueta; solo falta conectar los endpoints de usuarios |
| Recuperación por correo real | Requiere SMTP/cola de envío; se puede hacer con token en BD primero |
| PRÉDITO de mesas | No es parte del flujo del alumno |
| Reportes | No bloquean el uso de la app |

---

## 5. Orden sugerido de implementación

1. **Inscripción a materias** (`GET /api/v1/mesas-disponibles`, `POST /api/v1/inscripciones`) — contrato cerrado (§2.3), sin dependencias de decisiones pendientes.
2. **Recuperación por correo** (`/api/v1/auth/olvido-clave`, `/api/v1/auth/restablecer-clave`) — la tabla ya existe; sólo faltan endpoints + email. Requiere que el cliente fije la prioridad.
3. **Abrir los PR de `feat/sdd-3-mesas` y `feat/sdd-4-inscripciones`** — ambas ya están en el remoto; falta integrarlas a `main`.
4. **Registro libre y aprobación de usuarios** (PD-A / PD-B) — a esperar decisión del cliente; mientras tanto el alta sigue siendo por admin.

---

## Firma

Backend: fix F1/F2 en `feat/sdd-3-mesas` @ `7a1370d`; línea canónica `main` @ `6018204` (PR #4)  
Pruebas: según la devolución `informe-devolucion-colega-sdd4.md` — 181 passed, ruff limpio  
Informe relacionado: `informes\informe-fix-landing-colega.md`, `informes\informe-para-colega-modificaciones.md`