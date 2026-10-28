# AscensionFactory - Components Index

Complete technical reference and audit index for all UI constructors and UX capabilities in `Components/` and `UX/`.
Every configuration parameter is audited below with explicit data types, requirements (**Obligatorio** vs **Opcional**), and default values.

---

## Quick Navigation Table

| File | Constructor | Description | Composite Sub-Elements | Requisitos Clave |
| :--- | :--- | :--- | :--- | :--- |
| [`01Frame.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/01Frame.lua) | `Context:createFrame(options)` | Versatile Obsidian Cyberpunk container frame | Container `Frame`, Border `Texture`, Background `Texture` | Todo opcional (`width=300`, `height=200`, `clamped=true`) |
| [`01Frame.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/01Frame.lua) | `Context:createMainFrame(options)` | Top-level application window | Container `Frame`, Border `Texture`, Background `Texture`, `IconButton` (Close) | `name` (**Obligatorio**), `width=860`, `height=500`, `movable=true` |
| [`02TabbedInterface.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/02TabbedInterface.lua) | `Context:createTabbedInterface(options)` | Responsive sidebar navigation with auto-collapsing panels and auto-scroll | Collapsible Sidebar `Frame`, `LayoutModel`, `Button[]` (Tabs), Accent `Texture[]`, `Frame[]` (Panels with `UX:makeScrollable`) | `parent`, `startY`, `tabs` (**Obligatorios**), `initialIndex=1`, `collapsibleSidebar=true`, `collapseThreshold=550`, `autoScroll=true` |
| [`03TwoColumn.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/03TwoColumn.lua) | `Context:createTwoColumns(options)` | Responsive split column layout with auto-stacking below breakpoint | Left `Frame`, Right `Frame`, Optional Background `Texture` | Todo opcional (`stackThreshold=480`, `responsive=true`, `gap=10`) |
| [`04Text.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/04Text.lua) | `Context:createHeader(options)` | Glowing section title with optional elastic word-wrap | `FontString` | `text` (**Obligatorio**), `fontSize=24`, `justifyH="LEFT"`, `elasticWidth=false` |
| [`04Text.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/04Text.lua) | `Context:createLabel(options)` | Single-line form label with optional elastic word-wrap | `FontString` | `text` (**Obligatorio**), `fontSize=18`, `justifyH="LEFT"`, `elasticWidth=false` |
| [`04Text.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/04Text.lua) | `Context:createParagraph(options)` | Multi-line wrapped text body | `FontString` | `text` (**Obligatorio**), `fontSize=12`, `wordWrap=true` |
| [`05Button.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/05Button.lua) | `Context:createButton(options)` | Interactive styled push button | `Button`, Border `Texture`, Track `Texture`, `FontString` | Todo opcional (`width=60`, `height=25`, `clickTypes={"AnyUp"}`) |
| [`05Button.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/05Button.lua) | `Context:createIconButton(options)` | Square geometric vector icon button with rotation support | `Button`, Geometric vector `Texture[]` (`close`, `plus`, `minus`, `minimize`, `maximize`, `arrowdown`, `arrowleft`, `arrowright`, `arrowup`) | Todo opcional (`size=24`, `iconType="close"`) |
| [`05Button.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/05Button.lua) | `Context:createDialogButton(options)` | Semantic action button (`accept`/`cancel`/`neutral`) | `Button`, Border `Texture`, Track `Texture`, `FontString` | Todo opcional (`variant="neutral"`, `width=90` auto-expand, `fluidWidth=false`) |
| [`05Button.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/05Button.lua) | `Context:createDialogButtonGroup(options)` | Responsive dialog action button row with auto-stacking below breakpoint | Container `Frame`, `DialogButton[]` | Todo opcional (`stackThreshold=400`, `gap=8`, `buttonHeight=26`) |
| [`06Toggle.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/06Toggle.lua) | `Context:createToggle(options)` | Animated binary switch (on/off) with flex row mode | `Button`, Border `Texture`, Track `Texture`, Sliding Thumb `Texture`, Optional Label `FontString` | Todo opcional (`width=52`, `height=24`, `padding=2`, `flexRow=false`) |
| [`07Checkbox.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/07Checkbox.lua) | `Context:createCheckbox(options)` | Checkbox row with vector checkmark and flex row mode | Row `Button`, Box Border `Texture`, Box Track `Texture`, Vector Check Leg `Texture[2]`, Label `FontString` | Todo opcional (`checked=false`, `boxSize=25`, `flexRow=false`) |
| [`08InputField.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/08InputField.lua) | `Context:createInputField(options)` | Single/Multi-line text input & scroll area with fluid width support | Container `Frame`, Border `Texture`, Track `Texture`, `ScrollFrame` (multi-line), `EditBox`, Placeholder `FontString`, `IconButton` (Clear), `Slider` (Scrollbar) | `height` (**Obligatorio**), `width` (**Obligatorio** salvo `fluidWidth=true`), `multiLine=false` |
| [`09Slider.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/09Slider.lua) | `Context:createSlider(options)` | Horizontal/Vertical slider & meter with fluid width support | `Frame`, Border `Texture`, Track `Texture`, Fill `Texture`, Diamond/Capsule/Bar Thumb `Button` | `orientation` (**Obligatorio**), `length` (**Obligatorio** salvo `fluidWidth=true`), `min=0`, `max=100` |
| [`10Stepper.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/10Stepper.lua) | `Context:createStepper(options)` | Joined numeric stepper with repeat ticker and fluid width support | Container `Frame`, Minus `IconButton`, Middle `InputField`, Plus `IconButton` | `height` (**Obligatorio**), `width` (**Obligatorio** salvo `fluidWidth=true`), `min=0`, `max=100` |
| [`11Tooltip.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/11Tooltip.lua) | `Context:createTooltip(options)` / `getTooltip()` | Obsidian Cyberpunk styled tooltip | Container `Frame` (`01Frame`), Title `FontString`, Description `FontString` | Todo opcional (`minWidth=160`, `maxWidth=280`, `padding=12`) |
| [`12Dropdown.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/12Dropdown.lua) | `Context:createDropdown(options)` | Dropdown select with scrollable list and fluid width support | Trigger `Button`, Down Arrow `IconButton`, List `Frame` (`01Frame`), `ScrollFrame` (`09Slider`) | Todo opcional (`options={}`, `width=160`, `height=26`, `fluidWidth=false`) |
| [`13ContextMenu.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/13ContextMenu.lua) | `Context:createContextMenu(options)` / `UX:showContextMenu` | Right-click popup context menu | Menu `Frame` (`01Frame`), Item `Button[]` (`05Button`), Separator `Texture[]` | En `showContextMenu`: `parent`, `items` (**Obligatorios**) |
| [`14Toast.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/14Toast.lua) | `Context:showToast(options)` / `createToast` | Cyberpunk HUD notification toast & queue | Toast `Frame` (`01Frame`), Title `FontString`, Message `FontString`, `IconButton` (Close), Icon `Frame` (Vector/Atlas), Countdown `StatusBar` | Todo opcional (`duration=4`, `maxVisible=4`, `type="info"`, `showProgress=false`) |
| [`15ColorPicker.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/15ColorPicker.lua) | `Context:createColorPicker(options)` / `openColorPicker` | Cyberpunk RGBA modal color picker & swatch | Swatch `Button`, Modal `Frame`, Hex `InputField`, RGBA `Slider[]`, History `Button[]` | Todo opcional (`color={1,1,1,1}`, `hasAlpha=true`) |
| [`UX/Scrollable.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/UX/Scrollable.lua) | `UX:makeScrollable(container, options)` | UX scroll viewport capability | `ScrollFrame`, Content `Frame`, Vertical `Slider` (`09Slider`) | `container` (**Obligatorio**), `scrollBarWidth=12`, `step=30`, `thumbShape="capsule"` |
| [`UX/Resizable.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/UX/Resizable.lua) | `UX:makeResizable(frame, options)` | UX corner bracket resize capability | Corner Button, Bracket `Texture[2]` (`WHITE8X8`), Metallic states | `frame` (**Obligatorio**), `gripSize=24`, `gripThickness=8`, metallic palette |
| [`Core/LayoutModel.lua`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Core/LayoutModel.lua) | `Context:createLayoutModel(parent)` | Layout engine with dynamic stacking, responsive modes & wrappers | Dynamic layout state, responsive registry, fluid anchor calculator | `parent` (**Obligatorio**), `enableResponsive(options)`, `getAvailableWidth(padding)` |

---

## Component Detailed Specifications

### 1. `01Frame.lua`

#### `Context:createFrame(options)`
Versatile container frame styled with Obsidian Cyberpunk metallic borders and background layers.

- **Composite Elements**:
  - `frame` (`Frame`): Container frame in the WoW hierarchy.
  - `frame.border` (`Texture`): Outer border texture on layer `BACKGROUND` (-2).
  - `frame.background` (`Texture`): Inner surface fill on layer `BACKGROUND` (-1).
  - `frame.closeButton` (`Button` / `IconButton`): Top-right close button (optional).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre en la jerarquía de interfaz de WoW. |
| `name` | `string` | **Opcional** | `nil` | Identificador global registrado en `_G[name]`. |
| `width` | `number` | **Opcional** | `300` | Ancho del frame en píxeles. |
| `height` | `number` | **Opcional** | `200` | Alto del frame en píxeles. |
| `point` / `anchorPoint` | `string` | **Opcional** | `options.anchor or "CENTER"` | Punto de anclaje relativo (`"CENTER"`, `"TOPLEFT"`, etc.). |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Frame o UI element de referencia para el anclaje. |
| `relativePoint` | `string` | **Opcional** | `options.point or "CENTER"` | Punto de anclaje en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Desplazamiento horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Desplazamiento vertical en píxeles. |
| `strata` | `string` | **Opcional** | `parent:GetFrameStrata() or "MEDIUM"` | Nivel de strata (`"BACKGROUND"`, `"MEDIUM"`, `"DIALOG"`, etc.). |
| `frameLevel` | `number` | **Opcional** | `parent:GetFrameLevel() + 1` | Z-index relativo dentro de la strata. |
| `clamped` | `boolean` | **Opcional** | `true` | Restringe el frame para que no pueda salir de la pantalla visible (`SetClampedToScreen`). |
| `showBorder` | `boolean` | **Opcional** | `true` | Si dibuja la textura perimetral de borde exterior. |
| `borderColor` | `table` RGBA | **Opcional** | `styles.colors.border` | Color RGBA del borde `{r, g, b, a}`. |
| `borderInset` | `number` | **Opcional** | `1` | Grosor / inset del borde perimetral en píxeles. |
| `showBackground` | `boolean` | **Opcional** | `true` | Si dibuja la textura interna de fondo. |
| `backgroundColor` | `table` RGBA | **Opcional** | `styles.colors.background` | Color RGBA de la superficie de fondo `{r, g, b, a}`. |
| `showCloseButton` | `boolean` | **Opcional** | `false` | Genera un botón 'X' de cierre en la esquina superior derecha. |
| `closeButtonSize` | `number` | **Opcional** | `24` | Dimensiones en píxeles del botón de cierre. |
| `closeButtonXOffset` | `number` | **Opcional** | `-8` | Desplazamiento horizontal del botón de cierre respecto a TOPRIGHT. |
| `closeButtonYOffset` | `number` | **Opcional** | `-8` | Desplazamiento vertical del botón de cierre respecto a TOPRIGHT. |
| `onClose` | `function(frame)` | **Opcional** | `nil` | Callback ejecutado al hacer click en el botón de cierre. |
| `movable` | `boolean` | **Opcional** | `false` | Permite mover la ventana arrastrándola con el cursor (`SetMovable`). |
| `closableWithEscape` | `boolean` | **Opcional** | `false` | Registra el frame en `UISpecialFrames` para permitir cerrarlo con Escape. |
| `resizable` | `boolean` | **Opcional** | `false` | Habilita la manija de redimensión en la esquina inferior derecha (`UX:makeResizable`). |
| `minWidth` | `number` | **Opcional** | `0` | Ancho mínimo permitido al redimensionar. |
| `minHeight` | `number` | **Opcional** | `0` | Alto mínimo permitido al redimensionar. |
| `maxWidth` | `number` | **Opcional** | `0` | Ancho máximo permitido al redimensionar (`0` = sin límite). |
| `maxHeight` | `number` | **Opcional** | `0` | Alto máximo permitido al redimensionar (`0` = sin límite). |
| `onResizeStop` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado al soltar el botón de redimensión. |
| `onSizeChanged` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado dinámicamente durante el cambio de tamaño. |

- **Instance Methods / Properties**:
  - API nativa de WoW `Frame` (`Show()`, `Hide()`, `SetPoint()`, `SetSize()`, etc.).
  - `frame.globalName` (`string`).

---

#### `Context:createMainFrame(options)`
Top-level application window container styled with Obsidian Cyberpunk metallic borders and background. Configures window dragging and Escape-to-close by default.

- **Composite Elements**:
  - `frame` (`Frame`): Top-level window attached to `UIParent`.
  - `frame.border` (`Texture`): Outer border texture on layer `BACKGROUND` (-2).
  - `frame.background` (`Texture`): Inner surface fill on layer `BACKGROUND` (-1).
  - `frame.closeButton` (`Button` / `IconButton`): Top-right close button.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `name` | `string` | **Obligatorio** | *Ninguno (Error si falta)* | Identificador global único para la ventana (`_G[name]`). |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre en la jerarquía. |
| `width` | `number` | **Opcional** | `860` | Ancho total de la ventana principal en píxeles. |
| `height` | `number` | **Opcional** | `500` | Alto total de la ventana principal en píxeles. |
| `anchor` / `point` | `string` | **Opcional** | `"CENTER"` | Posición inicial de anclaje en pantalla. |
| `xOffset` | `number` | **Opcional** | `0` | Desplazamiento horizontal inicial en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Desplazamiento vertical inicial en píxeles. |
| `strata` | `string` | **Opcional** | `"DIALOG"` | Strata de la ventana principal. |
| `clamped` | `boolean` | **Opcional** | `true` | Impide arrastrar la ventana fuera de la pantalla visible. |
| `movable` | `boolean` | **Opcional** | `true` | Habilita arrastre con el ratón por toda la superficie de la ventana. |
| `closableWithEscape` | `boolean` | **Opcional** | `true` | Registra la ventana en `UISpecialFrames` para cerrarse con Esc. |
| `showCloseButton` | `boolean` | **Opcional** | `true` | Muestra el botón de cierre 'X' en la esquina superior derecha. |
| `closeButtonSize` | `number` | **Opcional** | `24` | Tamaño en píxeles del botón de cierre. |
| `closeButtonXOffset` | `number` | **Opcional** | `-8` | Offset X del botón de cierre. |
| `closeButtonYOffset` | `number` | **Opcional** | `-8` | Offset Y del botón de cierre. |
| `onClose` | `function(frame)` | **Opcional** | `nil` | Callback ejecutado tras cerrar la ventana. |
| `borderInset` | `number` | **Opcional** | `2` | Grosor / inset del borde exterior en píxeles. |
| `resizable` | `boolean` | **Opcional** | `false` | Habilita la manija de redimensión metálica en la esquina inferior derecha. |
| `minWidth` | `number` | **Opcional** | `0` | Ancho mínimo permitido al redimensionar. |
| `minHeight` | `number` | **Opcional** | `0` | Alto mínimo permitido al redimensionar. |
| `maxWidth` | `number` | **Opcional** | `0` | Ancho máximo permitido al redimensionar (`0` = sin límite). |
| `maxHeight` | `number` | **Opcional** | `0` | Alto máximo permitido al redimensionar (`0` = sin límite). |
| `onResizeStop` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado al soltar el botón de redimensión. |
| `onSizeChanged` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado dinámicamente durante el cambio de tamaño. |

- **Instance Methods / Properties**:
  - API nativa de WoW `Frame` (`Show()`, `Hide()`, `SetPoint()`, `SetSize()`, etc.).
  - `frame.globalName` (`string`).

---

### 2. `02TabbedInterface.lua`

#### `Context:createTabbedInterface(options)`
Constructs a vertical navigation sidebar and synchronized content panels with active indicator accents, responsive auto-collapsing sidebar to compact icon indicators, manual toggle arrow button, and integrated auto-scroll viewport per panel via `UX:makeScrollable`.

- **Composite Elements**:
  - `sidebar` (`Frame`): Navigation container (width: `sidebarWidth` [160px] or `collapsedWidth` [40px]).
  - `sidebar.toggleButton` (`IconButton`): Top-right arrow button toggling collapse/expand with smooth rotation.
  - `tabs` (`Button[]`): Array of tab button frames managed by `LayoutModel`.
  - `tab.tabLabel` (`FontString`): Standard text title, visible in expanded mode.
  - `tab.compactIndicator` (`FontString`): Centered 1-2 letter uppercase monogram, visible in collapsed mode.
  - `tab.accent` (`Texture`): 8px left indicator bar colored in `primary` / `primaryActive`.
  - `panels` (`Frame[]`): Array of content panels matching tab order.
  - `panel.scrollFrame` (`ScrollFrame`): Scrollable viewport attached when `autoScroll = true`.
  - `panel.scrollChild` (`Frame`): Content container for placing user elements when `autoScroll = true`.
  - `panel.scrollbar` (`Slider`): Vertical capsule slider attached when `autoScroll = true`.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Obligatorio** | *Ninguno (Requerido)* | Frame contenedor sobre el que se anclan sidebar y paneles. |
| `startY` | `number` | **Obligatorio** | *Ninguno (Requerido)* | Offset vertical (negativo, e.g. `-30`) para ubicar la parte superior del sidebar. |
| `tabs` | `string[]` | **Obligatorio** | *Ninguno (Requerido)* | Array secuencial con títulos de pestañas (`{"General", "Audio", ...}`). |
| `initialIndex` | `number` | **Opcional** | `1` | Índice (1-based) de la pestaña que se activa por defecto al iniciar. |
| `sidebarWidth` | `number` | **Opcional** | `160` | Ancho del sidebar expandido en píxeles. |
| `collapsedWidth` | `number` | **Opcional** | `40` | Ancho del sidebar colapsado (compact mode) en píxeles. |
| `collapseThreshold` | `number` | **Opcional** | `550` | Ancho del frame padre por debajo del cual el sidebar se colapsa automáticamente. |
| `collapsibleSidebar` | `boolean` | **Opcional** | `true` | Habilita botón de toggle superior y auto-colapso responsivo. |
| `autoScroll` | `boolean` | **Opcional** | `true` | Integra automáticamente un viewport desplazable (`UX:makeScrollable`) en cada panel. |
| `scrollStep` | `number` | **Opcional** | `30` | Paso de desplazamiento del scroll en píxeles por giro de rueda del ratón. |
| `onSidebarToggle` | `function(sidebar, isCollapsed)` | **Opcional** | `nil` | Callback ejecutado cuando el sidebar se expande o colapsa. |
| `onTabSelected` | `function(index, tab, panel)` | **Opcional** | `nil` | Callback ejecutado cuando el usuario cambia de pestaña. |

- **Return Value**:
  - `table`:
    - `sidebar` (`Frame`): Frame contenedor del menú lateral.
    - `tabs` (`Button[]`): Array de botones de navegación.
    - `panels` (`Frame[]`): Array de paneles de contenido (con `panel.scrollChild` si `autoScroll=true`).
    - `toggleButton` (`IconButton`): Botón flecha de colapso/expansión.
    - `collapseSidebar()` (`function`): Colapsa el sidebar a modo compacto.
    - `expandSidebar()` (`function`): Expande el sidebar a modo normal.
    - `toggleSidebar()` (`function`): Alterna el estado de colapso.
    - `isCollapsed()` (`function(): boolean`): Devuelve `true` si el sidebar está colapsado.
    - `selectTab(index)` (`function`): Cambia programáticamente la pestaña activa.
    - `getActiveTab()` (`function(): number`): Devuelve el índice de la pestaña activa.

---

### 3. `03TwoColumn.lua`

#### `Context:createTwoColumns(options)`
Splits parent width into two container columns with a configurable center gap. Features automatic responsive stacking: maintains 50%/50% side-by-side mode in wide layouts, and automatically transitions to 100% full-width vertical stacked layout when parent width falls below `stackThreshold` (default 480px).

- **Composite Elements**:
  - `leftColumn` (`Frame`): Top/left container frame.
  - `rightColumn` (`Frame`): Bottom/right container frame.
  - Optional `background` (`Texture`) on each column.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre en el cual se divide el espacio. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical desde la parte superior del padre en píxeles. |
| `name` | `string` | **Opcional** | `"TwoColumnLayout"` | Prefijo para nombres globales (`_G[name.."Left"]`, `_G[name.."Right"]`). |
| `height` | `number` | **Opcional** | `nil` *(Ancla al BOTTOM del padre)* | Altura fija de las columnas en píxeles. Si no se pasa, llena hasta abajo en modo horizontal. |
| `gap` | `number` | **Opcional** | `10` | Separación en píxeles entre ambas columnas. |
| `stackThreshold` / `threshold` | `number` | **Opcional** | `480` | Ancho en píxeles por debajo del cual las columnas se apilan verticalmente (100% ancho). |
| `responsive` | `boolean` | **Opcional** | `true` | Si se suscribe automáticamente a `OnSizeChanged` del padre para auto-apilarse. |
| `stackedColumnHeight` | `number` | **Opcional** | `200` | Altura en píxeles de cada columna al colapsar a modo apilado si `height` es `nil`. |
| `backgroundColor` | `table` RGBA | **Opcional** | `nil` *(Transparente {0,0,0,0})* | Color de fondo aplicado a ambas columnas. |
| `leftBackgroundColor` | `table` RGBA | **Opcional** | `options.backgroundColor` | Color de fondo específico para la columna izquierda. |
| `rightBackgroundColor` | `table` RGBA | **Opcional** | `options.backgroundColor` | Color de fondo específico para la columna derecha. |
| `onLayoutChange` | `function(left, right, mode, width)` | **Opcional** | `nil` | Callback ejecutado cuando el modo cambia entre `"horizontal"` y `"stacked"`. |

- **Return Value**:
  - `leftColumn, rightColumn` (`Frame, Frame`).
- **Attached Column Methods & Properties**:
  - `column.mode`: `"horizontal"` o `"stacked"`.
  - `column.isStacked()` (`function(): boolean`): Devuelve `true` si las columnas están apiladas verticalmente.
  - `column.updateLayout(width)` (`function`): Fuerza una recalculación del layout para un ancho dado.
  - `column.otherColumn`: Referencia a la columna complementaria.
  - `column.parentFrame`: Referencia al contenedor padre.

---

### 4. `04Text.lua`

#### `Context:createHeader(options)`
Creates glowing section title header text with neon orange cyberpunk accent.

- **Composite Elements**: `FontString`.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `string` | **Obligatorio** | *Ninguno (Requerido)* | Contenido del texto del título. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre donde se crea el FontString. |
| `fontSize` | `number` | **Opcional** | `24` | Tamaño de la fuente en píxeles. |
| `fontFamily` | `string` | **Opcional** | `"fonts/frizqt___cyr.ttf"` | Ruta al archivo de fuente tipográfica. |
| `shadowColor` | `table` RGBA | **Opcional** | `styles.colors.surfaceDark` | Color de sombra del texto (offset fijo 2, -2). |
| `wordWrap` | `boolean` | **Opcional** | `nil` | Si se permite o restringe el ajuste de línea automático. |
| `elasticWidth` | `boolean` | **Opcional** | `false` | Ancla automáticamente el extremo derecho al borde del padre con `wordWrap=true` preservando el tamaño tipográfico. |
| `justifyH` | `string` | **Opcional** | `"LEFT"` | Alineación horizontal (`"LEFT"`, `"CENTER"`, `"RIGHT"`). |
| `width` | `number` | **Opcional** | `nil` | Ancho explícito en píxeles para delimitar el texto. |
| `rightOffset` | `number` | **Opcional** | `nil` | Ancla el extremo derecho al borde del padre con este offset. |
| `spaceBelow` | `number` | **Opcional** | `0` | Espacio en píxeles añadido debajo al calcular `nextY`. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Return Value**: `header, nextY` (`FontString, number`).

---

#### `Context:createLabel(options)`
Creates single-line UI form label with crisp white text.

- **Composite Elements**: `FontString`.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `string` | **Obligatorio** | *Ninguno (Requerido)* | Contenido de texto de la etiqueta. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre contenedor. |
| `fontSize` | `number` | **Opcional** | `18` | Tamaño de la fuente en píxeles. |
| `fontFamily` | `string` | **Opcional** | `"fonts/frizqt___cyr.ttf"` | Archivo de tipografía. |
| `shadowColor` | `table` RGBA | **Opcional** | `styles.colors.black` | Color de sombra (offset 1, -1). |
| `wordWrap` | `boolean` | **Opcional** | `nil` | Ajuste de palabras automático. |
| `elasticWidth` | `boolean` | **Opcional** | `false` | Ancla automáticamente el extremo derecho al borde del padre con `wordWrap=true` preservando el tamaño tipográfico. |
| `justifyH` | `string` | **Opcional** | `"LEFT"` | Alineación horizontal del texto. |
| `width` | `number` | **Opcional** | `nil` | Ancho explícito del contenedor de texto. |
| `rightOffset` | `number` | **Opcional** | `nil` | Anclaje derecho al padre. |
| `spaceBelow` | `number` | **Opcional** | `0` | Margen inferior para el cálculo de `nextY`. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Return Value**: `label, nextY` (`FontString, number`).

---

#### `Context:createParagraph(options)`
Creates multi-line auto-wrapped descriptive text block.

- **Composite Elements**: `FontString` (with `SetWordWrap(true)`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `string` | **Obligatorio** | *Ninguno (Requerido)* | Cuerpo de texto multilínea. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `fontSize` | `number` | **Opcional** | `12` | Tamaño de la fuente en píxeles. |
| `fontFamily` | `string` | **Opcional** | `"fonts/frizqt___cyr.ttf"` | Archivo de tipografía. |
| `justifyH` | `string` | **Opcional** | `"LEFT"` | Alineación horizontal. |
| `width` | `number` | **Opcional** | `nil` | Ancho explícito en píxeles. Si no se pasa, usa `rightOffset`. |
| `rightOffset` | `number` | **Opcional** | `-xOffset` o `-10` | Offset derecho para auto-envolver las líneas dentro del frame padre. |
| `spaceBelow` | `number` | **Opcional** | `0` | Espacio extra debajo para el retorno `nextY`. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Return Value**: `paragraph, nextY` (`FontString, number`).

---

### 5. `05Button.lua`

#### `Context:createButton(options)`
Creates standard interactive button with border, track, hover glow, and text label.

- **Composite Elements**: `Button`, `border` (`Texture`), `track` (`Texture`), `label` (`FontString`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `string` | **Opcional** | `""` | Texto del botón. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `width` | `number` | **Opcional** | `60` | Ancho del botón en píxeles. |
| `height` | `number` | **Opcional** | `25` | Alto del botón en píxeles. |
| `trackColors` | `table` | **Opcional** | `{ normal, hover, active, disabled }` de styles | Paleta de colores RGBA de la superficie de fondo. |
| `borderColors` | `table` | **Opcional** | `{ normal, hover, active, disabled }` de styles | Paleta de colores RGBA del borde perimetral. |
| `labelColors` | `table` | **Opcional** | `{ normal, hover, active, disabled }` de styles | Paleta de colores RGBA del texto. |
| `tooltip` | `string\|function` | **Opcional** | `nil` | Contenido del tooltip mostrado al hacer hover. |
| `clickTypes` | `string[]` | **Opcional** | `{"AnyUp"}` | Tipos de clicks registrados en WoW (`"LeftButtonUp"`, etc.). |
| `onClick` | `function(self, btn, down)` | **Opcional** | `nil` | Callback de acción al pulsar el botón. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Return Value**: `button` (`Button`).
- **Instance Methods**: `button:setText(text)`, `button:getText()`, `button:setEnabled(enabled)`.

---

#### `Context:createIconButton(options)`
Creates square button with procedural geometric vector icon.

- **Icon Types (`iconType`)**: `"close"`, `"plus"`, `"minus"`, `"minimize"`, `"maximize"`, `"arrowdown"`, `"arrowleft"`, `"arrowright"`, `"arrowup"`.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `size` | `number` | **Opcional** | `24` | Ancho y alto cuadrado en píxeles. |
| `iconType` | `string` | **Opcional** | `"close"` | Tipo de vector geométrico (`"close"`, `"plus"`, `"minus"`, `"minimize"`, `"maximize"`, `"arrowdown"`, `"arrowleft"`, `"arrowright"`, `"arrowup"`). |
| `iconColor` | `table` RGBA | **Opcional** | `styles.colors.white` | Color del trazo del icono vectorizado. |
| `...` *(Opciones de `createButton`)* | Mixto | **Opcional** | *(Heredado)* | Soporta todas las opciones de `createButton` (`onClick`, `tooltip`, `parent`, anclajes). |

- **Return Value**: `button` (`Button`).
- **Instance Methods**:
  - `button:setIconRotation(angleDegrees)`: Rota dinámicamente la textura del icono (para flechas giratorias).

---

#### `Context:createDialogButton(options)`
Creates semantic dialog action button with automated width, theme colors, and optional fluid stretching.

- **Variants (`variant`)**:
  - `"accept"` / `"confirm"` / `"success"`: Green accent theme.
  - `"cancel"` / `"decline"` / `"danger"`: Red laser theme.
  - `"neutral"`: Standard metallic theme.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `variant` / `buttonType` | `string` | **Opcional** | `"neutral"` | Semántica visual: `"accept"`/`"confirm"`/`"success"`, `"cancel"`/`"decline"`/`"danger"`, `"neutral"`. |
| `text` | `string` | **Opcional** | Según variante (`"Accept"`, `"Cancel"`, `"Button"`) | Texto del botón (se auto-asigna según la variante si no se especifica). |
| `width` | `number` | **Opcional** | `90` *(Auto-expande si el texto es más largo)* | Ancho base en píxeles. |
| `height` | `number` | **Opcional** | `26` | Alto del botón en píxeles. |
| `fluidWidth` | `boolean` | **Opcional** | `false` | Si es true, expande el botón horizontalmente hacia el borde derecho. |
| `fluidRightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al expandir con `fluidWidth=true`. |
| `...` *(Opciones de `createButton`)* | Mixto | **Opcional** | *(Heredado)* | Soporta todas las opciones estándar de `createButton`. |

- **Return Value**: `button` (`Button`).

---

#### `Context:createDialogButtonGroup(options)` / `Context:createDialogButtons(options)`
Creates a responsive group of semantic dialog buttons. Renders buttons side-by-side in a horizontal row when space permits, and automatically transitions to a 100% full-width stacked vertical column when parent width is below `stackThreshold` (default 400px).

- **Composite Elements**:
  - `group` (`Frame`): Container frame wrapping the buttons.
  - `group.buttons` (`DialogButton[]`): Array of created action buttons.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `buttons` | `table[]` | **Obligatorio** | *Ninguno (Requerido)* | Array de configuraciones de botón (`{ { text="Save", variant="accept", onClick=... }, { text="Cancel", variant="cancel" } }`). |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor sobre el que se ancla el grupo. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `stackThreshold` / `threshold` | `number` | **Opcional** | `400` | Ancho en píxeles por debajo del cual el grupo pasa a modo vertical apilado. |
| `buttonHeight` / `height` | `number` | **Opcional** | `26` | Altura en píxeles de cada botón del grupo. |
| `buttonWidth` / `width` | `number` | **Opcional** | `90` | Ancho predeterminado de cada botón en modo horizontal. |
| `gap` | `number` | **Opcional** | `8` | Separación en píxeles entre botones consecutivos. |
| `responsive` | `boolean` | **Opcional** | `true` | Si se suscribe automáticamente a `OnSizeChanged` del contenedor padre. |
| `onLayoutChange` | `function(group, mode, width)` | **Opcional** | `nil` | Callback ejecutado cuando el grupo cambia entre `"horizontal"` y `"vertical"`. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"BOTTOMRIGHT"` | Anclaje relativo del grupo de botones. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `"BOTTOMRIGHT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Return Value**: `group` (`Frame`).
- **Attached Group Properties & Methods**:
  - `group.buttons`: Array con las instancias de botones creadas.
  - `group.mode`: `"horizontal"` o `"vertical"`.
  - `group.isStacked()` (`function(): boolean`): Devuelve `true` si los botones están apilados verticalmente.
  - `group.updateLayout(width)` (`function`): Fuerza actualización de layout para un ancho específico.

---

### 6. `06Toggle.lua`

#### `Context:createToggle(options)`
Creates an animated binary switch toggle button with sliding thumb block.

- **Composite Elements**: `Button`, `border` (`Texture`), `track` (`Texture`), `thumb` (`Texture`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `text` / `label` | `string` | **Opcional** | `""` | Texto de la etiqueta de fila (activa `flexRow` automáticamente si se especifica). |
| `flexRow` | `boolean` | **Opcional** | `false` | Fila adaptable al 100% de ancho con interruptor a la derecha y etiqueta izquierda con auto-wrap. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al anclar en modo `flexRow`. |
| `width` | `number` | **Opcional** | `52` | Ancho total del interruptor en píxeles. |
| `height` | `number` | **Opcional** | `24` | Alto total del interruptor en píxeles. |
| `padding` | `number` | **Opcional** | `2` | Margen interior (inset) entre el thumb deslizante y el marco. |
| `getter` | `function(): boolean` | **Opcional** | `nil` | Función que retorna el estado inicial booleano (`true`/`false`). |
| `setter` | `function(isOn: boolean)` | **Opcional** | `nil` | Callback ejecutado cuando el usuario cambia el estado. |
| `onClick` | `function(self, isOn)` | **Opcional** | `nil` | Callback directo al pulsar el toggle. |
| `tooltip` | `string\|function` | **Opcional** | `nil` | Tooltip de ayuda en mouseover. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods / Properties**:
  - `toggle.isOn` (`boolean`).
  - `toggle:setState(state)` (`function`): Programmatically sets state and triggers animation.
  - `toggle:setText(newText)` / `toggle:SetText(newText)`: Updates flex row label text.
  - `toggle:setFlexRow(enabled)`: Toggles flex row mode.

---

### 7. `07Checkbox.lua`

#### `Context:createCheckbox(options)`
Creates checkbox row containing a square box, vector checkmark legs, and adjacent label. Supports `flexRow = true` mode for responsive forms with right-aligned checkbox and left-anchored word-wrapped label.

- **Composite Elements**: `Button` (row), `boxBorder` (`Texture`), `boxTrack` (`Texture`), `checkShortLeg` (`Texture`), `checkLongLeg` (`Texture`), `label` (`FontString`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `text` | `string` | **Opcional** | `""` | Texto adyacente a la casilla de verificación. |
| `flexRow` | `boolean` | **Opcional** | `false` | Fila adaptable al 100% de ancho con casilla a la derecha y etiqueta izquierda con auto-wrap. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al anclar en modo `flexRow`. |
| `checked` | `boolean` | **Opcional** | `false` | Estado inicial de selección si no se define `getter`. |
| `getter` | `function(): boolean` | **Opcional** | `nil` | Función que devuelve el estado activo de la opción. |
| `setter` | `function(checked: boolean)` | **Opcional** | `nil` | Función invocada al cambiar el estado. |
| `boxSize` / `size` | `number` | **Opcional** | `buttonHeight` (`25`) | Dimensiones cuadradas de la caja de verificación en píxeles. |
| `width` | `number` | **Opcional** | Auto-calculado (`boxSize + 8 + textWidth`) | Ancho total de la fila del checkbox (salvo en flexRow que llena el ancho). |
| `onClick` | `function(self, checked, btn, down)` | **Opcional** | `nil` | Callback de click adicional. |
| `tooltip` | `string\|function` | **Opcional** | `nil` | Tooltip en hover. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods / Properties**:
  - `checkbox.isChecked` (`boolean`).
  - `checkbox:getChecked()` / `checkbox:GetChecked()`: Returns current checked boolean state.
  - `checkbox:setChecked(isChecked)` / `checkbox:SetChecked(isChecked)`: Updates checked state and checkmark visibility.
  - `checkbox:setText(newText)` / `checkbox:SetText(newText)`: Updates label text and resizes checkbox frame.
  - `checkbox:setFlexRow(enabled)`: Toggles flex row mode.

---

### 8. `08InputField.lua`

#### `Context:createInputField(options)`
Unified text input field supporting single-line inputs, multi-line scrollable text areas with clipping, numeric constraints, ghost placeholder text, focus glow, and clear/scrollbar attachments.

- **Composite Elements**:
  - `container` (`Frame`): Outer clipping frame with border and track.
  - `container.scrollFrame` (`ScrollFrame`): Child viewport when `multiLine = true`.
  - `container.editBox` (`EditBox`): Native text editing widget.
  - `container.placeholder` (`FontString`): Ghost text overlay.
  - `container.clearButton` (`IconButton`): Optional clear icon button (single-line).
  - `container.scrollbar` (`Slider`): Optional vertical slider (multi-line).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `width` | `number` | **Obligatorio\*** | *Ninguno (Error si falta)* | Ancho total del campo en píxeles. (\*Opcional si se especifica `fluidWidth = true`). |
| `height` | `number` | **Obligatorio** | *Ninguno (Error si falta)* | Alto total del campo en píxeles. |
| `fluidWidth` | `boolean` | **Opcional** | `false` | Si es true, el campo expande su ancho automáticamente hasta el margen derecho del contenedor. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al expandir con `fluidWidth=true`. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Nombre global registrado en `_G[name]`. |
| `multiLine` | `boolean` | **Opcional** | `false` | Habilita modo multilínea con ScrollFrame interno y redimensión adaptativa. |
| `showScrollbar` | `boolean` | **Opcional** | `false` | Añade barra de desplazamiento vertical integrada (solo en multilínea). |
| `showClear` / `clearButton` | `boolean` | **Opcional** | `false` | Añade botón de limpiar contenido 'X' (solo en una sola línea). |
| `placeholder` | `string` | **Opcional** | `""` | Texto fantasma visible cuando el campo está vacío. |
| `numeric` | `boolean` | **Opcional** | `false` | Restringe la entrada exclusivamente a caracteres numéricos (`0-9`). |
| `password` | `boolean` | **Opcional** | `false` | Oculta los caracteres introducidos con asteriscos (`*`). |
| `maxLetters` / `maxLength` | `number` | **Opcional** | `0` *(Sin límite)* | Límite máximo de caracteres permitidos. |
| `autoFocus` | `boolean` | **Opcional** | `false` | Activa el foco automáticamente al inicializarse. |
| `text` / `getter` | `string\|function` | **Opcional** | `""` | Valor textual inicial cargado en el campo. |
| `setter` | `function(text: string)` | **Opcional** | `nil` | Función que recibe el nuevo texto cuando cambia. |
| `onTextChanged` | `function(container, text, isUserInput)` | **Opcional** | `nil` | Evento ejecutado cada vez que el texto cambia. |
| `onEnterPressed` | `function(container, text)` | **Opcional** | `nil` | Evento ejecutado al presionar la tecla Enter. |
| `onEscapePressed`| `function(container)` | **Opcional** | `nil` | Evento ejecutado al presionar la tecla Escape. |
| `onFocusGained` | `function(container)` | **Opcional** | `nil` | Evento ejecutado al entrar en foco el cursor. |
| `onFocusLost` | `function(container)` | **Opcional** | `nil` | Evento ejecutado al perder el foco de edición. |
| `font` | `string` | **Opcional** | `styles.fonts.text` | Fuente tipográfica para el EditBox. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |
| `tooltip` | `string\|function` | **Opcional** | `nil` | Tooltip de ayuda al posicionar el cursor sobre el campo. |

- **Instance Methods (`container`)**:
  - `container:getText()` / `container:GetText()`: Returns current text.
  - `container:setText(text)` / `container:SetText(text)`: Updates text.
  - `container:clear()` / `container:Clear()`: Empties text.
  - `container:setPlaceholder(text)` / `container:SetPlaceholder(text)`.
  - `container:setNumeric(bool)` / `container:SetNumeric(bool)`.
  - `container:setMaxLetters(max)` / `container:SetMaxLetters(max)`.
  - `container:setFocus()` / `container:SetFocus()`.
  - `container:clearFocus()` / `container:ClearFocus()`.
  - `container:getEditBox()` / `container:GetEditBox()`.
  - `container:setEnabled(enabled)` / `container:SetEnabled(enabled)`.

---

### 9. `09Slider.lua`

#### `Context:createSlider(options)`
Precision slider and scrollbar supporting horizontal and vertical orientations, diamond/capsule/bar thumb geometry, progress fill bar, step snapping, inverted meter direction, fluid width stretching, and mouse wheel navigation.

- **Composite Elements**:
  - `slider` (`Frame`): Base bounds, outer border, inner track.
  - `slider.fill` (`Texture`): Progress fill bar (`showFill = true`).
  - `slider.thumb` (`Button`): Drag handle button supporting `"diamond"`, `"capsule"`, or `"bar"` geometry.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `orientation` | `string` | **Obligatorio** | *Ninguno (Error si falta)* | Orientación del deslizador: `"HORIZONTAL"` o `"VERTICAL"`. |
| `length` | `number` | **Obligatorio\*** | *Ninguno (Error si falta)* | Longitud total del track. Puede pasarse como `width` (horizontal) o `height` (vertical). (\*Opcional si `fluidWidth=true` y `orientation="HORIZONTAL"`). |
| `fluidWidth` | `boolean` | **Opcional** | `false` | Si es true (en orientación horizontal), expande el slider automáticamente hacia el borde derecho y recalcula el thumb al redimensionar. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al expandir con `fluidWidth=true`. |
| `thickness` | `number` | **Opcional** | `16` (Horizontal) / `14` (Vertical) | Grosor transversal del track. Puede pasarse como `height` (horizontal) o `width` (vertical). |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `minValue` / `min` | `number` | **Opcional** | `0` | Valor numérico mínimo del rango. |
| `maxValue` / `max` | `number` | **Opcional** | `100` | Valor numérico máximo del rango. |
| `step` / `stepSize` | `number` | **Opcional** | `1` | Incremento de paso para el salto discreto del valor. |
| `value` / `defaultValue` / `getter` | `number\|function` | **Opcional** | `minValue` (`0`) | Valor numérico inicial asignado al deslizador. |
| `setter` | `function(val: number)` | **Opcional** | `nil` | Callback ejecutado cuando el valor cambia. |
| `onValueChanged` | `function(slider, val, isUserInput)` | **Opcional** | `nil` | Callback detallado al cambiar de valor por ratón o teclado. |
| `showFill` / `fill` | `boolean` | **Opcional** | `false` | Muestra una barra de relleno de progreso desde el inicio hasta el thumb. |
| `fillColor` | `table` RGBA | **Opcional** | `styles.colors.primary` | Color RGBA de la barra de progreso. |
| `inverted` | `boolean` | **Opcional** | `false` | Invierte la dirección del progreso/valor (útil para medidores). |
| `thumbShape` | `string` | **Opcional** | `"diamond"` (Sliders) / `"capsule"` (Scrollbars) | Forma estética del tirador: `"capsule"` (píldora redondeada Blizzard), `"bar"` (rectángulo cyberpunk) o `"diamond"` (rombo 45°). |
| `thumbSize` / `thumbLength` | `number` | **Opcional** | `thickness - 2` | Longitud en píxeles del tirador en el eje de desplazamiento. |
| `thumbThickness` | `number` | **Opcional** | `thickness - 2` | Grosor en píxeles del tirador en el eje perpendicular. |
| `tooltip` | `string\|function` | **Opcional** | `nil` | Tooltip informativo al pasar el cursor. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods (`slider`)**:
  - `slider:getValue()` / `slider:GetValue()`: Returns current value.
  - `slider:setValue(val, isSilent, isUserInput)` / `slider:SetValue(val, isSilent, isUserInput)`: Updates current slider value.
  - `slider:setMinMaxValues(min, max)` / `slider:SetMinMaxValues(min, max)`: Sets lower and upper value bounds.
  - `slider:getMinMaxValues()` / `slider:GetMinMaxValues()`: Returns `min, max`.
  - `slider:setStep(step)` / `slider:SetStep(step)`: Updates step snapping increment.
  - `slider:setThumbSize(length, thickness)` / `slider:SetThumbSize(length, thickness)`: Updates thumb handle size.
  - `slider:setThumbShape(shape)` / `slider:SetThumbShape(shape)`: Sets thumb shape to `"capsule"`, `"bar"`, or `"diamond"`.
  - `slider:setEnabled(enabled)` / `slider:SetEnabled(enabled)`: Enables or disables interactivity.
  - `slider:enable()` / `slider:disable()` / `slider:isEnabled()`.

---

### 10. `10Stepper.lua`

#### `Context:createStepper(options)`
Joined numeric stepper combining minus button, centered input field, and plus button in a unified layout with continuous repeat ticker acceleration and fluid width adaptability.

- **Composite Elements**:
  - `stepper` (`Frame`): Outer wrapper frame.
  - `stepper.minusButton` (`IconButton`): Decrement button (`minus`).
  - `stepper.inputField` (`InputField`): Centered numerical input box (width: 2/5 of available space or fluidly stretched).
  - `stepper.plusButton` (`IconButton`): Increment button (`plus`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `width` | `number` | **Obligatorio\*** | *Ninguno (Error si falta)* | Ancho total del stepper. Debe ser al menos `height * 2 + 10`. (\*Opcional si se especifica `fluidWidth = true`). |
| `height` | `number` | **Obligatorio** | *Ninguno (Error si falta)* | Alto total del stepper y tamaño de los botones minus/plus. |
| `fluidWidth` | `boolean` | **Opcional** | `false` | Si es true, el stepper expande su ancho automáticamente hasta el margen derecho con layout continuo unido. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al expandir con `fluidWidth=true`. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `inputWidth` | `number` | **Opcional** | `max(40, floor((w - h*2 + 2) * 2/5))` | Ancho del campo de texto central (salvo en modo `fluidWidth`). |
| `minValue` / `min` | `number` | **Opcional** | `0` | Límite numérico inferior. |
| `maxValue` / `max` | `number` | **Opcional** | `100` | Límite numérico superior. |
| `step` / `stepSize` | `number` | **Opcional** | `1` | Cantidad de incremento/decremento por pulsación o giro de rueda. |
| `decimals` | `number` | **Opcional** | Auto-detectado del `step` o `0` | Número de decimales a formatear (`%.Nf`). |
| `value` / `defaultValue` / `getter` | `number\|function` | **Opcional** | `minValue` (`0`) | Valor numérico inicial cargado en el stepper. |
| `allowNegative` | `boolean` | **Opcional** | `false` *(o `true` si `minValue < 0`)* | Si se permite escribir o decrementar valores negativos. |
| `setter` | `function(val: number)` | **Opcional** | `nil` | Callback ejecutado al cambiar el valor. |
| `onValueChanged` | `function(stepper, val, isUserInput)` | **Opcional** | `nil` | Callback detallado al alterarse el valor. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods (`stepper`)**:
  - `stepper:getValue()` / `stepper:GetValue()`: Returns numerical value.
  - `stepper:setValue(val, isSilent, isUserInput)` / `stepper:SetValue(val, isSilent, isUserInput)`: Updates numerical value.
  - `stepper:setMinMaxValues(min, max)` / `stepper:SetMinMaxValues(min, max)`: Sets lower and upper value bounds.
  - `stepper:getMinMaxValues()` / `stepper:GetMinMaxValues()`: Returns `min, max`.
  - `stepper:setStep(step)` / `stepper:SetStep(step)`: Updates increment/decrement step amount.
  - `stepper:setEnabled(enabled)` / `stepper:SetEnabled(enabled)`: Toggles interactive state.
  - `stepper:enable()` / `stepper:Enable()`: Enables stepper and sub-controls.
  - `stepper:disable()` / `stepper:Disable()`: Disables stepper and sub-controls.

---

### 11. `.PresetColorPicker.lua`

#### `Context:createColorPicker(options)`
Creates a stylized color picker row with an interactive color swatch preview box and label text.

- **Composite Elements**:
  - `colorPicker` (`Button`): Interactive row button.
  - `colorPicker.swatchBorder` (`Texture`): Outer border for color swatch.
  - `colorPicker.swatchBackground` (`Texture`): Underlay for alpha transparency.
  - `colorPicker.swatchColor` (`Texture`): Active color preview fill.
  - `colorPicker.label` (`FontString`): Attached label text.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `text` | `string` | **Opcional** | `""` | Etiqueta de texto adyacente al cuadro de muestra de color (swatch). |
| `color` / `getter` | `table\|function` | **Opcional** | `{1, 1, 1, 1}` (Blanco) | Color RGBA inicial `{r, g, b, a}`. |
| `hasAlpha` | `boolean` | **Opcional** | `true` | Si se habilita el canal alfa / transparencia en los controles. |
| `swatchSize` / `boxSize` / `size` | `number` | **Opcional** | `buttonHeight` (`25`) | Tamaño cuadrado del cuadro de muestra de color en píxeles. |
| `width` | `number` | **Opcional** | Auto-calculado del texto | Ancho total del componente fila. |
| `setter` | `function(colorTable)` | **Opcional** | `nil` | Callback ejecutado tras confirmar la selección del color. |
| `onColorChanged` | `function(colorTable)` | **Opcional** | `nil` | Callback en tiempo real al arrastrar los sliders de color. |
| `onClick` | `function(self, color, btn, down)` | **Opcional** | `nil` | Callback adicional al pulsar el botón swatch. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods**:
  - `colorPicker:getColor()`: Returns `r, g, b, a, colorTable`.
  - `colorPicker:setColor(r, g, b, a)`: Sets color programmatically.
  - `colorPicker:setText(newText)`: Updates text and expands frame width.
  - `colorPicker:openColorPicker()`: Opens the modal color picker dialog for this swatch.

---

#### `Context:openColorPicker(options)` / `getOrCreateColorPickerDialog()`
Custom modal color picker dialog with live RGBA sliders, preview swatches, quick palette presets, and confirmation actions.

- **Composite Elements**:
  - `dialog` (`Frame`): Modal dialog window (`FULLSCREEN_DIALOG`).
  - `dialog.closeButton` (`IconButton`): Close button.
  - `dialog.previewOld`, `dialog.previewNew` (`Texture`): Color swatches.
  - `dialog.sliders` (`Slider[]`): 4 RGBA sliders (Red, Green, Blue, Alpha).
  - `dialog.paletteSwatches` (`Button[]`): Quick preset color buttons.
  - `dialog.acceptButton`, `dialog.cancelButton` (`DialogButton`).

##### Tabla de Opciones para `openColorPicker(options)`
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `initialColor` | `table` RGBA | **Opcional** | `{1, 1, 1, 1}` | Color inicial cargado en la paleta de previsualización. |
| `onAccept` | `function(colorTable)` | **Opcional** | `nil` | Callback invocado cuando el usuario pulsa Aceptar. |
| `onCancel` | `function(origColorTable)` | **Opcional** | `nil` | Callback invocado cuando el usuario pulsa Cancelar. |
| `onColorChanged` | `function(liveColorTable)` | **Opcional** | `nil` | Callback en tiempo real mientras el usuario manipula los sliders. |

---

### 12. `11Tooltip.lua`

#### `Context:createTooltip(options)` / `Context:getTooltip()`
Custom Obsidian Cyberpunk styled tooltip element with glowing headers, hierarchical text formatting, dynamic width/height fitting, and transparent integration with `UX/Hoverable.lua`.

- **Composite Elements**:
  - `tooltip` (`Frame`): Base container reusing `01Frame.lua` on `TOOLTIP` strata.
  - `tooltip.title` (`FontString`): Glowing orange primary title.
  - `tooltip.desc` (`FontString`): White auto-wrapped body description.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre en la jerarquía. |
| `maxWidth` | `number` | **Opcional** | `280` | Ancho máximo en píxeles antes de ajustar líneas de texto. |
| `minWidth` | `number` | **Opcional** | `160` | Ancho mínimo del contenedor de tooltip. |
| `padding` | `number` | **Opcional** | `12` | Margen interior (padding) en píxeles. |
| `frameLevel` | `number` | **Opcional** | `500` | Nivel z-index en la capa `TOOLTIP`. |
| `borderColor` | `table` RGBA | **Opcional** | `styles.colors.border` | Color RGBA del marco del tooltip. |
| `backgroundColor` | `table` RGBA | **Opcional** | `styles.colors.background` | Color RGBA del fondo del tooltip. |

- **Instance Methods**:
  - `tooltip:showAt(targetElement, titleText, descText, anchorPoint)`
  - `tooltip:hideTooltip()`
  - `tooltip:attachTo(frame, titleText, descText, anchorPoint)`

---

### 13. `12Dropdown.lua`

#### `Context:createDropdown(options)`
Custom Obsidian Cyberpunk styled dropdown select component with scrollable options list, procedural arrow icon, and automatic dismissal via `UX/ClickOutside.lua`.

- **Composite Elements**:
  - `dropdown` (`Button`): Trigger button displaying active selection, reusing `05Button.lua`.
  - `dropdown.arrowIcon` (`Button` / `IconButton`): Procedural arrow down icon.
  - `dropdown.listFrame` (`Frame`): Popup list container reusing `01Frame.lua` (`TOOLTIP` strata).
  - `dropdown.scrollFrame` (`ScrollFrame`): Viewport managed by `UX:makeScrollable` (using `09Slider.lua`).
  - Option items (`Button[]`): Selectable entries styled with `UX/Hoverable.lua`.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `options` | `table[]` | **Opcional** | `{}` | Array de opciones: strings (`{"A", "B"}`) o tablas (`{{ label = "A", value = 1, tooltip = "..." }}`). |
| `width` | `number` | **Opcional** | `160` | Ancho del botón disparador y de la lista desplegable en píxeles. |
| `fluidWidth` | `boolean` | **Opcional** | `false` | Si es true, el botón disparador y la lista desplegable adaptan su ancho dinámicamente al contenedor. |
| `fluidRightOffset` / `rightOffset` | `number` | **Opcional** | `-10` | Offset derecho en píxeles al expandir con `fluidWidth=true`. |
| `height` | `number` | **Opcional** | `26` | Alto del botón disparador en píxeles. |
| `itemHeight` | `number` | **Opcional** | `24` | Alto en píxeles de cada opción en la lista desplegable. |
| `maxVisibleItems` | `number` | **Opcional** | `6` | Cantidad máxima de elementos visibles antes de activar la barra de scroll. |
| `placeholder` | `string` | **Opcional** | `"Select..."` | Texto visible en el botón cuando no hay elemento seleccionado. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame contenedor. |
| `name` | `string` | **Opcional** | `nil` | Identificador global en `_G[name]`. |
| `getter` | `function(): any` | **Opcional** | `nil` | Función que devuelve el valor seleccionado actual. |
| `setter` | `function(val: any)` | **Opcional** | `nil` | Callback ejecutado cuando el usuario selecciona un nuevo valor. |
| `onValueChanged` | `function(dropdown, val, item)` | **Opcional** | `nil` | Callback detallado con el objeto item completo al cambiar selección. |
| `tooltip` | `string\|table` | **Opcional** | `nil` | Tooltip informativo en el botón principal. |
| `point` / `anchorPoint` | `string` | **Opcional** | `"TOPLEFT"` | Punto de anclaje relativo. |
| `relativeTo` | `Frame` | **Opcional** | `parent` | Objeto de referencia para anclaje. |
| `relativePoint` | `string` | **Opcional** | `point or "TOPLEFT"` | Punto en el objeto relativo. |
| `xOffset` | `number` | **Opcional** | `0` | Offset horizontal en píxeles. |
| `yOffset` | `number` | **Opcional** | `0` | Offset vertical en píxeles. |

- **Instance Methods**:
  - `dropdown:getValue()` / `dropdown:GetValue()`: Returns current selected value.
  - `dropdown:setValue(val, isSilent)` / `dropdown:SetValue(val, isSilent)`: Updates selection programmatically.
  - `dropdown:setOptions(newList)` / `dropdown:SetOptions(newList)`: Replaces options dynamically.
  - `dropdown:open()` / `dropdown:close()` / `dropdown:toggle()`

---

### 14. `13ContextMenu.lua`

#### `Context:createContextMenu(options)` / `UX:showContextMenu(parent, items, config)`
Pop-up right-click context menu positioned dynamically at mouse coordinates with outside-click dismissal.

- **Composite Elements**:
  - `menu` (`Frame`): Container reusing `01Frame.lua` (`TOOLTIP` strata).
  - Action items (`Button[]`): Menu buttons reusing `05Button.lua` with hover states.
  - Dividers (`Texture[]`): 1px separator lines (`text = "---"`).

##### Tabla de Opciones para `createContextMenu(options)`
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `items` | `table[]` | **Opcional** | `{}` | Lista de opciones `{ text = "...", func = function() end, tooltip = "..." }` o separadores `{ text = "---" }`. |
| `parent` | `Frame` | **Opcional** | `_G.UIParent` | Frame padre en la jerarquía. |
| `minWidth` | `number` | **Opcional** | `130` *(Auto-expande según el texto más largo)* | Ancho mínimo del menú emergente en píxeles. |
| `itemHeight` | `number` | **Opcional** | `22` | Alto de cada fila de opción en píxeles. |

##### Tabla de Opciones para `UX:showContextMenu(parent, items, config)`
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `parent` | `Frame` | **Obligatorio** | *Ninguno (Requerido)* | Frame de referencia o contenedor sobre el cual se invoca el menú contextual. |
| `items` | `table[]` | **Obligatorio** | *Ninguno (Requerido)* | Array de acciones del menú. Si se pasa `config`, añade automáticamente Lock y Reset. |
| `config` | `table` | **Opcional** | `nil` | Tabla de configuración de persistencia del addon (usada para botones auxiliares Lock y Reset). |

- **UX Helpers**:
  - `UX:addLockButton(items, frame, config)`
  - `UX:addResetPositionButton(items, frame, config)`
  - `UX:addOptionsButton(items, onClick)`

---

### 14. `14Toast.lua`

#### `Context:createToast(options)` / `Context:showToast(options)`
Obsidian Cyberpunk HUD notification toast component and FIFO queue manager with auto-dismiss timers, native `AnimationGroup` alpha fades, hover-to-pause countdown, optional vector/status icons, countdown progress bar, and clickable action support.

- **Composite Elements**:
  - `toast` (`Frame`): Obsidian Cyberpunk container frame created via `01Frame.lua`.
  - `toast.closeButton` (`Button` / `IconButton`): Top-right `X` icon button (`05Button.lua`).
  - `toast.titleLabel` (`FontString`): Bold title text (`styles.fonts.label`).
  - `toast.messageLabel` (`FontString`): Multiline word-wrapped body description (`styles.fonts.text`).
  - `toast.iconFrame` (`Frame` / `Texture`): Optional status icon (vector checkmark, cross, exclamation, or atlas/fileId).
  - `toast.progressBar` (`StatusBar`): Optional countdown timer progress bar depleting across `duration`.
  - `toast.animFadeIn` / `toast.animFadeOut` (`AnimationGroup`): Hardware-accelerated alpha transition animations.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `title` | `string` | **Opcional** | `"Notification"` | Texto de encabezado principal del toast. |
| `message` | `string` | **Opcional** | `""` | Mensaje descriptivo con ajuste multilínea automático. |
| `type` | `string` | **Opcional** | `nil` | Variante semántica (`"info"`, `"success"`, `"warning"`, `"error"`). Configura icono vectorial y color de borde. |
| `duration` | `number` | **Opcional** | `4` | Tiempo en segundos antes del cierre automático. Pasar el cursor pausa el temporizador. |
| `showProgress` | `boolean` | **Opcional** | `false` | Muestra una barra de estado inferior que se vacía reflejando el tiempo restante. |
| `icon` | `string` / `number` | **Opcional** | `nil` | Textura personalizada de WoW, ID de archivo o nombre de Atlas (ej. `"Interface\\Icons\\..."`). |
| `iconSize` | `number` | **Opcional** | `20` | Dimensión cuadrada en píxeles del icono de estado. |
| `onClick` | `function` | **Opcional** | `nil` | Callback ejecutado al hacer click izquierdo sobre el cuerpo del toast (`function(toast) ... end`). |
| `onDismiss` | `function` | **Opcional** | `nil` | Callback ejecutado cuando el toast termina su animación de desvanecimiento y se oculta. |
| `width` | `number` | **Opcional** | `280` | Ancho del toast en píxeles. |
| `minHeight` | `number` | **Opcional** | `54` | Altura mínima en píxeles (auto-expande si el texto multilínea es largo). |
| `padding` | `number` | **Opcional** | `12` | Margen interno entre los bordes y el contenido textual en píxeles. |
| `borderColor` | `table` RGBA | **Opcional** | Auto por `type` o `styles.colors.border` | Color RGBA explícito para el borde perimetral. |
| `backgroundColor` | `table` RGBA | **Opcional** | `styles.colors.background` | Color RGBA de la superficie de fondo. |
| `titleColor` | `table` RGBA | **Opcional** | `styles.colors.white` | Color del texto del título. |
| `messageColor` | `table` RGBA | **Opcional** | `styles.colors.surfaceHover` | Color del cuerpo del mensaje. |
| `strata` | `string` | **Opcional** | `"TOOLTIP"` | Frame strata para asegurar visibilidad sobre ventanas activas. |
| `frameLevel` | `number` | **Opcional** | `800` | Nivel Z-index del frame contenedor. |

##### Tabla de Configuración del Gestor de Cola (`Context:configureToasts(config)`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `anchor` | `string` | **Opcional** | `"TOPRIGHT"` | Punto de anclaje en la pantalla o frame relativo (`"TOPRIGHT"`, `"TOPLEFT"`, etc.). |
| `relativeTo` | `Frame` | **Opcional** | `_G.UIParent` | Frame de referencia donde se anclan los toasts. |
| `xOffset` | `number` | **Opcional** | `-20` | Desplazamiento horizontal inicial respecto al ancla. |
| `yOffset` | `number` | **Opcional** | `-80` | Desplazamiento vertical inicial respecto al ancla. |
| `direction` | `string` | **Opcional** | `"DOWN"` | Dirección de apilamiento de las alertas (`"DOWN"` o `"UP"`). |
| `spacing` | `number` | **Opcional** | `10` | Separación en píxeles entre toasts consecutivos en la pila. |
| `maxVisible` | `number` | **Opcional** | `4` | Cantidad máxima de alertas simultáneas en pantalla. Las excedentes entran a la cola FIFO. |
| `defaultDuration` | `number` | **Opcional** | `4` | Duración predeterminada en segundos asignada si la alerta no especifica una. |

- **Métodos Públicos del Objeto Toast**:
  - `toast:Dismiss()`: Inicia la animación `FadeOut` y retira la alerta de la pila activa, desencadenando el reacomodo y procesado del siguiente elemento en cola.

---

### 15. `15ColorPicker.lua`

#### `Context:createColorPicker(options)` / `Context:getOrCreateColorPickerDialog()`
Obsidian Cyberpunk interactive color picker component and compact modal dialog (`280x220`). Features inline RGBA gradient sliders, interactive Hex input field (`#RRGGBB`), vector checkerboard opacity underlay, live target preview, click-to-revert original color, and an 8-slot session-persistent recent colors history.

- **Composite Elements**:
  - `colorPicker` (`Button`): Consuming UI trigger button with integrated color swatch.
  - `colorPicker.swatchWrap` (`Frame`): Swatch container with checkerboard background.
  - `colorPicker.swatchColor` (`Texture`): Active color fill layer.
  - `colorPicker.label` (`FontString`): Text label to the right of the swatch.
  - `dialog` (`Frame`): Modal dialog frame (`01Frame.lua`, `280x220`) with close button and Escape closure.
  - `dialog.currentContainer` (`Button`): Starting color swatch (clickable to revert).
  - `dialog.newContainer` (`Frame`): Working target color swatch with checkerboard underlay.
  - `dialog.hexInput` (`Frame` / `EditBox`): Interactive Hex input (`08InputField.lua`).
  - `dialog.sliders` (`table`): Compact inline R, G, B, A horizontal sliders (`09Slider.lua`) with dynamic track gradients.
  - `dialog.recentSwatches` (`Button[]`): 8-slot session-persistent recent colors history row.

##### Tabla de Opciones de Configuración (`options`) para `Context:createColorPicker`
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `color` | `table` RGBA | **Opcional** | `{1, 1, 1, 1}` | Color inicial `{r, g, b, a}` o `{1, 1, 1, 1}`. |
| `text` | `string` | **Opcional** | `""` | Etiqueta de texto descriptiva a la derecha del swatch. |
| `width` | `number` | **Opcional** | Auto-ajustado | Ancho total del botón disparador en píxeles. |
| `swatchSize` | `number` | **Opcional** | `height - 4` | Dimensión cuadrada en píxeles de la caja de color. |
| `hasAlpha` | `boolean` | **Opcional** | `true` | Habilita soporte y control del canal de opacidad/transparencia Alpha. |
| `getter` | `function` | **Opcional** | `nil` | Función que retorna el color inicial dinámicamente (`function() return r,g,b,a end`). |
| `setter` | `function` | **Opcional** | `nil` | Callback ejecutado al confirmar ("Accept") un nuevo color (`function(color, r,g,b,a) ... end`). |
| `onChange` | `function` | **Opcional** | `nil` | Callback ejecutado en tiempo real al arrastrar sliders o cambiar Hex (`function(color, r,g,b,a) ... end`). |
| `onClick` | `function` | **Opcional** | `nil` | Callback auxiliar al hacer click sobre el botón antes de abrir el modal. |

- **Métodos Públicos del Objeto ColorPicker**:
  - `colorPicker:getColor()` -> `r, g, b, a, colorTable`
  - `colorPicker:setColor(r, g, b, a)`: Actualiza y confirma un nuevo color en el widget.
  - `colorPicker:setText(text)`: Modifica el texto de la etiqueta descriptiva.
  - `colorPicker:openColorPicker()`: Abre el diálogo modal de selección de color.

---

### 16. `UX/Scrollable.lua`

#### `UX:makeScrollable(container, options)`
UX capability that transforms any frame into a scrollable viewport with an integrated vertical `09Slider.lua` scrollbar with capsule styling and Shift-accelerated mouse wheel scrolling.

- **Composite Elements**:
  - `scrollFrame` (`ScrollFrame`): Viewport frame created inside the container.
  - `contentChild` (`Frame`): Scrollable canvas child hosting all user widgets.
  - `scrollbar` (`Slider`): Vertical `09Slider.lua` scrollbar attached to the right.

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `container` | `Frame` | **Obligatorio** | *Ninguno (Requerido)* | Frame que se convertirá en un viewport desplazable con ScrollFrame y Content Frame. |
| `options.scrollBarWidth` | `number` | **Opcional** | `12` | Ancho en píxeles de la barra de desplazamiento vertical. |
| `options.scrollBarGap` | `number` | **Opcional** | `4` | Separación en píxeles entre el contenido y la barra de desplazamiento. |
| `options.step` | `number` | **Opcional** | `30` | Cantidad de desplazamiento en píxeles por cada paso de rueda del ratón (Shift = 3x). |
| `options.autoHideScrollBar` | `boolean` | **Opcional** | `true` | Oculta la barra de desplazamiento si el contenido no excede la altura visible. |
| `options.thumbShape` | `string` | **Opcional** | `"capsule"` | Forma estética del tirador de scroll (`"capsule"`, `"diamond"`, `"bar"`). |
| `options.bottomPadding` | `number` | **Opcional** | `16` | Margen inferior adicional en píxeles para asegurar que el último elemento no quede pegado. |

- **Return Value**:
  - `scrollFrame, contentChild, scrollbar` (`ScrollFrame, Frame, Slider`).
- **Attached Container Methods**:
  - `container:updateScrollRange()`: Recalculates total content height from children and adjusts slider min/max, view range, and thumb size.

---

### 17. `UX/Resizable.lua`

#### `UX:makeResizable(frame, options)` / `UX:makeResizable(frame, minWidth, minHeight, maxWidth, maxHeight)`
Capacidad UX que transforma un frame en una ventana redimensionable agregando una manija táctil en forma de bracket angular ("L" invertida de 4 px de grosor y 16 px de longitud) en la esquina inferior derecha (`BOTTOMRIGHT`). Utiliza la paleta metálica Obsidian Cyberpunk (`steelBase`, `steelHover`, `steelActive`) y transiciones reactivas al cursor.

- **Composite Elements**:
  - `frame` (`Frame`): Frame interactivo configurado con `SetResizable(true)`.
  - `frame.resizeBtn` (`Button`): Botón interactivo de 24x24 px en `BOTTOMRIGHT` con nivel `FrameLevel + 10`.
  - `resizeBtn.hBar` (`Texture`): Barra horizontal inferior del bracket (24x8 px, `WHITE8X8`).
  - `resizeBtn.vBar` (`Texture`): Barra vertical derecha del bracket (8x24 px, `WHITE8X8`).

##### Tabla de Opciones de Configuración (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `frame` | `Frame` | **Obligatorio** | *Ninguno (Requerido)* | Frame contenedor que se habilitará para redimensionamiento. |
| `options.minWidth` / `minW` | `number` | **Opcional** | `0` | Ancho mínimo permitido al redimensionar en píxeles. |
| `options.minHeight` / `minH` | `number` | **Opcional** | `0` | Alto mínimo permitido al redimensionar en píxeles. |
| `options.maxWidth` / `maxW` | `number` | **Opcional** | `0` | Ancho máximo permitido al redimensionar (`0` = sin límite). |
| `options.maxHeight` / `maxH` | `number` | **Opcional** | `0` | Alto máximo permitido al redimensionar (`0` = sin límite). |
| `options.gripSize` | `number` | **Opcional** | `24` | Longitud en píxeles de los brazos del bracket angular y botón de agarre. |
| `options.gripThickness` | `number` | **Opcional** | `8` | Grosor en píxeles de los brazos del bracket angular de esquina. |
| `options.onResizeStop` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado al terminar la redimensión (`OnMouseUp`). |
| `options.onSizeChanged` | `function(frame, width, height)` | **Opcional** | `nil` | Callback ejecutado continuamente mientras cambia de tamaño (`OnSizeChanged`). |

- **Métodos y Propiedades Adjuntas al Frame**:
  - `frame.resizeBtn` (`Button`): Referencia pública al botón de redimensión en la esquina.
  - `frame:SetResizable(true)`: Habilitado por WoW nativo.
  - `frame:SetResizeBounds(minW, minH, maxW, maxH)`: Límites dimensionales configurados.

---

### 18. `Core/LayoutModel.lua`

#### Responsive Capability Engine & Component Wrappers
Motor de maquetación y posicionamiento dinámico vertical/columnar con motor reactivo de breakpoints (`normal` vs `compact`), propagación a elementos registrados, cálculo de anchos disponibles, wrappers con soporte de componentes fluidos y apilamiento columnar adaptativo automático.

##### Constructor y Activación Automática
El modelo de layout puede instanciarse mediante `Context:createLayoutModel(parent, options)` o reiniciarse con `layout:reset(parent, options)`. Si `options.responsive ~= false`, el sistema activa automáticamente la observación responsiva en tiempo real sobre el contenedor.

##### Tabla de Opciones del Layout (`options`)
| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `responsive` | `boolean` | **Opcional** | `true` | Activa automáticamente la capacidad responsiva y la observación del contenedor. |
| `threshold` | `number` | **Opcional** | `480` | Punto de quiebre en píxeles para alternar entre modo `"normal"` ($\ge 480$px) y `"compact"` ($< 480$px). |
| `onModeChange` | `function` | **Opcional** | `nil` | Callback ejecutado al cambiar de breakpoint: `function(layout, mode, width, height)`. |
| `frame` | `Frame` | **Opcional** | `parent` | Frame de referencia a observar para eventos `OnSizeChanged`. |
| `verticalGap` | `number` | **Opcional** | `6` | Separación vertical por defecto entre elementos consecutivos. |

##### Métodos del Motor Responsivo
| Método | Parámetros | Retorno | Descripción |
| :--- | :--- | :--- | :--- |
| `layout:enableResponsive(options)` | `options`: `{ threshold=480, frame=parent, onModeChange=func, alwaysNotify=bool }` | `void` | Activa la observación de `OnSizeChanged` en el frame con debouncing de 50ms y transiciones de modo. |
| `layout:notifyResponsive(newMode, width, height)` | `newMode`: `"normal"` \| `"compact"`, `width`: `number`, `height`: `number` | `void` | Notifica la transición de modo a todos los elementos registrados, al callback `onModeChange` y actualiza el viewport scrollable. |
| `layout:registerResponsiveElement(element, callback)` | `element`: `table`, `callback`: `function(element, mode, width, height)` | `void` | Registra un elemento UI para recibir notificaciones reactivas de cambio de modo responsivo. |
| `layout:getAvailableWidth(padding, element)` | `padding`: `number` (opcional, default `0`), `element`: `table` (opcional) | `number` | Calcula y retorna el ancho utilizable disponible en píxeles dentro del contenedor o frame padre del elemento. |
| `layout:updateScrollRangeIfAvailable()` | *Ninguno* | `void` | Inspecciona el contenedor activo y sus ancestros; si pertenecen a un viewport de `Scrollable.lua`, invoca `updateScrollRange()`. |

##### Gestión de Columnas Adaptativas
| Método | Parámetros | Descripción |
| :--- | :--- | :--- |
| `layout:beginColumn(xOffsetOrOptions, width)` | `xOffsetOrOptions`: `number` \| `table`, `width`: `number` | Inicia una columna. Admite coordenadas fijas `beginColumn(10, 200)` o tabla `beginColumn({ width = 0.5, gap = 12 })`. Si `width <= 1.0`, se interpreta como proporción porcentual. |
| `layout:endColumn()` | *Ninguno* | Cierra la columna actual, ajusta su anclaje inferior al último elemento agregado y calcula la altura estimada. |
| `layout:applyColumnLayout(group, mode, totalWidth)` | `group`: `table`, `mode`: `string`, `totalWidth`: `number` | Aplica el ordenamiento visual: en modo `"normal"` coloca columnas en paralelo lado a lado; en modo `"compact"` apila automáticamente las columnas de forma vertical al 100% de ancho. |
| `layout:columnsFinalize(contentFrame, bottomPadding)` | `contentFrame`: `Frame` (opcional), `bottomPadding`: `number` (opcional) | Balancea las alturas de las columnas, ancla la base del grupo a la columna más alta, registra el listener responsivo para redimensionamiento en vivo y opcionalmente ancla el contenedor maestro. |

##### Wrappers de Componentes Adaptativos en `LayoutModel`
Todos los controles interactivos heredan automáticamente `fluidWidth = true` si el layout es responsivo y no se especifica un ancho estático fijo.
| Wrapper | Opciones Responsivas Clave | Comportamiento |
| :--- | :--- | :--- |
| `layout:header(id, text, options)` | `elasticWidth=true`, `wordWrap=true`, `rightOffset=-10` | Ancla el extremo derecho al contenedor padre activando wrap automático sin alterar `fontSize`. |
| `layout:label(id, text, options)` | `elasticWidth=true`, `wordWrap=true`, `rightOffset=-10` | Ancla el extremo derecho al contenedor padre activando wrap automático. |
| `layout:paragraph(id, text, rightOffset)` | `rightOffset=-10` | Envoltura de texto multilínea con auto-wrap delimitado por margen derecho. |
| `layout:button(id, options, ...)` | `fluidWidth=true`, `rightOffset=-10` | Botón adaptable al ancho disponible de la columna o contenedor padre. |
| `layout:toggle(id, options, ...)` | `flexRow=true`, `text="..."`, `rightOffset=-10` | Fila adaptable al 100% de ancho con switch a la derecha y etiqueta izquierda con wordWrap. |
| `layout:checkbox(id, options, ...)` | `flexRow=true`, `text="..."`, `rightOffset=-10` | Fila adaptable al 100% de ancho con casilla a la derecha y etiqueta izquierda con wordWrap. |
| `layout:inputField(id, options, ...)` | `fluidWidth=true`, `rightOffset=-10` | Ancho fluido con auto-anclaje a la derecha y redimensión adaptativa de EditBox en multilínea. |
| `layout:slider(id, options, ...)` | `fluidWidth=true`, `rightOffset=-10` | Slider horizontal adaptativo con reposicionamiento dinámico de thumb y barra de progreso. |
| `layout:stepper(id, options, ...)` | `fluidWidth=true`, `rightOffset=-10` | Stepper fluido con layout unido: minus a la izquierda, plus a la derecha e input central flexible. |
| `layout:dropdown(id, options, ...)` | `fluidWidth=true`, `rightOffset=-10` | Selector dropdown fluido con lista emergente y botones de opción dimensionados al ancho del botón. |


