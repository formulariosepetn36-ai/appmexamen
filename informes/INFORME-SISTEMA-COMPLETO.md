# Informe Completo del Sistema — Backend EPET36

**Versión:** SDD-5 completado (reportes) — 7/11/2026
**Rama actual:** `feat/sdd-4-inscripciones` @ `4c2221b` (19 commits sobre `feat/sdd-3-mesas` = `c9a0ee4`)
**Suite de tests:** 272 passed / ruff limpio / árbol limpio
**Remoto:** `https://github.com/formulariosepetn36-ai/backend-epet-n36.git`

---

## 1. Visión General del Proyecto

### Propósito
Backend API para **SIGME / SIGME-M** (sistema de gestión de mesas de examen y preinscripción de la Escuela de Educación Técnica N°36). Provee:

- **Auth** (JWT ES256 access + refresh con rotación, Argon2id)
- **Preinscripción pública** (landing sin auth)
- **SIGME Web** (gestión: personas, usuarios, catálogo, convocatorias, mesas, grupos, reportes)
- **SIGME Mobile** (alumno: convocatoria vigente, mesas disponibles, inscribirse, mis inscripciones, dispositivos push)

### Stack Tecnológico
| Componente | Tecnología | Detalle |
|------------|-----------|---------|
| Framework | FastAPI + Pydantic v2 | Python 3.13 |
| Base de datos | PostgreSQL (Neon) | SQLAlchemy 2.0 declarativo + Alembic |
| Auth | JWT ES256 | Access 15min + Refresh 7d (rotación, hash SHA-256) |
| Hash | Argon2id | `password_hash` en `us_usuario` |
| TZ | America/Argentina/Buenos_Aires | UTC-3 fijo (sin horario de verano desde 2009) |
| Despliegue | Vercel (serverless) | Pool TCP retirado, driver HTTP Neon |
| Lint | Ruff | `ruff check .` |
| Tests | pytest + SQLite/aiosqlite | 272 tests unitarios |

### Convenciones de Arquitectura (analisis.txt §5)
- **Dominios** en `app/features/<dominio>/{router,service,models,schemas}.py`
- **Routers** solo HTTP; lógica en `service.py` sin importar FastAPI
- **Único punto de registro** de routers: `app/api/v1/api.py`
- **Prefijo `/api/v1`** aplicado en factory `create_app()`
- **CORS obligatorio** (servicio independiente, landing separada)

---

## 2. Estado de SDDs (Roadmap Completado)

| SDD | Nombre | Rama | Commits | Estado | Tests |
|-----|--------|------|---------|--------|-------|
| SDD-0 | Bootstrap backend | `feat/sdd-0-bootstrap` | — | ✅ Base | — |
| SDD-1 | Auth (JWT, login, refresh, logout, cambiar clave) | `feat/sdd-1-auth` | — | ✅ | ✅ |
| SDD-2 | SIGME Base (personas, usuarios, catálogo, preinscripción) | `feat/sdd-2-sigme-base` | — | ✅ | ✅ |
| SDD-3 | Mesas y convocatorias (CRUD, grupos, mesas, ventanas) | `feat/sdd-3-mesas` | 7 | ✅ | 181 |
| **SDD-4** | **Inscripciones y consultas de alumno** | **`feat/sdd-4-inscripciones`** | **10** | **✅ 7/7** | **203→220** |
| **SDD-5** | **Reportes de cierre** | **`feat/sdd-4-inscripciones`** | **5** | **✅ 5/6 (T6 pendiente)** | **243→272** |

**Total suite actual:** 272 tests passed, 1 warning (starlette deprecation), ruff limpio.

---

## 3. Arquitectura de Dominios (app/features/)

