-- ==============================================================================
-- *** SUPERSEDIDO (2026-09-29) — NO CARGAR ESTE ARCHIVO ***
-- Prototipo original (nuestro diseño con nombres en inglés). La BD vigente es
-- docs/modelo/prototipo-bd-adaptado.txt, que combina este diseño con analisis.txt.
-- ==============================================================================
-- Prototipo de base de datos — App de Inscripción a Mesas de Examen
-- Escuela Secundaria E.P.E.T. N°36 — Posadas, Misiones
--
-- Fuente     : docs/diseno.md §4 (Modelo de datos) con las ediciones de la tarea
--              odd/tasks/condiciones-alumno.md (D15 / D6 / D1).
-- Fecha      : 2026-09-29
-- Dialecto   : PostgreSQL 14+ (uuid, timestamptz, índices parciales, trigger
--              BEFORE INSERT OR UPDATE). gen_random_uuid() viene en el core desde
--              PostgreSQL 13: no hace falta pgcrypto.
--
-- CONFLICTO #2 — RESUELTO (comparativa, sección 11, fila "Quién ASIGNA la
--   condicion"): la condición la pone el ALUMNO al inscribirse, una por materia,
--   por defecto 'regular' (D15). Vive en enrollments.condition; el admin solo
--   puede corregirla desde el panel (§2). Las materias se AGRUPAN por condición
--   al generar el permiso: un grupo = un permiso; si hay mezcla salen dos
--   permisos (RB-18). tools/generar_permiso.py no cambia.
--
-- CONFLICTO #1 — ABIERTO (comparativa, sección 11, fila "Idioma de tablas"):
--   se conservan nuestros nombres según docs/diseno.md §4 (inglés, con
--   `mesas` en castellano). Si el área impone su norma (analisis.txt 1.1,
--   prefijos pe_/us_/es_/pr_), el mapeo sugerido es:
--       degrees            -> es_tecnicatura
--       students           -> es_alumno
--       users              -> us_usuario
--       subjects           -> es_materia
--       mesas              -> es_mesa_examen
--       enrollments        -> es_mesa_inscripcion
--       permits            -> permiso_examen
--       permit_enrollments -> permiso_examen_materia
--       password_resets    -> us_password_reset
--       audit_log          -> aud_evento
--
-- Convenciones técnicas (analisis.txt 1.1–1.10 / comparativa §2.3):
--   * id uuid PRIMARY KEY DEFAULT gen_random_uuid()
--   * created_at / updated_at / deleted_at con timestamptz (soft delete)
--   * función trg_set_updated_at() + CREATE TRIGGER en toda tabla con updated_at
--   * índice parcial  idx_<tabla>_activa ON <tabla>(id) WHERE deleted_at IS NULL
--   * ON DELETE explícito en CADA FK: CASCADE (junction/detalle),
--     RESTRICT (referencias que no se pierden), SET NULL (referencia opcional)
--   * nombres: uq_* (únicos), idx_* (índices), ck_* (checks)
--   * varchar(n) con límite de negocio, nunca text sin tope
--   * COMMENT ON en las columnas que no se explican solas
-- ==============================================================================

SET client_encoding = 'UTF8';

-- ------------------------------------------------------------------------------
-- Auditoría de tabla: se crea UNA vez y la usan todas las tablas con updated_at.
-- DEFAULT now() solo corre en INSERT; sin este trigger, updated_at queda
-- congelado en el valor del alta (comparativa §2.3).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- 1) degrees — catálogo fijo de tecnicaturas (2 filas)
-- ==============================================================================
CREATE TABLE degrees (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       varchar(120) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz,
  deleted_at timestamptz,
  CONSTRAINT ck_degrees_name_no_vacia CHECK (btrim(name) <> '')
);
COMMENT ON TABLE  degrees     IS 'Catálogo fijo: 2 tecnicaturas de la E.P.E.T. N°36.';
COMMENT ON COLUMN degrees.name IS 'Nombre corto del impreso. OJO: el nombre formal de es_orientacion en analisis.txt es más largo ("Tecnicatura en Tecnología de los Alimentos"); ver comparativa sección 11, fila 18 (conflicto de nombres ABIERTO).';

