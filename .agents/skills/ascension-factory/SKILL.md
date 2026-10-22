---
name: ascension-factory
description: >-
  Especialista en la arquitectura de software, patrones de diseño OOP, reciclaje de elementos
  y catálogo de componentes UI/UX del framework AscensionFactory para World of Warcraft.
  Usar siempre que se consulte, modifique, extienda o implemente código dentro de AscensionFactory
  o en addons que consuman esta librería.
---

# Skill: Desarrollo y Mantenimiento de AscensionFactory

Esta skill documenta la arquitectura de software, los patrones de programación orientada a objetos (OOP), el sistema de pooling de widgets, el catálogo completo de constructores y las directrices obligatorias de seguridad y documentación de [`AscensionFactory`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory).

---

## 1. Reglas Sagradas e Invariantes de Seguridad

> [!CAUTION]
> ### REGLA 1: CÓDIGO SAGRADO (CONFIRMACIÓN PREVIA OBLIGATORIA)
> El código fuente de `AscensionFactory` es la base central compartida para los addons del usuario. Cualquier modificación puede provocar fallos o efectos secundarios en cascada a través de múltiples proyectos.
> **NUNCA modifiques, refactorices, agregues o elimines código en `Core/`, `Components/`, `UX/` o `Integration/` sin antes:**
> 1. Explicar claramente el problema o necesidad técnica.
> 2. Describir la solución propuesta y los componentes que se verán impactados.
> 3. **Preguntar y obtener confirmación expresa del usuario antes de ejecutar la edición.**

> [!IMPORTANT]
> ### REGLA 2: SINCRONIZACIÓN OBLIGATORIA DE DOCUMENTACIÓN
> Cada vez que se cree un nuevo componente, se altere un constructor, se agregue un método o se modifiquen parámetros:
> - Es **ESTRICTAMENTE OBLIGATORIO** actualizar [`Components/README.md`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/README.md) manteniendo el formato de tabla de auditoría:
>   `| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |`.
> - Se debe distinguir claramente entre parámetros **Obligatorios** y **Opcionales** con sus valores por defecto exactos.
> - Actualizar [`README.md`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/README.md) si se introducen capacidades públicas o cambios de API.

> [!TIP]
> ### REGLA 3: REUTILIZACIÓN ESTRICTA Y OOP (NO REINVENTAR LA RUEDA)
> Si necesitas un botón, slider, toggle, input, tooltip o menú, **NUNCA** crees un frame o widget desde cero con `CreateFrame`. Llama al constructor de `Context` (`Context:createButton`, `Context:createSlider`, etc.) pasándole la tabla de opciones requerida.

---

## 2. Arquitectura de Software del Framework

AscensionFactory está diseñado siguiendo un patrón orientado a objetos (OOP) desacoplado, modular y con pooling intensivo:

```
AscensionFactory/
├── Core/
│   ├── Core.lua               # Registro en LibStub y Prototipo Context
│   ├── FrameworkPool.lua      # Gestión y reciclaje de pools de widgets de WoW
│   ├── ThemeStyles.lua        # Tokens de diseño Obsidian Cyberpunk (colores, fuentes)
│   └── LayoutModel.lua        # Disposición secuencial automática de elementos
├── UX/
│   ├── Hoverable.lua          # Estados hover/active y enlace con tooltips
│   ├── ClickOutside.lua       # Detección modal de clicks fuera de ventanas emergentes
│   └── Scrollable.lua         # Viewports scrollables reciclando 09Slider.lua
├── Components/                # Catálogo de constructores UI modulares
│   ├── 01Frame.lua            # Ventanas base y principales (MainFrame)
│   ├── 02TabbedInterface.lua  # Navegación con pestañas y paneles
│   ├── 03TwoColumn.lua        # Layout dividido 50/50
│   ├── 04Text.lua             # Headers, Labels y Paragraphs
│   ├── 05Button.lua           # Buttons, IconButtons (vectores) y DialogButtons
│   ├── 06Toggle.lua           # Switch binario animado
│   ├── 07Checkbox.lua         # Checkbox con checkmark vectorizado
│   ├── 08InputField.lua       # Inputs de texto mono/multilínea con ScrollFrame
│   ├── 09Slider.lua           # Sliders continuos/discretos con thumb diamond/capsule/bar
│   ├── 10Stepper.lua          # Incrementador numérico con input central y repeat ticker
│   ├── 11Tooltip.lua          # Tooltips Cyberpunk con ajuste dinámico
│   ├── 12Dropdown.lua         # Select desplegable con lista scrollable
│   ├── 13ContextMenu.lua      # Menú contextual emergente por click derecho
│   ├── 14Toast.lua            # Alertas HUD con cola FIFO y temporizadores
│   ├── 15ColorPicker.lua      # Selector modal de color RGBA con gradientes e historial
│   └── README.md              # Auditoría completa de parámetros y tipos
└── Integration/
    └── BlizzardOptions.lua    # Integración con Settings.RegisterCanvasLayoutCategory
```

