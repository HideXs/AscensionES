# 🩺 Herramienta de diagnóstico — AscensionES

¿El addon **no aparece en tu lista de AddOns** o no traduce tras actualizar? Esta
herramienta comprueba en 5 segundos las causas más comunes y genera un informe
para que podamos ayudarte.

## Cómo usarla

1. Descarga **`Diagnostico_AscensionES.bat`** (desde [Releases](../../releases) o
   [directamente aquí](Diagnostico_AscensionES.bat) → botón *Download raw file*).
2. Guárdalo **dentro de tu carpeta `Interface\AddOns`** del juego
   (normalmente `...\Ascension\Launcher\resources\ascension-live\Interface\AddOns\`),
   al lado de la carpeta `AscensionES` — **no dentro de ella**.
3. Haz **doble clic** y espera a que termine.
4. Haz una **captura de toda la ventana** y pégala en una
   [Issue](../../issues/new/choose) o en el hilo de Discord.

## Así se ve un informe SANO

```text
============================================
 Diagnostico AscensionES - pega una captura
 de esta ventana en el Discord
============================================
[1] Carpeta donde se ejecuta: J:\Ascension\Launcher\resources\ascension-live\Interface\AddOns

[2] AscensionES\AscensionES.toc : EXISTE
    tamano: 556 bytes | fecha: 15/07/2026 04:08 AM

[3] Primeras lineas del .toc:
    1:## Interface: 30300
    2:## Title: AscensionES |cff33ff99español|r
    3:## Notes: Traducción al español de hechizos, talentos, objetos y NPCs para Ascension (Conquest of Azeroth)
    4:## Author: HideXs
    5:## Version: 1.0.6
    6:## SavedVariables: AscensionESDB

[4] Contenido de la carpeta AscensionES:
15/07/2026  04:08 AM               556 AscensionES.toc
15/07/2026  01:35 AM             3.468 Chat.lua
15/07/2026  04:05 AM            93.167 Core.lua
15/07/2026  02:30 AM    <DIR>          data
13/07/2026  04:37 PM             2.244 Errors.lua
13/07/2026  04:12 PM    <DIR>          sounds
13/07/2026  04:14 PM             4.553 Voice.lua
                5 archivos         103.988 bytes

[5] Numero de .lua en data:
15

[6] Ruta del juego detectada al lado (Ascension.exe):
    OK: esta es la carpeta AddOns del juego

[7] Busqueda de copias/duplicados en AddOns:
    OK: sin duplicados ni copias
```

## Qué significa cada aviso

| Punto | Si sale mal | Solución |
|---|---|---|
| **[2] NO EXISTE** | El `.toc` no está (extracción incompleta o antivirus) | Vuelve a extraer el zip; añade la carpeta a las exclusiones del antivirus |
| **[3] líneas raras** | `.toc` corrupto | Reinstala desde el zip oficial |
| **[5] menos de 15** | Faltan archivos de datos | Borra la carpeta `AscensionES` y extrae el zip de nuevo |
| **[6] OJO: no está Ascension.exe** | **La causa más común**: has puesto el addon en una carpeta que NO es la del juego (instalación vieja, copia, otra ruta) | Busca la instalación real: la carpeta correcta contiene `Ascension.exe` dos niveles más arriba |
| **[7] DUPLICADO** | Hay otra carpeta con el addon dentro (`AscensionES (1)`, `AscensionES - copia`…) de extraer varias veces | Borra las copias y deja UNA sola carpeta llamada exactamente `AscensionES` |

Y siempre: actualiza con el **juego cerrado** y comprueba que la ruta final sea
`...\Interface\AddOns\AscensionES\AscensionES.toc` (sin carpetas de versión intermedias).