CREATE UNIQUE INDEX uq_degrees_name ON degrees (name) WHERE deleted_at IS NULL;
CREATE INDEX idx_degrees_activa ON degrees (id) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_degrees_updated_at
  BEFORE INSERT OR UPDATE ON degrees
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 2) users — cuentas de acceso (alumno y admin)
-- ==============================================================================
CREATE TABLE users (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username             varchar(60) NOT NULL,
  password_hash        varchar(255) NOT NULL,
  role                 varchar(10) NOT NULL DEFAULT 'alumno',
  status               varchar(10) NOT NULL DEFAULT 'activo',
  must_change_password boolean NOT NULL DEFAULT true,
  last_login_at        timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz,
  deleted_at           timestamptz,
  CONSTRAINT ck_users_role          CHECK (role IN ('alumno', 'admin')),
  CONSTRAINT ck_users_status        CHECK (status IN ('activo', 'baja')),
  CONSTRAINT ck_users_username_vacio CHECK (btrim(username) <> '')
);
COMMENT ON TABLE  users                   IS 'Cuentas: un alumno = un D.N.I. = una cuenta (RB-01/RB-16).';
COMMENT ON COLUMN users.password_hash     IS 'Hash Argon2id de la contraseña, nunca texto plano (RB-11).';
COMMENT ON COLUMN users.role              IS 'Rol: alumno | admin (comparativa, sección 11, fila 13).';
COMMENT ON COLUMN users.must_change_password IS 'true = obliga cambiar la contraseña en el primer ingreso (admin/admin, §2).';
COMMENT ON COLUMN users.status            IS 'Estado de negocio (activo | baja); no reemplaza al borrado lógico deleted_at.';

-- Un solo usuario vivo por username: un D.N.I. borrado no bloquea re-crearlo.
CREATE UNIQUE INDEX uq_usuario_username ON users (username) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_activa ON users (id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role   ON users (role) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_users_updated_at
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 3) students — ficha del alumno
-- ==============================================================================
CREATE TABLE students (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL,
  degree_id         uuid NOT NULL,
  dni               varchar(12) NOT NULL,
  first_name        varchar(80) NOT NULL,
  last_name         varchar(80) NOT NULL,
  phone             varchar(30),
  address           varchar(160),
  email             varchar(160),
  email_verified_at timestamptz,
  status            varchar(10) NOT NULL DEFAULT 'activo',
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz,
  deleted_at        timestamptz,
  CONSTRAINT fk_students_user   FOREIGN KEY (user_id)   REFERENCES users (id)   ON DELETE CASCADE,
  CONSTRAINT fk_students_degree FOREIGN KEY (degree_id) REFERENCES degrees (id) ON DELETE RESTRICT,
  CONSTRAINT ck_students_status CHECK (status IN ('activo', 'baja')),
  CONSTRAINT ck_students_dni    CHECK (dni ~ '^[0-9]{7,8}$'),
  CONSTRAINT ck_students_email  CHECK (email IS NULL OR position('@' IN email) > 1)
);
COMMENT ON TABLE  students                IS 'Ficha del alumno. El admin corrige D.N.I./nombre/apellido (RB-08).';
COMMENT ON COLUMN students.dni            IS 'D.N.I. sin puntos: único por alumno (RB-01).';
COMMENT ON COLUMN students.email_verified_at IS 'null = correo sin verificar: no se le envía código de recuperación (RB-07/RB-19).';
COMMENT ON COLUMN students.status         IS 'activo | baja (baja = cuenta desactivada, no borrada).';