---

## 3. Patrones Clave de Implementación

### 3.1 Prototipo Maestro `Context` (`Core/Core.lua`)
- `lib.Context` es el prototipo donde se registran todos los constructores de componentes.
- `Context.__index = Context` proporciona herencia OOP en Lua.
- Un consumidor obtiene una instancia con:
  ```lua
  local AF = LibStub("AscensionFactory")
  local UI = AF:createContext(customStyles)
  ```
- Cada método adjunto a `Context` (ej. `function Context:createButton(options)`) está disponible inmediatamente en cualquier instancia `UI`.

### 3.2 Pooling y Reciclaje de Widgets (`Core/FrameworkPool.lua`)
- En WoW, `CreateFrame` es costoso y los widgets eliminados no son recolectados por el GC.
- Todos los constructores adquieren elementos usando:
  ```lua
  local widget = self:acquireElement(widgetType, parent, options)
  ```
- Tipos de pools soportados: `"Frame"`, `"Button"`, `"StatusBar"`, `"CheckButton"`, `"EditBox"`, `"Texture"`, `"FontString"`, `"Slider"`.
- Cada tipo tiene su reseteador dedicado que limpia scripts, colores, puntos y texturas antes de devolver el elemento al pool (`resetButton`, `resetFrame`, etc.).
- Para vaciar un panel dinámico antes de re-dibujarlo: `self:cleanupContent(panelFrame)`.

### 3.3 Composición de Componentes
- Los componentes complejos se ensamblan combinando componentes más primitivos:
  - `createMainFrame` = `createFrame` + `createIconButton` (cerrar) + scripts de arrastre y Escape.
  - `createCheckbox` = `createButton` (fila) + texturas vectoriales de palomita + `createLabel`.
  - `createStepper` = frame contenedor + dos `createIconButton` (minus/plus) + `createInputField` central con cálculo automático de ancho.
  - `createDropdown` = `createButton` + `createIconButton` (flecha) + `createFrame` flotante + `UX:makeScrollable` (con `createSlider`) + `UX:registerClickOutside`.
  - `UX:makeScrollable` = `ScrollFrame` nativo + frame canvas hijo + `createSlider` vertical con tirador en forma de cápsula.

### 3.4 Sistema de Diseño Obsidian Cyberpunk (`Core/ThemeStyles.lua`)
- **Fondo Metálico Oscuro**: `#020305` (`styles.colors.background`).
- **Bordes y Delimitadores**: `#141A24` (`styles.colors.border`), `borderInset = 1` o `2`.
- **Superficies**: `surfaceDark`, `surfaceLight`, `surfaceHover`.
- **Acentos Neón Principales**: `#FF6000` (`styles.colors.primary`), `primaryHover`, `primaryActive`.
- **Semántica Funcional**: `neonGreen` (aceptar, éxito), `neonRed` (cancelar, cerrar, peligro).
- **Tipografías**: `styles.fonts.title`, `styles.fonts.label`, `styles.fonts.text`, `styles.fonts.code`.

---

## 4. Guía de Referencia Rápida de Constructores