```
app/features/
├── auth/                    # SDD-1: JWT, sesiones, login, refresh, logout, cambiar clave
├── auditoria/               # PD-05: tabla aud_evento (append-only, snapshot JSONB)
├── catalogo/                # SDD-2: orientaciones, cursos, materias, condiciones
├── dispositivos/            # SDD-4 T6: tabla es_dispositivo (push notifications)
├── inscripciones/           # SDD-4 T1-T5: convocatoria vigente, mesas disponibles, alta, gestión, mis inscripciones
├── mesas/                   # SDD-3: convocatorias, grupos, mesas, ventanas
│   ├── router.py            # /sigme/convocatorias
│   ├── router_grupos.py     # /sigme/grupos
│   ├── router_mesas.py      # /sigme/mesas
│   └── router_convocatorias.py
├── personas/                # SDD-2: CRUD personas (filtro q=)
├── preinscripcion/          # SDD-2: landing pública + ventanas SIGME
│   ├── router.py            # /preinscripcion (público)
│   └── router_sigme.py      # /sigme/ventanas-preinscripcion
├── reportes/                # SDD-5: 5 endpoints de reportes de cierre
├── usuarios/                # SDD-2: usuarios, roles, permisos, módulos, seguridad
└── health/                  # /healthz (contrato operativo)
```

---

## 4. Modelo de Datos (Tablas Principales)

### Auth & Usuarios (SDD-1/2)
| Tabla | Descripción | PK | FK / Índices clave |
|-------|-------------|-----|-------------------|
| `us_usuario` | Usuarios del sistema | `id` (UUID) | `persona_id` → `pe_persona` |
| `us_rol` | Roles (alumno, secretario, director, admin, superadmin) | `codigo` | — |
| `us_permiso` | 13 permisos granulares (§2.7) | `codigo` | — |
| `us_modulo` | `landing`, `sigme_web`, `sigme_mobile` | `codigo` | — |
| `us_usuario_rol` | Usuario ↔ Rol | composite | — |
| `us_usuario_modulo` | Usuario ↔ Módulo | composite | — |
| `us_rol_permiso` | Rol ↔ Permiso (matriz PD-03) | composite | — |
| `us_sesion` | Refresh tokens (hash SHA-256) | `id` | `usuario_id` |
| `us_password_reset` | PD-04: reset por email | `id` | `usuario_id` |

### Catálogo (SDD-2)
| Tabla | Descripción | PK | Campos clave |
|-------|-------------|-----|--------------|
| `es_orientacion` | Orientaciones (ej: "Técnica") | `id` | `descripcion`, `activo` |
| `es_curso` | Cursos/años (ej: "3er Año") | `id` | `orientacion_id`, `anio`, `activo` |
| `es_materia` | Materias por curso | `id` | `curso_id`, `descripcion`, `es_taller`, `activo` |
| `es_condicion` | Condiciones de cursada | `id` | `descripcion`, `limite_materias` (NULL=∞), `activo` |

### Mesas y Convocatorias (SDD-3)
| Tabla | Descripción | PK | Campos clave |
|-------|-------------|-----|--------------|
| `es_convocatoria` | Campaña de mesas | `id` | `descripcion`, `fecha_inicio_inscripcion`, `fecha_fin_inscripcion`, `activa` |
| `es_grupo_horario` | Grupo = fecha+hora | `id` | `convocatoria_id`, `fecha`, `hora`, `nombre` |
| `es_mesa_examen` | Mesa individual (materia x condición) | `id` | `convocatoria_id`, `grupo_id`, `materia_id`, `condicion_id`, `fecha`, `hora`, `estado` (planificada/realizada/cerrada), **snapshots**: `orientacion_nombre`, `curso_nombre`, `materia_nombre`, `condicion_nombre` |
| `es_mesa_inscripcion` | Inscripción alumno↔mesa | `id` | `usuario_id`, `mesa_examen_id`, `convocatoria_id`, `materia_id`, `condicion_id`, `estado` (inscripto/anulado), `inscripto_en` |

