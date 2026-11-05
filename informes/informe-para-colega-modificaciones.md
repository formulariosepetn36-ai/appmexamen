# Informe de modificaciones pendientes — para el colega

**Para:** colega (backend)  
**De:** equipo frontend / prototipo  
**Fecha:** 2026-10-27  
**Rama evaluada:** `main` @ `6018204` (GitHub) / `feat/sdd-3-mesas` @ `7a1370d`  
**Asunto:** Modificaciones pendientes tras auditoría y correcciones F1/F2  

> **Corrección 2026-11-02:** actualizado contra el estado real de GitHub y la devolución `informe-devolucion-colega-sdd4.md` — sdd-3/sdd-4 ya están pushadas (falta PR), `18fc09f` descartado, F3 sigue abierto.

---

## Resumen ejecutivo

El fix **F1 (upsert RB-13)** y **F2 (code 422 `validacion`)** está aplicado en `feat/sdd-3-mesas` @ `7a1370d` (ya en el remoto) y verificado: 181 tests pasando, ruff limpio (según la devolución del 2026-10-31). Nuestra copia local equivalente (`18fc09f`) fue descartada para no duplicar.

Estado de las tres acciones (actualizado 2026-11-02):

1. ~~Subir su rama `feat/sdd-3-mesas` a remoto~~ — **hecho**: `feat/sdd-3-mesas` y `feat/sdd-4-inscripciones` están en GitHub. **Falta abrir los PR** para integrarlas a `main`.
2. **Cerrar F3 — rate limit de la landing** (mecanismo por IP + umbral NFR-008, aún en evaluación interna) — sigue pendiente.
3. ~~Reconciliar ramas~~ — **hecho de nuestro lado**: descartamos `18fc09f` y queda `7a1370d` como fix canónico (método §3 de la devolución).

---

## Qué debe modificar el colega

### 1. Integrar las ramas a `main` (abrir PR)

`feat/sdd-3-mesas` (7 commits, hasta 30/10) y `feat/sdd-4-inscripciones` (14 commits, hasta 31/10, hereda sdd-3) **ya están en el remoto** (verificado 2026-11-02), pero **no tienen PR** y no están mergeadas: `main` sigue en el PR #4 (SDD-2). Falta abrir los PR y mergearlos.

### 2. Cerrar F3 — Rate limit de la landing (pendiente de su decisión interna)

La obligación de rate limit está cerrada en las fuentes (§2.9, §6), pero faltan dos decisiones de su equipo:

- **Mecanismo:** por IP (la landing es anónima, no hay usuario a quién contarle los intentos).
- **Umbral numérico:** NFR-008 está `[POR DEFINIR]`. Debe elegir cuántos requests por ventana de tiempo se permiten antes de devolver `429`.

Una vez decida e implemente, avise al equipo para que la landing pueda programar defensivamente la rama de 429.

### 3. Reconciliar ramas — resuelto

El duplicado quedó cerrado (2026-11-02):
- Fix canónico: `feat/sdd-3-mesas` @ `7a1370d` (en el remoto) — su parche es superset (incluye el fix en `service_convocatoria` y los tests de ventanas).
- Nuestra copia `18fc09f` (rama `feat/sdd-2-sigme-base` local) **fue descartada**; la rama local ahora coincide con el remoto.

No queda ningún fix duplicado pendiente.

---

## Contrato final para la landing (ya acordado)

```
POST /api/v1/preinscripcion/   (público, sin token)
Body:  { nombre_alumno, documento, fecha_nacimiento, orientacion, nombre_tutor, email }
Query: utm_source, utm_medium, utm_campaign (opcional)

Respuesta   Cuerpo
201 Created {"accion": "creada"}
200 OK      {"accion": "actualizada"} — reenvío seguro, nunca 409 por duplicado
409 Conflict {"code": "ventana-cerrada"} — sólo ventana cerrada
422         {"code": "validacion", "errors": [{"field", "message"}]}
429         Pendiente (F3); hasta entonces inalcanzable
```

**Nota:** el path es `/api/v1/preinscripcion/` (no `/api/v1/landing/preinscripcion/` como decía el informe inicial).

---

## Qué NO debe modificar

- **No rehaga F1 ni F2:** ya están aplicados y verificados (181 tests, ruff limpio según la devolución sdd4).
- **No toque el prototipo HTML ni la maqueta de la landing:** eso es responsabilidad del equipo frontend/prototipo; el backend ya expone el endpoint.
- **No cambie el cuerpo de respuesta 201/200:** debe seguir siendo `{"accion": ...}` según §6 y doc 11 §11.4.3.

---

## Próximos pasos del proyecto (una vez cerrado F3)

1. Conectar la maqueta al backend (tarea 2, solo lectura) usando el contrato de `POST /api/v1/preinscripcion/`.
2. Dividir el panel admin (OpenPencil) en vistas separadas: Alumnos, Inscripciones, Mesas, Permisos, Usuarios.
3. Tomar decisión sobre el registro de alumnos (pantalla 3 del prototipo) — sigue pendiente.
4. Abrir los PR de `feat/sdd-3-mesas` y `feat/sdd-4-inscripciones` para integrarlas a `main`.

---

## Firma

Rama de referencia: `main` @ `6018204`; fix canónico en `feat/sdd-3-mesas` @ `7a1370d`  
Pruebas: 181 passed, ruff limpio (según devolución sdd4)  
Informe relacionado: `informes\informe-fix-landing-colega.md`