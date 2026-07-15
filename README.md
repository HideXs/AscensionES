# AscensionES — Traducción al español de Ascension WoW (Conquest of Azeroth)

Addon que traduce al **español de España** el contenido de [Ascension WoW](https://ascension.gg) en los reinos **Conquest of Azeroth** (probado en Vol'jin). No requiere modificar el cliente ni los MPQ: es un addon normal, compatible con el launcher oficial.

## 📥 Descarga e instalación

1. Descarga `AscensionES.zip` desde la sección **[Releases](../../releases)** (o usa **Code → Download ZIP** y quédate con la carpeta `AscensionES` de dentro).
2. Extrae la carpeta `AscensionES` dentro de `Interface\AddOns\` de tu cliente de Ascension
   (normalmente `...\Ascension\Launcher\resources\ascension-live\Interface\AddOns\`).
3. Inicia el juego. Si ya estabas dentro, sal hasta la **selección de personaje** y vuelve a entrar (el cliente solo detecta addons nuevos ahí).
4. En la lista de AddOns, asegúrate de que **AscensionES español** está activado.

## ✨ Qué traduce

| Contenido | Entradas |
|---|---:|
| Nombres de hechizos y talentos | 67.002 |
| Descripciones de hechizos/talentos | 160.886 |
| Tooltips y rangos | 75.453 |
| Objetos (nombres, descripciones, efectos Equipar/Uso) | 154.905 |
| **Misiones** (título, descripción, objetivos y diálogos de progreso/entrega) | 9.753 |
| **Nombres de NPC oficiales** (tooltip, marco de objetivo, nameplates, diálogos) | 22.993 |
| Logros (títulos, descripciones, criterios, categorías) | 22.980 |
| Interfaz custom de Ascension, errores y mensajes de chat/sistema | miles |
| Voces oficiales en español («No tengo maná…») por raza y género | 1.511 clips |

- Cubre el contenido **custom de Conquest of Azeroth**: tarjetas de habilidad embebidas en los tooltips, libro de hechizos, entrenador de clase, notificaciones, Worldforged, etc.
- Terminología cuidada y coherente (las habilidades citadas dentro de otras descripciones usan siempre su nombre español canónico).
- Si el servidor cambia un texto en un parche, el addon lo deja en inglés antes que mostrar una traducción incorrecta.

## 🚫 Qué NO traduce (por diseño)

- **NPC custom de Conquest of Azeroth**: no tienen nombre oficial esES y se muestran en inglés; las misiones que los citan conservan el nombre tal cual para no romper la referencia. (Los NPC estándar de Blizzard sí van traducidos con su nombre oficial.)
- **El nombre flotante sin barra de vida**: lo dibuja el motor del juego y ningún addon puede tocarlo — con los nameplates activados (tecla V) sí se traduce.

## ⚙️ Configuración

- Panel de opciones: **Interfaz → AddOns → AscensionES** (activa/desactiva cada módulo).
- Comando `/ases` en el chat: `hechizos`, `objetos`, `logros`, `interfaz`, `chat`, `errores`, `voz`, `refrescar`…

## 🐛 ¿Has visto un error de traducción?

Abre una [Issue con el formulario de errores](../../issues/new/choose): te pedirá el nombre exacto, dónde aparece y una captura. Las correcciones se incorporan en la siguiente versión.

## 🖋️ Autoría

Traducción y addon creados por **HideXs** (2026). Cada release legítima incluye una firma de autoría verificable (v1.0.6: `AES/2026-07-15/ce1d56a4311964c5/HideXs`); desconfía de copias que no la lleven.

© 2026 HideXs — todos los derechos reservados sobre la traducción y el código del addon. No redistribuir versiones modificadas sin permiso. World of Warcraft® es una marca de Blizzard Entertainment; Ascension es un proyecto independiente de terceros.