**Índices únicos críticos:**
- `uq_mesa_unica`: `(convocatoria_id, grupo_id, materia_id, condicion_id)` — una mesa por grupo x materia x condición
- `uq_inscripcion_unica`: `(convocatoria_id, usuario_id, materia_id)` WHERE `deleted_at IS NULL AND estado <> 'anulado'` — **unicidad por materia × convocatoria** (no por mesa)

### Dispositivos (SDD-4 T6)
| Tabla | Descripción | PK | Índice único |
|-------|-------------|-----|--------------|
| `es_dispositivo` | Dispositivos push por usuario | `id` | `(usuario_id, device_id)` WHERE `deleted_at IS NULL` |

### Auditoría (PD-05)
| Tabla | Descripción |
|-------|-------------|
| `aud_evento` | Append-only, snapshot JSONB (excluye password_hash, refresh tokens, session hashes) |

### Preinscripción (SDD-2)
| Tabla | Descripción |
|-------|-------------|
| `pr_preinscripcion` | 6 campos obligatorios (nombre_alumno, documento, fecha_nacimiento, orientacion, nombre_tutor, email) |
| `pr_ventana` | Ventanas por `anio_lectivo` (upsert, unique `uq_ventana_anio`) |

---

## 5. Endpoints por Dominio

### Auth (`/api/v1/auth`)
| Método | Ruta | Permiso/Session | Descripción |
|--------|------|-----------------|-------------|
| POST | `/auth/login` | — | `TokenPair` (access + refresh) |
| POST | `/auth/refresh` | refresh válido | Rota par, revoca anterior |
| POST | `/auth/logout` | access | Revoca sesión (204) |
| POST | `/auth/logout-all` | access | Revoca todas (204) |
| POST | `/auth/cambiar-clave` | access | `AccessOnly` (access nuevo) |
| GET | `/yo` | access | `YoResponse` (usuario, roles, permisos, módulos) |

**Rate limit login (PD-27):** 5 fallos/15min → 429 `Retry-After`, bloqueo 15min.