CREATE UNIQUE INDEX uq_students_dni   ON students (dni)   WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX uq_students_email ON students (email) WHERE deleted_at IS NULL;
CREATE INDEX idx_students_degree ON students (degree_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_students_activa ON students (id)        WHERE deleted_at IS NULL;

CREATE TRIGGER trg_students_updated_at
  BEFORE INSERT OR UPDATE ON students
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 4) subjects — catálogo de materias (153 filas semilla)
-- ==============================================================================
CREATE TABLE subjects (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  degree_id  uuid NOT NULL,
  year       smallint NOT NULL,
  name       varchar(140) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz,
  deleted_at timestamptz,
  CONSTRAINT fk_subjects_degree    FOREIGN KEY (degree_id) REFERENCES degrees (id) ON DELETE RESTRICT,
  CONSTRAINT ck_subjects_year      CHECK (year >= 1 AND year <= 6),
  CONSTRAINT ck_subjects_name_vacia CHECK (btrim(name) <> '')
);
COMMENT ON TABLE  subjects     IS 'Catálogo de materias: 153 filas tomadas de data/materias.csv (§6).';
COMMENT ON COLUMN subjects.year IS 'Año de la tecnicatura: 1..6 (RB-02: el alumno solo ve las de su tecnicatura).';
COMMENT ON COLUMN subjects.name IS 'Nombre de la materia tal como se imprime en el permiso.';

-- Semilla: 153 filas.
-- psql> \copy subjects(degree_id, year, name) FROM 'data/materias.csv' WITH (FORMAT csv, HEADER true);

CREATE UNIQUE INDEX uq_subjects_grado_anio_nombre ON subjects (degree_id, year, name) WHERE deleted_at IS NULL;
CREATE INDEX idx_subjects_degree ON subjects (degree_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_subjects_activa ON subjects (id)        WHERE deleted_at IS NULL;

CREATE TRIGGER trg_subjects_updated_at
  BEFORE INSERT OR UPDATE ON subjects
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 5) mesas — UNA sola mesa por materia (D14, sin turnos)
-- ==============================================================================
CREATE TABLE mesas (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id             uuid NOT NULL,
  date                   date NOT NULL,
  time                   time NOT NULL,
  location               varchar(80),
  date_source            varchar(10) NOT NULL DEFAULT 'externa',
  external_ref           varchar(60),
  last_synced_at         timestamptz,
  registration_opens_at  timestamptz,
  registration_closes_at timestamptz,
  status                 varchar(10) NOT NULL DEFAULT 'abierta',
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz,
  deleted_at             timestamptz,
  CONSTRAINT fk_mesas_subject  FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE RESTRICT,
  CONSTRAINT ck_mesas_source   CHECK (date_source IN ('externa', 'manual')),
  CONSTRAINT ck_mesas_status   CHECK (status IN ('abierta', 'cerrada')),
  CONSTRAINT ck_mesas_ventana  CHECK (registration_closes_at IS NULL
                                       OR registration_opens_at IS NULL
                                       OR registration_closes_at > registration_opens_at)
);
COMMENT ON TABLE  mesas                     IS 'Mesa de examen: UNA por materia (D14). No existen turnos ni mesas duplicadas por condición.';
COMMENT ON COLUMN mesas.date                IS 'Fecha de la mesa; la asigna un sistema externo (RB-17/D11).';
COMMENT ON COLUMN mesas.time                IS 'Hora de inicio, formato "08:00".';
COMMENT ON COLUMN mesas.location            IS 'Lugar/aula: dato que el documento de análisis no tiene (comparativa §11 fila 15).';
COMMENT ON COLUMN mesas.date_source         IS 'externa = importada | manual = cargada o forzada por el admin (RB-17).';
COMMENT ON COLUMN mesas.external_ref        IS 'Referencia en el sistema externo que genera las fechas.';
COMMENT ON COLUMN mesas.registration_opens_at  IS 'Ventana de inscripción POR MESA (RB-12).';
COMMENT ON COLUMN mesas.registration_closes_at IS 'Cierre de la ventana de inscripción (RB-12).';

