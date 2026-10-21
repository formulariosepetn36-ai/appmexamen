# Engram: sesión cerrada bloquea todas las escrituras (diagnóstico)

Fecha: 2026-10-15. Estado: causa raíz identificada y verificada con evidencia.

## Síntoma

Cualquier escritura a memoria (`mem_save`, `mem_update`, `mem_session_summary`) falla con:

```
gentle-engram could not confirm Engram session registration for <tool>;
verify that the Engram server is available and accepting requests
```

Las LECTURAS (`mem_current_project`, `mem_search`, `mem_context`, `mem_doctor`,
`mem_get_observation`) funcionan sin problema. `mem_doctor` reporta el store sano
(10/10 checks OK). Es decir: el store está bien y las lecturas andan porque van por
MCP directo (stdio) y no pasan por el gate del plugin.

## Causa raíz

El plugin de Engram (hook `tool.execute.before` para las herramientas atribuidas a
sesión) exige registrar la sesión antes de escribir. La llamada que hace
(`POST /sessions`) devuelve **409 `session_already_ended`** para la sesión del TUI:

```
POST /sessions ses_f183ac08effesCNGhYXBPS7anj
 -> 409 {"code":"session_already_ended","error":"session has already ended"}

GET /sessions/ses_f183ac08effesCNGhYXBPS7anj
 -> started_at 2026-09-28 11:27:39   ended_at 2026-10-15 22:34:01
```

Cadena causal completa:

1. La sesión del TUI `ses_f183ac08effesCNGhYXBPS7anj` viene viva desde el 28/09
   (24 observaciones guardadas en ese período: las escrituras funcionaban).
2. El 2026-10-15 a las 22:34 UTC (19:34 local) se **cerró esa sesión en Engram**:
   `POST /sessions/{id}/end`. Lo dispara el `dispose()` del plugin (que llama a
   `closeKnownSession`) al recargarse los plugins — en este caso por el reinicio de
   OpenCode al configurar el provider NVIDIA (auth.json).
3. OpenCode se reinició y **reanudó el MISMO session id**.
4. El plugin intenta re-registrarlo → el server responde 409 → `engramFetch` devuelve
   `null` (non-2xx) → `ensureSession()` = `false` → throw. Y como el id reanudado es
   siempre el mismo, la falla es **permanente para esa sesión**: no se recupera sola.

Descartado con evidencia (no es esto):

- El server responde: `GET /health` 200, `GET /project/current` 200 (project
  `git_remote`), `GET /observations` 200, `GET /context/compaction` 200,
  `POST /observations/passive` 200, `POST /sessions` 201 para ids nuevos.
- La base no está corrupta (`mem_doctor` 10/10).
- No es desalineación de versiones en el camino de escritura: el plugin spawnea
  `D:\progamacion\bin\engram.exe` (v2.2.1) y el MCP del PATH es v3.4.0, pero todos los
  endpoints que usa el plugin responden bien en 2.2.1. Ambos binarios comparten
  instance-id `49b0856f33430741bf9bc81ce49d7cbf` y el server vivo del puerto 7437 es
  el 2.2.1.

## Solución

Inmediata (no requiere tocar nada):

1. Abrir una **sesión NUEVA** en OpenCode (nuevo session id) → se registra con 201 y
   las escrituras vuelven a funcionar al instante.
2. Reiniciar OpenCode **no alcanza por sí solo** si el TUI reanuda el id viejo
   `ses_f183ac08...`: ese id está cerrado en Engram y el server lo rechaza siempre.
   Hay que forzar sesión nueva (o dejar que el TUI no reanude esa).

Paliativo para esa sesión ya cerrada: el id existe en la base (GET 200), así que se
puede seguir guardando por HTTP directo mientras se decide la solución de fondo.

De fondo (dos frentes, sin aplicar todavía):

- Defecto del plugin: no contempla el 409 `session_already_ended` (debería reabrir la
  sesión o emitir un id nuevo en lugar de bloquear toda escritura con un mensaje que
  culpa al server). Además `dispose()` cierra sesiones que luego se reanudan.
- Higiene de entorno: alinear el binario que spawnea el plugin con el del MCP
  (`setx ENGRAM_BIN "C:\Users\Estudiante\AppData\Local\engram\bin\engram.exe"`, o
  actualizar `D:\progamacion\bin\engram.exe` a 3.4.0). Si el server viejo ya está
  escuchando en 7437 con el mismo instance-id, el plugin lo reutiliza y no va a
  spawnear el nuevo: hay que cerrarlo para que levante el 3.4.0.

## Riesgo aparte detectado

El prompt pegado en el chat con la API key de NVIDIA quedó guardado **en texto plano**
en la base de Engram (tabla de prompts, y la observación #35 "Configured NVIDIA
provider in OpenCode auth.json"). No está en git (`<repo>/.engram/` no existe), pero
está en el SQLite local. Conviene **rotar esa clave**.

## Cómo verificar que quedó resuelto

Después de abrir una sesión nueva (o de aplicar un fix), una escritura simple:
`mem_save` de prueba → debe devolver un id de observación, no el mensaje de error.
Chequeo directo del server, sin plugin:

```
POST http://127.0.0.1:7437/sessions   {"id":"<session id>","project":"<proyecto>","directory":"<cwd>"}
  201 = registrada / 409 = cerrada (es el caso que rompe todo)
```

Scripts de diagnóstico de esta sesión: `%TEMP%\opencode\diag_engram.py`,
`diag_engram2.py`, `diag_engram3.py`, `diag_engram4.py`.