### Preinscripción Pública (`/api/v1/preinscripcion`)
| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/preinscripcion` | **NINGUNO** | Único endpoint público sin JWT |

### SIGME Web (`/api/v1/sigme/*`) — Gate: `require_modulo("sigme_web")` + permiso
| Dominio | Endpoints | Permisos |
|---------|-----------|----------|
| Personas | GET/POST/PATCH `/personas`, `/personas/{id}` | `persona.listar`, `persona.modificar`, `usuario.gestionar` (POST) |
| Usuarios | GET/POST `/usuarios`, GET/POST `/roles`, `/permisos`, `/modulos` | `usuario.gestionar` |
| Catálogo | GET/POST/PATCH `/orientaciones`, `/cursos`, `/materias`, `/condiciones` | `usuario.gestionar` (escritura), `sigme_web` (lectura) |
| Convocatorias | GET/POST/PATCH `/convocatorias`, `/convocatorias/{id}` | `usuario.gestionar` (escritura), `sigme_web` (lectura) |
| Ventanas | GET/POST `/ventanas-preinscripcion` | `usuario.gestionar` (POST), `sigme_web` (GET) |
| Grupos | POST/PATCH `/grupos`, GET `/grupos?convocatoria_id=` | `mesa.crear`/`mesa.modificar`/`mesa.listar` |
| Mesas | GET `/mesas`, `/mesas/por-fecha`, `/mesas/{id}`, PATCH `/mesas/{id}` | `mesa.listar`/`mesa.modificar` |
| Cobertura | GET `/cobertura-mesas?convocatoria_id=` | `mesa.listar` |

### Inscripciones y Consultas Alumno (`/api/v1/*`) — **SIN prefijo de dispositivo (L2)**
| Método | Ruta | Gate | Descripción |
|--------|------|------|-------------|
| GET | `/convocatoria-vigente` | Sesión válida | Convocatoria `abierta` o `activa` más reciente (A-SDD4-1) |
| GET | `/mesas-disponibles` | `mesa.listar` | Mesas vivas de la vigente **solo en ventana** (RB-07/23) → 409 fuera; G-04 cascada |
| POST | `/inscripciones` | `inscripcion.crear` | Body `{materia_id, condicion_id}`; validaciones en orden S3 → crea `inscripto` |
| GET | `/inscripciones?mesa_id=&convocatoria_id=` | `inscripcion.listar` | Gestión: filtros opcionales, 404 si ID inexistente |
| GET | `/mis-inscripciones` | `inscripcion.listar` | Solo propias; estado + nombres + fecha/hora mesa; sin paginación |
| DELETE | `/mis-inscripciones/{id}` | `inscripcion.anular` | Solo propia, en ventana → `anulado` (libera unicidad); 204 idempotente |
| POST | `/dispositivos` | Sesión válida | Upsert por `device_id` (sin permiso extra) |
| GET | `/dispositivos` | Sesión válida | Lista propios, orden `created_at` desc |
| DELETE | `/dispositivos/{id}` | Sesión válida | Soft delete idempotente |

### Reportes (`/api/v1/reportes/*`) — Permiso `reporte.exportar` (secretario, director, admin, superadmin)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/reportes/permiso-examen/{usuario_id}` | Individual por alumno (mesas con inscripción activa + snapshots) |
| GET | `/reportes/permisos-examen?convocatoria_id=` | Masivo agrupado por mesa (alumnos por mesa) |
| GET | `/reportes/acta-volante/{mesa_id}` | Por mesa: alumnos inscriptos + snapshots; 404 `mesa-sin-inscriptos` si RB-22 falla |
| GET | `/reportes/mesa/{mesa_id}` | Snapshot mesa + estado derivado (fecha/hora BA vs hoy: `planificada`/`cerrada`) |
| GET | `/reportes/planilla-grupos/{convocatoria_id}` | Por convocatoria: grupos ordenados fecha/hora con mesas (materia, condición); RB-22 |

**Reglas transversales de reportes:**
- **RB-22 (vida):** Solo mesas con ≥ 1 inscripción `inscripto` + `deleted_at IS NULL`
- **RB-19 (snapshots):** Nombres desde `es_mesa_examen` (NO catálogo actual)
- **Auditoría (PD-05):** Cada descarga/impresión registrada en `aud_evento`

---

## 6. Reglas de Negocio Críticas (RB)

| RB | Descripción | Impacto |
|----|-------------|---------|
| **RB-01** | **No hay cupo por mesa** | Unlimited inscriptos por mesa |
| **RB-03 / PD-02** | Límite materias por condición: Previa 3, Regular 8, Libre ∞ (NULL) | Validado SOLO al inscribirse (CU-37), por convocatoria |
| **RB-06** | Un alumno puede tener múltiples inscripciones en la misma convocatoria (distintas materias) | — |
| **RB-07 / RB-23** | Ventana de inscripción: inclusive hasta 23:59:59 BA | `hoy_buenos_aires()` = `(datetime.now(UTC) - 3h).date()` |
| **RB-08** | Unicidad por **materia × convocatoria** (no por mesa) | `uq_inscripcion_unica` excluye `anulado` |
| **RB-08b** | Anulación solo dentro de ventana | Fuera → 409 `ventana-cerrada` |
| **RB-09** | Convocatoria `activa=false` bloquea inscripciones aun con ventana vigente | — |
| **RB-11** | Snapshots inmutables en `es_mesa_examen` (4 nombres) | Se copian al crear/reasignar mesa |
| **RB-17** | Fechas de mesa NUNCA cambian bajo alumnos inscriptos | Mover grupo → 409 `ventana-abierta` si ventana abierta |
| **RB-18** | No hay notas, asistencia ni estados de resultado | Solo `inscripto`/`anulado` |
| **RB-19** | Reportes leen **solo snapshots** (no catálogo actual) | — |
| **RB-22** | **Vida:** Lecturas de mesas/inscripciones → solo con ≥1 inscripción `inscripto` | Aplica a TODOS los reportes y listados SIGME |
| **RB-26** | Orden determinístico (fecha, hora, id) para cacheo cliente | — |
| **RB-28** | Grupo = fecha+hora; crea N = materias × condiciones mesas en bloque | — |
| **RB-29** | Mover grupo = mueve TODAS sus mesas en MISMA transacción | Snapshots recalculados |
| **RB-30** | Alumno elige SOLO `materia_id` + `condicion_id` (convocatoria = vigente, mesa = backend) | — |
| **RB-31** | Cobertura: reporte de consulta (no gate) | — |
| **RB-32** | Planilla de grupos confirmada 2026-10-04 para primera entrega | — |

---

## 7. Migraciones Alembic (Estado Actual)

| Rev | Nombre | Descripción |
|-----|--------|-------------|
| 0001 | `initial` | Esquema base (usuarios, catálogo, mesas, preinscripción, auditoría) |
| 0002 | `auditoria_password_reset` | `us_password_reset` + `aud_evento` (PD-04/05) |
| 0003 | `seed_roles_condiciones` | Roles + matriz rol×permiso (PD-03) + condiciones default (PD-02: Previa 3, Regular 8, Libre NULL) |
| **0004** | **`dispositivos`** | **Tabla `es_dispositivo` + enum `plataforma_dispositivo` + índices** |

**Comando útil:** `alembic upgrade head --sql` (DDL sin conexión)

---

## 8. Tests y Calidad

### Suite Actual
- **272 tests** passed
- **1 warning** (starlette testclient deprecation — no afecta)
- **ruff limpio**

### Estructura de Tests
```
tests/
├── conftest.py                    # Aislamiento env, SQLite memoria, registra todos los modelos
├── unit/
│   ├── test_auth.py               # Auth: login, refresh, logout, rate limit
│   ├── test_mesas.py              # SDD-3: CRUD mesas, grupos, convocatorias
│   ├── test_mesas_disponibles.py  # SDD-4 T2
│   ├── test_inscripciones.py      # SDD-4 T3
│   ├── test_inscripciones_gestion.py # SDD-4 T4
│   ├── test_mis_inscripciones.py  # SDD-4 T5
│   ├── test_dispositivos.py       # SDD-4 T6
│   ├── test_reportes_permiso_examen.py # SDD-5 T1
│   ├── test_reportes_permisos_masivo.py # SDD-5 T2
│   ├── test_reportes_acta_volante.py   # SDD-5 T3
│   ├── test_reportes_mesa_snapshot.py  # SDD-5 T4
│   ├── test_reportes_planilla_grupos.py # SDD-5 T5
│   ├── test_models_es_pr.py       # Cobertura 25/25 tablas + índices/CHECKs
│   ├── test_preinscripcion.py
│   ├── test_superficie_publica.py # Solo POST /preinscripcion público
│   └── test_*.py                  # Otros
```

### Patrones de Test (Harness Común)
```python
# make_usuario: crea usuario + rol + módulo + permisos (códigos exactos de seed.py)
# login: POST /auth/login → headers Authorization
# crear_convocatoria: devuelve UUID plano (evita ORM vencido)
# crear_catalogo: orientación + curso + N materias + M condiciones
# post_grupo: crea grupo + mesas en bloque (RB-28)
# inscribir_alumno: inserta EsMesaInscripcion directo (para tests de reporte)
```

---

## 9. Documentación Viva

### README.md
Contiene secciones completas para:
- Stack y restricción Vercel
- Estructura de dominios
- Auth (tokens, rate limit, contrato de error)
- SIGME Web (tabla de endpoints con permisos)
- Mesas y convocatorias (reglas RB-22, vencidas, RB-28/29/31)
- **Inscripciones y consultas alumno (SDD-4)** — 9 endpoints con tabla detallada
- Comandos y variables

### Análisis (fuente de verdad)
```
analisis/
├── 00-plan-de-analisis.md
├── 01-glosario-y-alcance.md      # Glosario + tabla de reportes (3 tipos)
├── 02-actores-y-consumidores.md  # Matriz rol×permiso (PD-03)
├── 03-eventos-y-gatillos.md      # E-xx gatillos
├── 04-maquinas-de-estados.md     # Estados convocatoria, mesa, inscripción
├── 05-casos-de-uso-sigme.md      # CU-19..CU-30 (SIGME Web)
├── 06-casos-de-uso-sigme-m.md    # CU-34..CU-42 (SIGME Mobile)
├── 07-estados-criticos-y-excepciones.md
├── 08-reglas-de-negocio.md       # RB-01..RB-32 (fuente)
├── 09-requisitos-no-funcionales.md # NFR-003: latencia reportes ≤2s
└── analisis.txt                  # DDL, §6 endpoints, PDs
```

### ODD Feature Docs (`odd/tasks/`)
| Archivo | SDD | Contenido |
|---------|-----|-----------|
| `sdd-4-inscripciones.md` | SDD-4 | 7 tasks, specs S1-S7, assumptions A-SDD4-1..9, Log L1-L11 |
| `sdd-5-reportes.md` | SDD-5 | 6 tasks, specs S1-S5, Log L1-L6 |

---

## 10. Decisiones Clave (PDs Cerradas)

| PD | Decisión | Fuente |
|----|----------|--------|
| **PD-01** | Preinscripción: 6 campos obligatorios | analisis.txt |
| **PD-02** | Condiciones: Previa 3, Regular 8, Libre NULL; editables desde SIGME | analisis.txt, seed 0003 |
| **PD-03** | Roles/permisos en migración 0003 (idempotente); matriz §2.4 celda `S`=asigna, `—`/`PENDIENTE`=NO | seed.py, 0003 |
| **PD-04** | `us_password_reset` tabla + email queue (v1) | 0002 |
| **PD-05** | `aud_evento` append-only JSONB; scope: escrituras, 401/403, reportes; excluye lecturas | 0002 |
| **PD-06** | Vercel serverless; pool TCP out; driver HTTP Neon; Alembic desde CI/local | analisis.txt |
| **PD-12** | Crear grupo con ventana abierta = OK; MOVER con ventana abierta = 409 | SDD-3 |
| **PD-13** | Hora NO participa en `uq_mesa_unica` | SDD-3 |
| **PD-19 / A-SDD4-5** | Sin mesa viva del combo → 409 `mesa-no-disponible` | SDD-4 |
| **PD-23 / A-SDD4-2** | RB-22 NO aplica a `/mesas-disponibles` (mesas sin inscripciones SÍ aparecen) | SDD-4 |
| **PD-25** | DELETE idempotente → 204 sin cuerpo | SDD-4/5 |
| **PD-27** | Rate limit login: 5 fallos/15min por usuario | Auth |

### Asunciones SDD-4 (A-SDD4-1..9 — TODAS CERRADAS)
1. **Vigente** = `abierta` si existe, si no `activa` más reciente, si no 404
2. RB-22 NO aplica a `/mesas-disponibles`
3. Cascada G-04 desde combinaciones únicas de `/mesas-disponibles`
4. Convocatoria NO viaja en body de inscripción (siempre vigente)
5. Sin mesa → 409 `mesa-no-disponible`
6. Elección determinística: fecha más próxima, hora e id desempate
7. Límite materias por condición (ya en PD-02)
8. Confirmación email FUERA de SDD-4 (sin infra cola)
9. Sin paginación v1 en `/mis-inscripciones`

---

## 11. Deuda Técnica / Próximos Pasos

### SDD-5 T6 — README + Cierre (Pendiente)
- [ ] Actualizar `README.md` con sección **Reportes** (tabla 5 endpoints)
- [ ] Cerrar Log en `odd/tasks/sdd-5-reportes.md`
- [ ] Commit + push

### SDD-6 — Próximo en Roadmap
- Endpoints de reset de contraseña por email (`us_password_reset` ya existe en 0002)
- Anulación por secretaría (INS-03 — pendiente en doc 04)
- Templates de impresión (A4, 3 por carilla) para reportes
- Generación PDF server-side o client-side

### Deuda Conocida
- `persona_documento` en acta volante: actualmente string vacío (TODO: join `pe_persona`)
- Email queue no implementada (requerida para PD-04 reset + PD-05 auditoría reportes)
- `acta-volante` devuelve 404 `mesa-sin-inscriptos` (decisión: que el secretario sepa que no hay acta)

---

## 12. Cómo Empezar (Onboarding para los 2 Nuevos Integrantes)

### 1. Clonar y Configurar
```bash
git clone https://github.com/formulariosepetn36-ai/backend-epet-n36.git
cd backend-epet-n36
git checkout feat/sdd-4-inscripciones  # rama actual con todo
cp env.example .env                    # completar variables (ver README)
python -m pip install -e ".[dev]"
```

### 2. Verificar Entorno
```bash
ruff check .          # debe pasar limpio
python -m pytest      # 272 passed
```

### 3. Entender el Flujo Principal
```
Landing (público)          → POST /preinscripcion
    ↓ (preinscripción aprobada → crea usuario en SIGME)
SIGME Mobile (alumno)      → GET /convocatoria-vigente
                             GET /mesas-disponibles (en ventana)
                             POST /inscripciones {materia_id, condicion_id}
                             GET /mis-inscripciones
                             DELETE /mis-inscripciones/{id}
                             POST/GET/DELETE /dispositivos
SIGME Web (secretario)     → CRUD personas, usuarios, catálogo
                             CRUD convocatorias, grupos, mesas
                             GET /reportes/* (permiso reporte.exportar)
```

### 4. Archivos Clave para Empezar a Contribuir
| Área | Archivo |
|------|---------|
| Entender auth | `app/features/auth/{router,service,dependencies,tokens}.py` |
| Entender inscripciones | `app/features/inscripciones/{service_inscripciones,router_inscripciones,schemas_inscripciones}.py` |
| Entender reportes | `app/features/reportes/{service,router,schemas}.py` |
| Entender mesas | `app/features/mesas/{router_grupos,router_mesas,service_grupos,service_mesas}.py` |
| Ver tests de referencia | `tests/unit/test_inscripciones.py`, `tests/unit/test_reportes_permiso_examen.py` |

### 5. Convenciones de Trabajo (ODD — Organic Driven Development)
1. **Test-first:** RED → GREEN → suite + ruff
2. **Risk line** al cerrar cada cambio (`Risk: item N` o `Risk: none`)
3. **Conventional commits:** `feat(dominio): descripción`
4. **Avisar antes de commit** (regla del usuario)
5. **Engram:** `mem_save` decisiones, fixes, discoveries
6. **Session summary** obligatorio al cerrar

---

## 13. Contacto y Referencias

- **Repo:** https://github.com/formulariosepetn36-ai/backend-epet-n36
- **Rama de trabajo:** `feat/sdd-4-inscripciones` (HEAD = `4c2221b`)
- **PRs pendientes:** `feat/sdd-3-mesas` y `feat/sdd-4-inscripciones` contra `main`
- **Informe devolución colega:** `C:\Users\Acer\Downloads\informe-devolucion-colega-sdd4.md` (PDs abiertos para cliente frontend)

---

**Fin del informe.** El sistema está en estado **estable, testeado y documentado** listo para que los nuevos integrantes tomen la posta del frontend SIGME.