-- D14: no existen dos mesas para la misma materia.
CREATE UNIQUE INDEX uq_mesas_subject ON mesas (subject_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_mesas_date    ON mesas (date) WHERE deleted_at IS NULL;
CREATE INDEX idx_mesas_activa  ON mesas (id)   WHERE deleted_at IS NULL;

CREATE TRIGGER trg_mesas_updated_at
  BEFORE INSERT OR UPDATE ON mesas
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 6) enrollments — inscripción del alumno a una materia (D15: acá vive la
--    condición que elige el ALUMNO)
-- ==============================================================================
CREATE TABLE enrollments (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   uuid NOT NULL,
  subject_id   uuid NOT NULL,
  mesa_id      uuid NOT NULL,
  condition    varchar(20) NOT NULL DEFAULT 'regular',
  status       varchar(10) NOT NULL DEFAULT 'pendiente',
  requested_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  confirmed_by uuid,
  notes        varchar(300),
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz,
  deleted_at   timestamptz,
  CONSTRAINT fk_enrollments_student  FOREIGN KEY (student_id)   REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_enrollments_subject  FOREIGN KEY (subject_id)   REFERENCES subjects (id) ON DELETE RESTRICT,
  CONSTRAINT fk_enrollments_mesa     FOREIGN KEY (mesa_id)      REFERENCES mesas (id)    ON DELETE RESTRICT,
  CONSTRAINT fk_enrollments_confirmed_by FOREIGN KEY (confirmed_by) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT ck_enrollments_condition CHECK (condition IN ('regular', 'previa', 'completar_estudio', 'equivalencia')),
  CONSTRAINT ck_enrollments_status    CHECK (status IN ('pendiente', 'confirmada', 'anulada')),
  CONSTRAINT ck_enrollments_notas     CHECK (notes IS NULL OR length(notes) <= 300)
);
COMMENT ON TABLE  enrollments              IS 'Inscripción a materia. El alumno elige la MATERIA (no la mesa: mesa_id se deduce de subject_id) y SU condición.';
COMMENT ON COLUMN enrollments.mesa_id      IS 'Obligatoria y deducible de subject_id: se guarda para no romper la trazabilidad.';
COMMENT ON COLUMN enrollments.condition    IS 'D15: la elige el ALUMNO al inscribirse; una por materia, por defecto regular. El admin solo la corrige (§2).';
COMMENT ON COLUMN enrollments.status       IS 'pendiente | confirmada | anulada (RB-03: sin doble inscripción en la misma materia).';
COMMENT ON COLUMN enrollments.confirmed_by IS 'Admin que confirmó/corrigió la inscripción; SET NULL si se borra la cuenta.';
COMMENT ON COLUMN enrollments.notes        IS 'Motivo de anulación u observación (máx. 300 caracteres).';

-- RB-03: una sola inscripción activa por alumno y materia.
CREATE UNIQUE INDEX uq_enrollments_alumno_materia
  ON enrollments (student_id, subject_id)
  WHERE deleted_at IS NULL AND status <> 'anulada';
