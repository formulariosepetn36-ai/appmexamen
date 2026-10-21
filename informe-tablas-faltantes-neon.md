# Informe técnico — Tablas faltantes en la base de datos del proyecto SIGME-M

*(Backend E.P.E.T. N°36 — Inscripción a mesas de examen)*

**Para:** equipo de base de datos
**Asunto:** faltan 4 tablas en la base online (Neon). El backend ya las tiene implementadas; solo falta aplicarlas en la base.

## 1. Contexto

El backend del sistema de inscripción a mesas de examen usa una base de datos PostgreSQL alojada en Neon (esquema `public`), gestionada con migraciones de **Alembic**. El esquema base (migración `0001`) **ya está aplicado** en la base y se encuentra vacío (sin usuarios, sin datos de prueba).

El código del backend (repositorio `backend-epet-n36-main`, rama `feat/m1-app-modelo`, commit `6df0c6d`) espera un total de **26 tablas**. La consulta de estado arrojó que la base tiene **22 tablas del esquema base + `alembic_version`**. Faltan exactamente **4 tablas**, todas definidas en la migración **`0002_app_modelo.py`**.

## 2. Las 4 tablas faltantes y para qué se usan

| # | Tabla | Necesidad en la base de datos |
|---|---|---|
| 1 | `aud_evento` | **Auditoría del sistema.** Registra qué operación se realizó, sobre qué registro, por quién y cuándo. Sin esta tabla no hay trazabilidad de cambios (requisito del modelo §3: quién modificó una inscripción, un usuario o una mesa). |
| 2 | `es_permiso_examen` | **Autorizaciones de examen por materia.** Define qué alumno tiene examen autorizado/pendiente en cada materia de cada curso. Es la base de las reglas de negocio que el sistema evalúa antes de permitir inscribirse a una mesa. |
| 3 | `es_permiso_inscripcion` | **Autorizaciones de inscripción por materia.** Define qué alumno tiene la inscripción habilitada o restringida en cada materia. El sistema la consulta para validar cada preinscripción. |
| 4 | `us_password_reset` | **Recuperación de contraseña.** Almacena los tokens de restablecimiento de contraseña de los usuarios (docentes/directivos). Sin ella, el flujo "olvidé mi contraseña" del login no puede funcionar. |

## 3. Estado del backend

Las 4 tablas **ya están implementadas en el backend**, por duplicado y de forma consistente:

- Como **modelos SQLAlchemy** (definición que usa la aplicación):
  - `aud_evento` → `app/features/auditoria/models.py`
  - `es_permiso_examen` y `es_permiso_inscripcion` → `app/features/permisos/models.py`
  - `us_password_reset` → `app/features/usuarios/models.py`
- Como **`CREATE TABLE`** en la migración `alembic/versions/0002_app_modelo.py` (con sus índices, únicos y restricciones según el modelo §3).

El modelo M1 correspondiente ya fue revisado y aprobado; la migración `0002` está commiteada y es de tipo **aditiva**: únicamente crea tablas nuevas.

## 4. Qué se pide

Aplicar en la base de Neon la migración pendiente:

```
alembic upgrade head
```

Esto llevará `alembic_version` de `0001` a `0002` y creará **solo** las 4 tablas listadas. La operación:

- **No modifica** tablas existentes ni sus datos.
- **No borra** nada.
- No inserta filas: las tablas quedan vacías, listas para que el backend las use.
- Es verificable después con `SELECT version_num FROM alembic_version;` (debe devolver `0002`).

## 5. Verificación previa realizada

Se consultó la base en modo solo lectura (vía `information_schema`): 23 tablas reales (22 de negocio + `alembic_version`), versión Alembic `0001`, conteos en 0 en `us_modulo`, `us_usuario`, `pe_documento_tipo`, `pe_persona` y `pr_preinscripcion`, y **cero tablas inesperadas**. El único delta entre el código y la base son las 4 tablas de la migración `0002`.

Quedamos a la espera de su confirmación de aplicación para continuar con el desarrollo de la app (módulo de inscripción).

---

*Informe generado el 2026-10-20 a partir de una consulta de solo lectura a la base. Fuente del estado: `information_schema` de Neon. Ubicación del backend canónico: `app para inscrpcion a mesa/backend-epet-n36-main`.*