| Constructor | Elemento Retornado | Parámetros Obligatorios | Defaults Clave |
| :--- | :--- | :--- | :--- |
| `Context:createFrame(opt)` | `Frame` | Ninguno | `width=300`, `height=200`, `clamped=true`, `strata=parent or "MEDIUM"` |
| `Context:createMainFrame(opt)` | `Frame` | `name` | `width=860`, `height=500`, `movable=true`, `closableWithEscape=true` |
| `Context:createTabbedInterface(opt)` | `{ sidebar, tabs, panels }` | `parent`, `startY`, `tabs` | `initialIndex=1` |
| `Context:createTwoColumns(opt)` | `leftColumn, rightColumn` | Ninguno | `parent=UIParent`, `name="TwoColumnLayout"` |
| `Context:createHeader(opt)` | `FontString, nextY` | `text` | `fontSize=24`, `justifyH="LEFT"`, `spaceBelow=0` |
| `Context:createLabel(opt)` | `FontString, nextY` | `text` | `fontSize=18`, `justifyH="LEFT"`, `spaceBelow=0` |
| `Context:createParagraph(opt)` | `FontString, nextY` | `text` | `fontSize=12`, `wordWrap=true`, `justifyH="LEFT"` |
| `Context:createButton(opt)` | `Button` | Ninguno | `width=60`, `height=25`, `clickTypes={"AnyUp"}` |
| `Context:createIconButton(opt)` | `Button` | Ninguno | `size=24`, `iconType="close"` (`"plus"`, `"minus"`, etc.) |
| `Context:createDialogButton(opt)` | `Button` | Ninguno | `variant="neutral"`, `width=90` (auto-expande por texto) |
| `Context:createToggle(opt)` | `Button` | Ninguno | `width=52`, `height=24`, `padding=2`, `isOn=false` |
| `Context:createCheckbox(opt)` | `Button` | Ninguno | `checked=false`, `boxSize=25` |
| `Context:createInputField(opt)` | `Frame` (con `editBox`) | `width`, `height` | `multiLine=false`, `numeric=false`, `showClear=false` |
| `Context:createSlider(opt)` | `Frame` (con `thumb`) | `orientation`, `length` | `minValue=0`, `maxValue=100`, `step=1`, `thumbShape="diamond"` |
| `Context:createStepper(opt)` | `Frame` (con input y btns) | `width`, `height` | `minValue=0`, `maxValue=100`, `step=1`, `inputWidth=2/5` |
| `Context:createColorPicker(opt)` | `Button` (swatch) | Ninguno | `color={1,1,1,1}`, `hasAlpha=true` |
| `Context:createTooltip(opt)` | `Frame` (`TOOLTIP`) | Ninguno | `minWidth=160`, `maxWidth=280`, `padding=12` |
| `Context:createDropdown(opt)` | `Button` (trigger) | Ninguno | `options={}`, `width=160`, `height=26`, `maxVisibleItems=6` |
| `Context:createContextMenu(opt)` | `Frame` (`TOOLTIP`) | Ninguno | `items={}`, `itemHeight=22`, `minWidth=130` |
| `Context:showToast(opt)` | `Frame` (`TOOLTIP`) | Ninguno | `duration=4`, `maxVisible=4`, `type="info"` |
| `UX:makeScrollable(container, opt)` | `scrollFrame, child, bar` | `container` | `scrollBarWidth=12`, `step=30`, `thumbShape="capsule"` |

*(Para la auditoría exhaustiva de opciones de cada componente, consultar siempre [Components/README.md](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/README.md)).*

---

## 5. Procedimiento para Modificaciones o Adición de Componentes

Cuando el usuario apruebe realizar un cambio o agregar un nuevo widget:

1. **Definir la Firma y Validación**:
   - Comprobar parámetros requeridos al inicio con `if not options.foo then error(...) end`.
   - Asignar valores por defecto razonables a los parámetros opcionales.
2. **Reutilizar Pooling y Componentes Existentes**:
   - Usar `self:acquireElement` para marcos base.
   - Si requiere botones, inputs o textos, componer con los constructores existentes de `Context`.
3. **Aplicar el Sistema de Estilos**:
   - Usar `self.styles.colors` y `self.styles.fonts` (no hardcodear valores de color fijos a menos que sea una sobreescritura deliberada).
4. **Verificar Compilación y Sintaxis**:
   ```bash
   luac -p Core/*.lua UX/*.lua Components/*.lua Integration/*.lua ExampleUI.lua
   ```
5. **Actualizar la Documentación Inmediatamente**:
   - Añadir la tabla de parámetros en [`Components/README.md`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/README.md).
   - Documentar `Parámetro`, `Tipo`, `Requisito`, `Valor por Defecto` y `Descripción`.
