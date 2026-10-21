#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera el PDF del Permiso de Examen de la E.P.E.T. N° 36 sobre la PLANTILLA.

La plantilla es el PDF que entregó la escuela:
    ``Permiso de examen alumno 2026 - A4 - nuevo modelo.pdf``

El archivo NO se redibuja: se usa tal cual y solo se le hacen dos cambios
mínimos, ambos del mismo tipo (se apaga un texto y se escribe otro encima):

  1. se **vacia el texto** de los bloques que hay que reescribir
     (título, las opciones de condición, las dos líneas del párrafo con
     guiones, la línea de fecha y las copias 2 y 3 enteras). El texto viejo
     no queda oculto bajo un rectángulo blanco: **desaparece del stream**,
     así que no se puede recuperar seleccionándolo ni imprimiéndolo. El
     rótulo "Condición" y su subrayado se conservan originales;
  2. se dibuja un overlay con los valores rellenables: nombre, DNI, año,
     tecnicatura, condición, fecha de emisión y las celdas
     ASIGNATURA / FECHA (esas celdas están vacías en la plantilla).

El único blanco que se pinta tapa las líneas de las copias 2 y 3 (son
trazado vectorial, no texto). Todo lo demás — logo, encabezados, párrafo,
nota, firma y todo el trazado — son bytes originales de la plantilla.
"""

import csv
import os
import re
import sys
from datetime import date
from io import BytesIO

from reportlab.lib.colors import black, white
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfgen import canvas
from pypdf import PdfReader, PdfWriter
from pypdf.generic import DecodedStreamObject

# --------------------------------------------------------------------------
# Fuentes
# --------------------------------------------------------------------------
# La plantilla usa Arial-BoldMT: Helvetica-Bold es métricamente idéntico,
# así que los textos nuevos calzan en el mismo ancho que los originales.
FONT = "Helvetica-Bold"

# El separador de condiciones de la plantilla no es una letra "o": es un glifo
# Wingdings (GID 134) que es un CUADRADO HUECO de 1480x1480 sobre 2048 upem,
# apoyado sobre la línea de base. reportlab no puede embeberlo, así que se
# dibuja como rectángulo vectorial con las mismas métricas.
BOX_LADO = 1480.0 / 2048.0       # lado, en em
BOX_X = 173.0 / 2048.0           # side bearing izquierdo, en em
BOX_AVANCE = 1911.0 / 2048.0     # ancho de avance, en em

# --------------------------------------------------------------------------
# Constantes de la plantilla (medidas sobre el PDF original)
# --------------------------------------------------------------------------
ANCHO_HOJA, ALTO_HOJA = 612, 792

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLANTILLA_DEFECTO = os.path.join(
    BASE, "Permiso de examen alumno 2026 - A4 - nuevo modelo.pdf")

CONDICIONES = {
    "regular": ("REGULAR", "Regular"),
    "previa": ("PREVIAS", "Previas"),
    "completar_estudio": ("COMPLETAR ESTUDIO", "Completar Estudio"),
    "equivalencia": ("EQUIVALENCIA", "Equivalencia"),
}

MAX_MATERIAS = 6  # RB-13

MESES = (
    "enero febrero marzo abril mayo junio "
    "julio agosto septiembre octubre noviembre diciembre"
).split()

COL_ASIG = (368.5, 437.8)
COL_FECHA = (437.8, 472.4)
FILAS_Y = (668.6, 652.4, 636.1, 620.0, 603.8, 587.5)

# --------------------------------------------------------------------------
# Purga del stream de contenido de la plantilla
# --------------------------------------------------------------------------
# Corte vertical: todo lo que está por debajo de COPIAS_ABAJO pertenece a las
# copias 2 y 3. La primera copia no tiene ni un solo bloque de texto por
# debajo de y=522 (su última línea es la nota, en y=535.7).
COPIAS_ABAJO = 522.0

# Bandas de la copia 1 cuyo texto fijo hay que reescribir: (y_min, y_max, x_max).
BANDAS_A_VACIAR = (
    (745.0, 753.0, 612.0),    # título
    (626.0, 629.0, 612.0),    # párrafo, línea 3 (el año)
    (614.0, 617.0, 612.0),    # párrafo, línea 4 (la tecnicatura)
    (566.0, 570.0, 612.0),    # línea de fecha
)

# Celda de Condición: se vacía entera menos el rótulo "Condición", que se
# conserva byte a byte (y con él su subrayado). A la derecha de COND_X_MAX
# están las cabeceras de la tabla (N°, LIBRO, FOLIO…), que no se tocan.
COND_Y = (679.0, 712.0)
COND_X_MAX = 265.0
COND_Y_ROTULO = (697.0, 698.0)
COND_X_ROTULO = 47.0        # el rótulo ocupa x = 19..48

# Sustituyen al "mostrar texto" por nada: se conservan Tm, Tf, Tc, Tr, g y Q
# (el resto del stream depende de ese estado), pero no se pinta un solo glifo.
_OPERADOR_TJ = re.compile(r"\[(?:[^[\]\\]|\\.)*\](\s*TJ)")
_OPERADOR_Tj = re.compile(r"\((?:[^()\\]|\\.)*\)(\s*Tj)")


def _hay_que_vaciar(x, y):
    if y < COPIAS_ABAJO:
        return True
    if COND_Y[0] <= y <= COND_Y[1]:
        if x >= COND_X_MAX:
            return False
        if COND_Y_ROTULO[0] <= y <= COND_Y_ROTULO[1] and x < COND_X_ROTULO:
            return False
        return True
    return any(lo <= y <= hi and x <= xmax
               for lo, hi, xmax in BANDAS_A_VACIAR)


def _vaciar_texto(datos):
    """Deja vacíos los bloques BT..ET que la plantilla trae fijos.

    Devuelve los mismos bytes con esos bloques sin glifos. Nunca borra
    operadores: solo vacía la cadena que se muestra.
    """
    origen = datos.decode("latin-1")
    salida = []
    pos = 0
    for m in re.finditer(r"BT(.*?)ET", origen, re.S):
        bloque = m.group(0)
        tm = re.search(r"1 0 0 1 (-?[\d.]+) (-?[\d.]+) Tm", bloque)
        if tm and _hay_que_vaciar(float(tm.group(1)), float(tm.group(2))):
            bloque = _OPERADOR_TJ.sub(lambda g: "[]" + g.group(1), bloque)
            bloque = _OPERADOR_Tj.sub(lambda g: "()" + g.group(1), bloque)
        salida.append(origen[pos:m.start()])
        salida.append(bloque)
        pos = m.end()
    salida.append(origen[pos:])
    return "".join(salida).encode("latin-1")


# Rectángulos a blanquear: (x, y, ancho, alto). Solo quedan trazados; el texto
# ya se vació arriba. El corte va hasta 520.4 para no tocar el borde inferior
# de la copia 1 (18, 520.53, 550.2, 1); el segundo rectángulo saca el resto
# del marco de la copia 2 que se asoma por encima (x=17..18, hasta y=521.53).
BLANQUEOS = (
    (0.0, 0.0, 612.0, 520.4),
    (17.0, 520.4, 1.0, 1.2),
)


# --------------------------------------------------------------------------
# Utilidades de dibujo (solo sobre el overlay)
# --------------------------------------------------------------------------
def _ajustar_fs(texto, fs, ancho_max, fs_min=3.5):
    while fs > fs_min and pdfmetrics.stringWidth(texto, FONT, fs) > ancho_max:
        fs -= 0.1
    return fs


def _fs_uniforme(textos, fs, ancho_max, fs_min=4.0):
    peor = max(pdfmetrics.stringWidth(t, FONT, fs) for t in textos)
    if peor <= ancho_max:
        return fs
    return max(fs_min, fs * ancho_max / peor)


def _centrado(c, x0, x1, y, texto, fs, ancho_interno=4.0):
    fs = _ajustar_fs(texto, fs, (x1 - x0) - ancho_interno)
    c.setFont(FONT, fs)
    c.drawCentredString((x0 + x1) / 2.0, y, texto)


def _izq(c, x, y, texto, fs, ancho_max, fs_min=3.5):
    fs = _ajustar_fs(texto, fs, ancho_max, fs_min)
    c.setFont(FONT, fs)
    c.drawString(x, y, texto)


def _condicion_piezas(etiquetas):
    """Fragmentos de la línea de condición: texto + casilla tras cada opción.

    Empieza en X_CONDICION, que es justo donde la plantilla pone la dos
    puntos: el rótulo "Condición" se conserva original y no se redibuja.
    """
    piezas = [("t", ": " + etiquetas[0], 0),
              ("t", " ", None),
              ("b", "", 0)]
    for i in range(1, len(etiquetas)):
        piezas.append(("t", "   - ", None))
        piezas.append(("t", etiquetas[i], i))
        piezas.append(("t", " ", None))
        piezas.append(("b", "", i))
    return piezas


X_CONDICION = 48.0           # fin del rótulo "Condición" en la plantilla
Y_CONDICION = 697.4          # línea de base de toda la fila


# --------------------------------------------------------------------------
# Overlay
# --------------------------------------------------------------------------
def _blanquear(c):
    c.setFillColor(white)
    c.setStrokeColor(white)
    for x, y, w, h in BLANQUEOS:
        c.rect(x, y, w, h, stroke=0, fill=1)
    c.setFillColor(black)
    c.setStrokeColor(black)


def _titulo(c, condicion):
    texto = "PERMISO DE EXAMEN - Alumno %s" % CONDICIONES[condicion][1]
    fs = _ajustar_fs(texto, 10.8, 514.0 - 54.0)
    c.setFont(FONT, fs)
    c.drawCentredString(284.35, 749.0, texto)


def _datos_alumno(c, alumno, dni):
    if alumno:
        _izq(c, 125.6, 724.0, alumno, 6.6, 333.9 - 125.6 - 2.0)
    if dni:
        _izq(c, 373.1, 723.0, dni, 6.6, 516.4 - 373.1 - 2.0)


def _condicion(c, clave):
    etiquetas = [CONDICIONES[k][0] for k in CONDICIONES]
    activo = list(CONDICIONES).index(clave)

    disponible = 264.4 - X_CONDICION
    ancho = sum(
        (pdfmetrics.stringWidth(t, FONT, 6.0) if k == "t" else 6.0 * BOX_AVANCE)
        for k, t, _ in _condicion_piezas(etiquetas))
    fs = 6.0 if ancho <= disponible else max(4.4, 6.0 * disponible / ancho)

    y, x = Y_CONDICION, X_CONDICION
    for kind, texto, indice in _condicion_piezas(etiquetas):
        if kind == "b":
            lado = fs * BOX_LADO
            bx = x + fs * BOX_X
            c.setLineWidth(max(0.35, fs * 0.09))
            if indice == activo:
                c.rect(bx, y, lado, lado, stroke=1, fill=1)
            else:
                c.rect(bx, y, lado, lado, stroke=1, fill=0)
            x += fs * BOX_AVANCE
        else:
            c.setFont(FONT, fs)
            c.drawString(x, y, texto)
            x += pdfmetrics.stringWidth(texto, FONT, fs)

    # El rótulo "Condición" y su subrayado no se tocan: son bytes originales.


def _parrafo(c, anio, carrera):
    """Reescribe solo las líneas 3 y 4 (las únicas con guiones)."""
    lineas = [
        (627.4, "correspondientes a: %s° año de" % anio),
        (615.4, "%s, que se indican a" % carrera),
    ]
    fs = _fs_uniforme([t for _, t in lineas], 9.8, 264.4 - 19.4)
    for y, texto in lineas:
        c.setFont(FONT, fs)
        c.drawString(19.4, y, texto)


def _fecha_emision(c, fecha):
    fecha = fecha or date.today()
    texto = "%d de %s de %d." % (fecha.day, MESES[fecha.month - 1], fecha.year)
    _izq(c, 19.2, 568.0, texto, 8.6, 567.2 - 19.2 - 2.0)


def _tabla(c, materias):
    for i, y in enumerate(FILAS_Y):
        if i >= len(materias):
            continue
        item = materias[i]
        _centrado(c, *COL_ASIG, y, item["nombre"], 6.6, 1.5)
        _centrado(c, *COL_FECHA, y, item.get("fecha", ""), 6.6, 1.5)


def _construir_overlay(alumno, dni, condicion, carrera, anio, materias,
                       fecha_emision):
    buf = BytesIO()
    c = canvas.Canvas(buf, pagesize=(ANCHO_HOJA, ALTO_HOJA))
    c.setFillColor(black)
    c.setStrokeColor(black)

    _blanquear(c)
    _titulo(c, condicion)
    _datos_alumno(c, alumno, dni)
    _condicion(c, condicion)
    _parrafo(c, anio, carrera)
    _fecha_emision(c, fecha_emision)
    _tabla(c, materias)

    c.showPage()
    c.save()
    buf.seek(0)
    return buf


# --------------------------------------------------------------------------
# API pública
# --------------------------------------------------------------------------
def generar_permiso(path_salida, *, alumno, dni, condicion, carrera, anio,
                    materias, fecha_emision=None, plantilla=None):
    """Completa la plantilla con los datos del alumno y devuelve la ruta."""
    if condicion not in CONDICIONES:
        raise ValueError(
            "condicion invalida: %r (esperado: %s)"
            % (condicion, ", ".join(sorted(CONDICIONES))))
    if not str(alumno or "").strip():
        raise ValueError("alumno vacio")
    if not str(dni or "").strip():
        raise ValueError("dni vacio")
    if not str(carrera or "").strip():
        raise ValueError("carrera vacia")
    materias = list(materias or [])
    if len(materias) > MAX_MATERIAS:
        raise ValueError(
            "RB-13: maximo %d materias por permiso, recibidas %d"
            % (MAX_MATERIAS, len(materias)))

    plantilla = plantilla or PLANTILLA_DEFECTO
    if not os.path.exists(plantilla):
        raise FileNotFoundError("no se encuentra la plantilla: %s" % plantilla)

    overlay = _construir_overlay(
        str(alumno).strip(), str(dni).strip(), condicion,
        str(carrera).strip(), anio, materias, fecha_emision)

    # clone_from deja la página asignada al writer: replace_contents solo es
    # fiable en páginas con escritorio (pypdf 7 lo exige).
    writer = PdfWriter(clone_from=plantilla)
    pagina = writer.pages[0]
    limpio = DecodedStreamObject()
    limpio.set_data(_vaciar_texto(pagina.get_contents().get_data()))
    pagina.replace_contents(limpio)
    pagina.merge_page(PdfReader(overlay).pages[0])

    writer.add_metadata({
        "/Title": "PERMISO DE EXAMEN - Alumno %s" % CONDICIONES[condicion][1],
        "/Author": "E.P.E.T. N° 36 - Posadas, Misiones",
        "/Subject": "Permiso de Examen",
    })
    with open(path_salida, "wb") as fh:
        writer.write(fh)
    return path_salida


def _muestra():
    """Genera docs/muestras/permiso-muestra.pdf con datos reales del catálogo."""
    csv_path = os.path.join(BASE, "data", "materias.csv")
    salida = os.path.join(BASE, "docs", "muestras", "permiso-muestra.pdf")

    carrera, anio = "GESTIÓN ORGANIZACIONAL", "3"
    with open(csv_path, encoding="utf-8-sig", newline="") as fh:
        filas = [r for r in csv.DictReader(fh)
                 if r["tecnicatura"] == carrera and r["anio"] == anio]

    fechas = ("03/11/2026 05/11/2026 10/11/2026 "
              "12/11/2026 17/11/2026 19/11/2026").split()
    materias = [{"nombre": f["materia"], "fecha": fechas[i]}
                for i, f in enumerate(filas[:MAX_MATERIAS])]

    generar_permiso(
        salida,
        alumno="PÉREZ, MARÍA SOLEDAD",
        dni="38.456.789",
        condicion="regular",
        carrera=carrera,
        anio=anio,
        materias=materias,
    )
    return salida


if __name__ == "__main__":
    destino = sys.argv[1] if len(sys.argv) > 1 else _muestra()
    print(destino)