CREATE INDEX idx_enrollments_student ON enrollments (student_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_enrollments_subject ON enrollments (subject_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_enrollments_mesa    ON enrollments (mesa_id)    WHERE deleted_at IS NULL;
CREATE INDEX idx_enrollments_activa  ON enrollments (id)         WHERE deleted_at IS NULL;

CREATE TRIGGER trg_enrollments_updated_at
  BEFORE INSERT OR UPDATE ON enrollments
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 7) permits — Permiso de Examen (PDF, UNA copia por hoja)
-- ==============================================================================
CREATE TABLE permits (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   uuid NOT NULL,
  year         smallint NOT NULL,
  condition    varchar(20) NOT NULL,
  title_text   varchar(160) NOT NULL,
  libro        varchar(30),
  folio        varchar(30),
  pdf_url      varchar(300),
  checksum     varchar(64),
  generated_at timestamptz NOT NULL DEFAULT now(),
  generated_by uuid,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz,
  deleted_at   timestamptz,
  CONSTRAINT fk_permits_student    FOREIGN KEY (student_id)   REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_permits_generated  FOREIGN KEY (generated_by) REFERENCES users (id)   ON DELETE SET NULL,
  CONSTRAINT ck_permits_condition  CHECK (condition IN ('regular', 'previa', 'completar_estudio', 'equivalencia')),
  CONSTRAINT ck_permits_year       CHECK (year >= 2020 AND year <= 2100),
  CONSTRAINT ck_permits_libro      CHECK (libro IS NULL OR length(libro) <= 30),
  CONSTRAINT ck_permits_folio      CHECK (folio IS NULL OR length(folio) <= 30),
  CONSTRAINT ck_permits_checksum   CHECK (checksum IS NULL OR checksum ~ '^[0-9a-f]{64}$')
);
COMMENT ON TABLE  permits             IS 'Permiso de Examen emitido: 1 PDF por grupo de materias que comparten condición (RB-18).';
COMMENT ON COLUMN permits.condition   IS 'Condición del GRUPO (snapshot del impreso). RB-18: todas las materias DE ESTE permiso la comparten porque nacieron agrupadas; el título del PDF sale de acá.';
COMMENT ON COLUMN permits.title_text  IS '"PERMISO DE EXAMEN - Alumno <Condición>", dinámico (RB-18/D9).';
COMMENT ON COLUMN permits.libro       IS 'LIBRO: lo carga la escuela, no la app (RB-15). Máx. 30 caracteres.';
COMMENT ON COLUMN permits.folio       IS 'FOLIO: lo carga la escuela, no la app (RB-15). Máx. 30 caracteres.';
COMMENT ON COLUMN permits.pdf_url     IS 'Ubicación del PDF guardado; se puede re-descargar (RB-09).';
COMMENT ON COLUMN permits.checksum    IS 'SHA-256 en hex del PDF, para verificar que no se alteró.';
COMMENT ON COLUMN permits.generated_by IS 'Usuario que disparó la generación; SET NULL si se borra la cuenta.';
-- RB-13: el formulario tiene 6 filas => máximo 6 filas de materias por permiso.
-- RB-14: el PDF es un borrador: solo vale con la firma manuscrita del Secretario.

CREATE INDEX idx_permits_student  ON permits (student_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_permits_generated ON permits (generated_by) WHERE deleted_at IS NULL;
CREATE INDEX idx_permits_activa   ON permits (id)         WHERE deleted_at IS NULL;

CREATE TRIGGER trg_permits_updated_at
  BEFORE INSERT OR UPDATE ON permits
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 8) permit_enrollments — junction: qué materias lleva cada permiso
--    PK compuesta y SIN timestamps: en una junction o existe la fila o no
--    (convención junction de analisis.txt 1.9 / comparativa §2.3).
--    Reemplaza al arreglo enrollment_ids[] de la versión anterior, que no era
--    una FK real.
-- ==============================================================================
CREATE TABLE permit_enrollments (
  permit_id     uuid NOT NULL,
  enrollment_id uuid NOT NULL,
  CONSTRAINT pk_permit_enrollments PRIMARY KEY (permit_id, enrollment_id),
  CONSTRAINT fk_permit_enrollments_permit     FOREIGN KEY (permit_id)     REFERENCES permits (id)     ON DELETE CASCADE,
  CONSTRAINT fk_permit_enrollments_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE
);

CREATE INDEX idx_permit_enrollments_enrollment ON permit_enrollments (enrollment_id);

-- ==============================================================================
-- 9) password_resets — código de recuperación y de verificación de correo
-- ==============================================================================
CREATE TABLE password_resets (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL,
  purpose    varchar(20) NOT NULL,
  token      varchar(120) NOT NULL,
  sent_to    varchar(160) NOT NULL,
  attempts   smallint NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL,
  used_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz,
  deleted_at timestamptz,
  CONSTRAINT fk_password_resets_user   FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT ck_password_resets_purpose CHECK (purpose IN ('reset_password', 'verify_email')),
  CONSTRAINT ck_password_resets_attempts CHECK (attempts >= 0 AND attempts <= 5),
  CONSTRAINT ck_password_resets_token  CHECK (btrim(token) <> '')
);
COMMENT ON TABLE  password_resets         IS 'Código de 6 dígitos (guardado hasheado). RB-07/RB-19: un solo uso, expira en 15 min, 5 intentos y se bloquea 15 min.';
COMMENT ON COLUMN password_resets.purpose IS 'reset_password = recuperar acceso | verify_email = verificar el correo del alumno.';
COMMENT ON COLUMN password_resets.sent_to IS 'Correo destino (el de la ficha del alumno).';
COMMENT ON COLUMN password_resets.attempts IS 'Intentos de ingreso del código: máx. 5.';
COMMENT ON COLUMN password_resets.expires_at IS 'Vence 15 minutos después de enviado.';
COMMENT ON COLUMN password_resets.used_at IS 'No nulo = código consumido (reenviar invalida el anterior).';
-- Aunque es un artefacto de un solo uso, se conservan created_at / updated_at /
-- deleted_at + trigger para no romper la convención única del esquema
-- (analisis.txt 1.4–1.9): el borrado lógico archiva códigos vencidos sin
-- perder la trazabilidad.

