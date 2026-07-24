# AscensionES — Traducción al español de Ascension WoW

Addon que traduce al **español de España** el contenido de [Ascension WoW](https://ascension.gg): misiones, hechizos, objetos, NPCs, logros e interfaz. Compatible con **Conquest of Azeroth** y con el modo **Wildcard** (Season 10).

No requiere modificar el cliente ni los MPQ: es un addon normal, compatible con el launcher oficial.

Se compone de dos piezas:

| | |
|---|---|
| **AscensionES** | La traducción. Es lo único imprescindible. |
| **AscensionES Voces** | Módulo **opcional** que narra las misiones en voz alta. |

---

## 📥 Instalación de la traducción

1. Descarga `AscensionES-1.5.6.zip` desde la sección **[Releases](../../releases)**.
2. Extrae la carpeta `AscensionES` dentro de `Interface\AddOns\` de tu cliente
   (normalmente `...\Ascension\Launcher\resources\ascension-live\Interface\AddOns\`).
3. Inicia el juego. Si ya estabas dentro, sal hasta la **selección de personaje** y vuelve a entrar (el cliente solo detecta addons nuevos ahí).
4. En la lista de AddOns, asegúrate de que **AscensionES español** está activado.

## ✨ Qué traduce

| Contenido | Entradas |
|---|---:|
| Nombres de hechizos y talentos | 67.711 |
| Descripciones de hechizos, talentos y tooltips | 107.611 |
| Objetos (nombres, descripciones, efectos Equipar/Uso) | 150.777 |
| **Misiones** (título, descripción, objetivos, progreso y entrega) | 13.987 |
| **Nombres de NPC** | 23.003 |
| **Diálogos de NPC** (ventana, saludos, frases al chat y burbujas) | ~69.000 |
| Logros (títulos, descripciones, criterios, categorías) | ~22.600 |
| Interfaz del servidor, errores y mensajes de chat/sistema | 9.176 |
| Voces oficiales en español («No tengo maná…») por raza y género | 1.511 clips |

- Cubre el **contenido propio de Ascension**, que no existe traducido en ningún otro sitio: cartas de habilidad, libro de hechizos, entrenador de clase, Worldforged, notificaciones…
- **Modo Wildcard (Season 10)**: panel de Progresión de personaje, ramas de talento, esencias, cartas de habilidad, colecciones de apariencia y guardarropa.
- Terminología cuidada y coherente: las habilidades citadas dentro de otras descripciones usan siempre su nombre español canónico.
- Si el servidor cambia un texto en un parche, el addon lo deja en inglés antes que mostrar una traducción incorrecta.

---

## 🔊 Módulo opcional: voz en las misiones

**AscensionES Voces** narra las misiones en español: al aceptarlas, consultarlas o entregarlas, escucharás su texto en voz alta mientras juegas.

- Narra la **descripción**, los **objetivos**, el **progreso** y la **entrega**.
- Dos voces, **narrador y narradora**, según el sexo del personaje que da la misión.
  Las misiones propias de Ascension, al no tener datos del personaje, usan la voz de narrador.
- Las voces son **sintéticas**, no grabaciones humanas.
- Ocupa unos **7,5 GB** en disco. Requiere tener AscensionES instalado.

### Instalación de las voces

Se reparte en **4 archivos** por su tamaño. **No hace falta ningún programa especial**: son ZIP normales que Windows abre solo.

1. Descarga los 4 desde [Releases](../../releases):
   `AscensionES_Voces-1.0.0-parte1de4.zip` … `parte4de4.zip` (~1,7 GB cada uno)
2. Extrae **cada uno** en `Interface\AddOns`: clic derecho → **Extraer todo…**
   Se combinan solos en la misma carpeta.
3. **Reinicia el juego.** Un `/reload` no basta: el cliente lee los sonidos al arrancar.

> **¿Y si te dejas alguna parte?** No pasa nada malo: el addon te avisa con una ventana al entrar, diciéndote **qué partes faltan** y dónde bajarlas. Mientras tanto funciona con las voces que sí tengas. Las partes van ordenadas por número de misión, así que la parte 1 cubre las de nivel bajo.

Para activar o desactivar la voz: **Interfaz → AddOns → AscensionES → Voces**, o el comando `/asesvoz`.

---

## 🚫 Qué NO traduce (por diseño)

- **NPC propios de Ascension**: no tienen nombre oficial en español y se muestran en inglés; las misiones que los citan conservan el nombre tal cual para no romper la referencia. (Los NPC estándar de Blizzard sí van traducidos con su nombre oficial.)
- **El nombre flotante sin barra de vida**: lo dibuja el motor del juego y ningún addon puede tocarlo — con los nameplates activados (tecla V) sí se traduce.
- **La pantalla de selección de reino**: los addons no se cargan ahí.

## ⚙️ Configuración

- Panel de opciones: **Interfaz → AddOns → AscensionES** (activa o desactiva cada módulo).
- Comando `/ases` en el chat: `hechizos`, `objetos`, `misiones`, `dialogos`, `logros`, `interfaz`, `chat`, `errores`, `voz`, `refrescar`…

## 🩺 ¿No te aparece el addon o no carga?

Usa la [**herramienta de diagnóstico**](DIAGNOSTICO.md): un doble clic y te dice qué pasa (ruta equivocada, extracción incompleta, antivirus…).

## 🐛 ¿Has visto un error de traducción?

Abre una [Issue con el formulario de errores](../../issues/new/choose): te pedirá el nombre exacto, dónde aparece y una captura. Las correcciones se incorporan en la siguiente versión.

## 🤝 Colabora con el proyecto

AscensionES es **gratuito y siempre lo será**. Si te ha hecho disfrutar más del juego en tu idioma y quieres colaborar, puedes hacerlo aquí:

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Colabora-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/hidexs)

Cualquier aportación ayuda a seguir revisando textos y a cubrir el contenido nuevo que va saliendo. Y si no puedes o no te apetece, también está genial: usarlo, compartirlo y avisarme de los fallos que encuentres ayuda igual. 🙂

## 🖋️ Autoría

Traducción y addon creados por **HideXs** (2026). Cada release legítima incluye una firma de autoría verificable (v1.5.6: `AES/2026-07-24/e7ac5aba4dd6cbac/HideXs`); desconfía de copias que no la lleven.

© 2026 HideXs — todos los derechos reservados sobre la traducción y el código del addon. No redistribuir versiones modificadas sin permiso. World of Warcraft® es una marca de Blizzard Entertainment; Ascension es un proyecto independiente de terceros.