-- RB-19/RB-07: un solo código ACTIVO por usuario y propósito.
CREATE UNIQUE INDEX uq_password_resets_activo ON password_resets (user_id, purpose) WHERE used_at IS NULL;
CREATE INDEX idx_password_resets_user    ON password_resets (user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_password_resets_expires ON password_resets (expires_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_password_resets_activa  ON password_resets (id)        WHERE deleted_at IS NULL;

CREATE TRIGGER trg_password_resets_updated_at
  BEFORE INSERT OR UPDATE ON password_resets
  FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- ==============================================================================
-- 10) audit_log — trazabilidad de acciones del admin (RB-10)
--     APPEND-ONLY: SIN updated_at / deleted_at y SIN trigger. Solo se INSERTA;
--     modificar o borrar una fila de auditoría anularía su valor de prueba.
-- ==============================================================================
CREATE TABLE audit_log (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id  uuid,
  action         varchar(60) NOT NULL,
  entity         varchar(60) NOT NULL,
  entity_id      uuid,
  before         jsonb,
  after          jsonb,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT fk_audit_log_actor   FOREIGN KEY (actor_user_id) REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT ck_audit_log_action  CHECK (btrim(action) <> ''),
  CONSTRAINT ck_audit_log_entity  CHECK (btrim(entity) <> ''),
  CONSTRAINT ck_audit_log_before_after CHECK (before IS NULL OR jsonb_typeof(before) = 'object'),
  CONSTRAINT ck_audit_log_after_obj    CHECK (after  IS NULL OR jsonb_typeof(after)  = 'object')
);
COMMENT ON TABLE  audit_log                IS 'Bitácora append-only de toda acción del admin (RB-10).';
COMMENT ON COLUMN audit_log.actor_user_id  IS 'Autor de la acción; SET NULL si el usuario se borra (la acción queda registrada).';
COMMENT ON COLUMN audit_log.action         IS 'Acción, ej.: inscripcion.anular, permiso.regenerar.';
COMMENT ON COLUMN audit_log.entity         IS 'Entidad afectada, ej.: enrollments, permits.';
COMMENT ON COLUMN audit_log.before         IS 'Estado previo (jsonb) de la entidad editada.';
COMMENT ON COLUMN audit_log.after          IS 'Estado nuevo (jsonb) de la entidad editada.';

CREATE INDEX idx_audit_log_actor   ON audit_log (actor_user_id);
CREATE INDEX idx_audit_log_entity  ON audit_log (entity, entity_id);
CREATE INDEX idx_audit_log_created ON audit_log (created_at);

-- ==============================================================================
-- Semilla: las 2 tecnicaturas (nombres tomados de data/materias.csv).
-- El seed de admin/admin queda PENDIENTE (PD-03 de la comparativa: "Alta
-- inicial de roles y usuarios administradores"; por ahora se decide a mano
-- con cambio obligatorio en el primer ingreso, §2 de diseno.md).
-- ==============================================================================
INSERT INTO degrees (name)
VALUES ('TECNOLOGÍA DE LOS ALIMENTOS'),
       ('GESTIÓN ORGANIZACIONAL')
ON CONFLICT (name) WHERE deleted_at IS NULL DO NOTHING;
