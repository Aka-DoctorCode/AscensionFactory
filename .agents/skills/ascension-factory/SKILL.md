---
name: ascension-factory
description: >-
  Especialista integral en el framework AscensionFactory para World of Warcraft: arquitectura OOP,
  reciclaje de widgets, catálogo completo de constructores Context:create*, motor de layout
  responsivo (LayoutModel, LayoutBuilder, ColumnGroup, UX:makeResponsive), secciones, scrollables
  y reglas de seguridad/sincronización. Usar siempre que se consulte, modifique, extienda o
  implemente UI dentro de AscensionFactory o en addons consumidores.
---

# Skill: Desarrollo, Arquitectura y Layout en AscensionFactory

Esta skill unifica la arquitectura interna, las reglas de seguridad, el catálogo de constructores de bajo nivel (`Context:create*`) y la guía práctica del motor de posicionamiento responsivo (`LayoutModel` + `LayoutBuilder` + `03ColumnGroup` + `UX/Responsive`) de [`AscensionFactory`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory).

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
> ### REGLA 2: SINCRONIZACIÓN OBLIGATORIA DE DOCUMENTACIÓN Y REPOSITORIOS
> Cada vez que se cree un nuevo componente, se altere un constructor, se agregue un método o se modifiquen parámetros:
> - Es **ESTRICTAMENTE OBLIGATORIO** actualizar [`Components/README.md`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/Components/README.md) manteniendo el formato de tabla de auditoría:
>   `| Parámetro | Tipo | Requisito | Valor por Defecto | Descripción |`.
> - Distinguir claramente entre parámetros **Obligatorios** y **Opcionales** con sus valores por defecto exactos.
> - Actualizar el [`README.md`](file:///Applications/World%20of%20Warcraft/_retail_/Interface/AddOns/AscensionFactory/README.md) principal de la raíz, que incluye el contenido completo de `Components/README.md` sin eliminar `Components/README.md`.
> - Mantener sincronizados los directorios de Retail (`/Applications/World of Warcraft/_retail_/Interface/AddOns/AscensionFactory`) y Desarrollo (`/Users/franciscomolina/Dev/WOW AddOns/AscensionFactory`).

> [!TIP]
> ### REGLA 3: REUTILIZACIÓN ESTRICTA Y OOP (NO REINVENTAR LA RUEDA)
> Si necesitas un botón, slider, slider con stepper, toggle, checkbox, input, color picker, tooltip, toast, acordeón, grupo de columnas o menú, **NUNCA** crees un frame o widget desde cero con `CreateFrame`. Usa los wrappers de `LayoutModel`/`LayoutBuilder` (`layout:button`, `layout:toggle`, `layout:row`, etc.) o llama al constructor de `Context` (`Context:createButton`, `Context:createSliderWithStepper`, `Context:createColumnGroup`, etc.).

---

## 2. Arquitectura de Software del Framework

`AscensionFactory` sigue un patrón orientado a objetos (OOP) desacoplado, modular y con pooling intensivo:

```
AscensionFactory/
├── Core/
│   ├── Core.lua               # Registro en LibStub, detección de addonName y Prototipo Context
│   ├── Context.lua            # Tokens de diseño Obsidian Cyberpunk (colores, fuentes, estilos)
│   ├── FrameworkPool.lua      # Gestión y reciclaje de pools de widgets de WoW
│   ├── PositionManager.lua    # Capa exclusiva de persistencia de coordenadas y dimensiones (_G.AscensionUIPositions)
│   ├── LayoutModel.lua        # Motor puro de apilamiento relativo, tamaño trifásico y tracking de altura
│   └── LayoutBuilder.lua      # Facade fluida sobre LayoutModel (wrappers, row, sections, columns) + auto-anclaje en Context
├── UX/
│   ├── ClickOutside.lua       # Detección modal de clicks fuera de ventanas emergentes
│   ├── Hoverable.lua          # Estados hover/active/disabled y enlace con tooltips
│   ├── Closable.lua           # Cierre con tecla Escape (UISpecialFrames) y reciclaje opcional
│   ├── Draggable.lua          # Interacción de arrastrar con el ratón (delega persistencia a PositionManager)
│   ├── Resizable.lua          # Manija metálica de redimensión en esquina (delega tamaño a PositionManager)
│   ├── Responsive.lua         # Coordinador responsivo con debounce (breakpoints "normal" / "compact")
│   └── Scrollable.lua         # Viewports scrollables reciclando 09Slider.lua
├── Components/                # Catálogo de constructores UI modulares
│   ├── 01Frame.lua            # Ventanas base (createFrame) y principales (createMainFrame)
│   ├── 02TabbedInterface.lua  # Navegación con pestañas colapsables y paneles auto-scroll
│   ├── 03TwoColumn.lua        # Layout clásico dividido 50/50 con auto-apilamiento responsivo
│   ├── 03ColumnGroup.lua      # Contenedor multi-columna N-columnas autónomo y responsivo (createColumnGroup)
│   ├── 04Text.lua             # Headers, Labels y Paragraphs con ajuste elástico (wordWrap)
│   ├── 05Button.lua           # Buttons, IconButtons (vectores), DialogButtons y DialogButtonGroup
│   ├── 06Toggle.lua           # Switch binario animado con soporte flexRow
│   ├── 07Checkbox.lua         # Checkbox con checkmark vectorizado y soporte flexRow
│   ├── 08InputField.lua       # Inputs de texto mono/multilínea con ScrollFrame y fluidWidth
│   ├── 09Slider.lua           # Sliders H/V (createSlider) y Slider compuesto con Stepper (createSliderWithStepper)
│   ├── 10Stepper.lua          # Incrementador numérico unido con input central y repeat ticker
│   ├── 11Tooltip.lua          # Tooltips Cyberpunk con ajuste dinámico (max 1/3 ancho x 9/10 alto de pantalla)
│   ├── 12Dropdown.lua         # Select desplegable con lista scrollable y fluidWidth
│   ├── 13ContextMenu.lua      # Menú contextual emergente por click derecho e integración con PositionManager
│   ├── 14Toast.lua            # Alertas HUD compactas con cola FIFO, temporizadores y persistencia en PositionManager
│   ├── 15ColorPicker.lua      # Fila limpia con botón cuadrado 24x24 (swatchButton) y modal RGBA con persistencia de posición
│   ├── 16Accordion.lua        # Tarjeta colapsable (Card Accordion) con encabezado estilizado, flecha rotatoria y sub-LayoutModel
│   └── README.md              # Auditoría completa de parámetros, tipos, obligatoriedad y valores por defecto
└── Integration/
    └── BlizzardOptions.lua    # Integración con Settings.RegisterCanvasLayoutCategory
```

---

## 3. Patrones Clave de Implementación

### 3.1 Prototipo Maestro `Context` (`Core/Core.lua`)
- `lib.Context` es el prototipo donde se registran todos los constructores de componentes.
- `Context.__index = Context` proporciona herencia OOP en Lua.
- Obtención de instancia en un addon consumidor:
  ```lua
  local AF = LibStub("AscensionFactory")
  local UI = AF:createContext(customStyles)
  ```
- `createContext` detecta automáticamente el nombre del AddOn emisor (`context.addonName`) inspeccionando el `debugstack`, alimentando valores por defecto como el título de notificaciones en `14Toast.lua` y su clave de posición.

### 3.2 Separación de Persistencia (`PositionManager`) vs Interacción (`Draggable` & `Resizable`)
- **`Core/PositionManager.lua`**: Gestiona **exclusivamente** lectura, escritura, aplicación y reseteo de coordenadas (`point`, `relativePoint`, `x`, `y`) y dimensiones (`width`, `height`) en `_G.AscensionUIPositions` (o tabla `SavedVariables` personalizada):
  - `initPositionStorage(moduleKey, defaultTable, storageTableName)`
  - `updatePositionFromFrame(frame, positionTable)` / `applySavedPosition(frame, positionTable, relativeTo)`
  - `updateSizeFromFrame(frame, positionTable)` / `applySavedSize(frame, positionTable)`
  - `resetPosition(frame, positionTable, defaultTable, relativeTo)`
  - `resolveStorageTable(frame, config)`
- **`UX/Draggable.lua` (`UX:makeMovable(frame, config)`)**: Solo arrastre con ratón. **Exige** `config.savePosition` (`true` o `false` explícito).
- **`UX/Resizable.lua` (`UX:makeResizable(frame, options)`)**: Manija de redimensión inferior derecha. **Exige** `options.saveSize` (`true` o `false` explícito).
- **Módulos conectados con `PositionManager`**: `01Frame.lua`, `13ContextMenu.lua` (`addLockButton`, `addResetPositionButton`), `14Toast.lua` (`toastManager`), `15ColorPicker.lua` (`AscensionFactoryColorPickerDialog`).

### 3.3 Coordinador Responsivo Independiente (`UX/Responsive.lua`)
- `UX:makeResponsive(containerFrame, options)` adjunta un coordinador debounced (`debounce = 0.05` s por defecto) que evalúa `threshold` (defecto `480` px) para alternar entre modo `"normal"` y `"compact"`, notificando a sus suscriptores (`coordinator:registerSubscriber(elementOrCallback, callback)`) sin acoplarse obligatoriamente a `LayoutModel`.

### 3.4 Composición de Componentes
- `createMainFrame` = `createFrame` + `createIconButton` (cerrar) + `UX:makeMovable` + `UX:makeResizable` + `UX:makeClosableWithEscape`.
- `createCheckbox` = `createButton` (fila limpia) + caja de 25x25 px + texturas vectoriales de palomita + `label` con soporte `flexRow`.
- `createColorPicker` = `createButton` (fila limpia) + botón cuadrado 24x24 px (`swatchButton`, `swatchSize = 24`) con damero alfa + `label` con `flexRow` + diálogo modal compartido (`getOrCreateColorPickerDialog`).
- `createStepper` = contenedor (`height = 24` por defecto) + dos `createIconButton` (`minus`/`plus`) + `createInputField` central con repeat ticker.
- `createSliderWithStepper` = `createSlider` horizontal + `createStepper` fluido anclado debajo (`slider.stepper`) con sincronización bidireccional automática.

---

## 4. Motor de Layout (`LayoutModel` + `LayoutBuilder` + `03ColumnGroup`)

En la arquitectura actual, `Core/LayoutModel.lua` es el motor puro de anclaje relativo y tamaño trifásico, mientras que `Core/LayoutBuilder.lua` mezcla sobre `LayoutModel` la facade fluida de alto nivel (wrappers, `row`, secciones y columnas) y registra un interceptor en `Context` para auto-anclar cualquier widget creado con `{ layout = myLayout }`.

### 4.1 Inicialización y Ciclo de Vida
```lua
-- Opción A: Desde el Contexto UI (Recomendado)
local layout = uiContext:createLayoutModel(parentFrame, options)

-- Opción B: Directo desde la librería
local AF = LibStub("AscensionFactory")
local layout = AF.LayoutModel:new(uiContext, parentFrame, options)

-- Opción C: Facade standalone LayoutBuilder
local builder = AF.LayoutBuilder:new(uiContext, layout)
```
Opciones de `options` (o un número equivalente a `{ startY = number }`):
- `verticalGap` / `gap` (número, defecto `uiContext:getDefaultGap()` o `10`): Espaciado vertical entre elementos.
- `bottomPadding` (número, defecto igual a `defaultGap`): Margen inferior reservado.
- `startY` (número, opcional): Offset vertical inicial antes del primer elemento.
- `threshold` (número, defecto `480`): Ancho en píxeles entre modo `"normal"` y `"compact"`.
- `responsive` (booleano, defecto `true`): Conecta `UX:makeResponsive` al contenedor padre (salvo `responsive = false`).
- `onModeChange` (función `fn(layout, mode, width, height)`): Callback al cambiar de modo responsivo.
- `onContainerResized` (función): Callback al recalcular altura del contenedor.
- `scrollable` o `autoScroll` (booleano): Delega en `UX:makeScrollable(parentFrame)` y apunta `currentParent` al `scrollChild`.
- `scrollStep` (número, defecto `30`): Paso de rueda del ratón.

Para reciclar una instancia sin generar basura (GC):
```lua
layout:reset(parentFrame, options)
```

### 4.2 Motor de Anclaje, Auto-Anclaje y Espaciado
- `layout:addSpace(pixels)`: Separa verticalmente solo al siguiente elemento (enruta al sub-layout activo si estás dentro de una sección/columna).
- `layout:addIndent(pixels)`: Aplica desplazamiento horizontal `X` único al siguiente elemento.
- `layout:getAvailableWidth(padding, element)`: Retorna el ancho útil disponible dentro del contenedor actual.
- `layout:add(element, options)`: Ancla manualmente un widget al flujo vertical del layout.
- `layout:recalculateAccumulatedHeight()`, `layout:onChildResized(child, newHeight)`, `layout:updateScrollRangeIfAvailable()`: Sincronización dinámica de altura y rango de scroll.
- **Auto-anclaje desde `Context`**: Al pasar `layout = myLayout` en la tabla de opciones de cualquier constructor estándar de `Context` (`createButton`, `createSliderWithStepper`, `createColumnGroup`, etc.), `LayoutBuilder` lo ancla automáticamente vía `registerCreatedElement` sin necesidad de llamar a `layout:add(...)`.

### 4.3 Catálogo de Wrappers en `LayoutModel` / `LayoutBuilder`
Todos devuelven la referencia del widget creado y soportan firmas híbridas (argumentos posicionales o tabla `opts`). Además, **normalizan automáticamente `opts.tooltip = false` si `tooltip == nil`**:
- `layout:header(elementID, text, options)`
- `layout:label(elementID, text, options)`
- `layout:paragraph(elementID, textOrOptions, rightOffset)`
- `layout:button(elementID, textOrOptions, tooltip, width, height, onClick)` (soporta `opts.variant` y `fluidWidth`)
- `layout:toggle(elementID, getterOrOptions, setter, width, height, onClick)`
- `layout:checkbox(elementID, textOrOptions, getter, setter, size, onClick)`
- `layout:colorPicker(elementID, textOrOptions, tooltip, getter, setter, hasAlpha, options)` (soporta `hasAlpha`, getter/setter `(r, g, b, a)`)
- `layout:slider(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)`
- `layout:sliderWithStepper(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)` (devuelve `(sliderElement, stepperElement)`)
- `layout:stepper(elementID, textOrOptions, minValue, maxValue, step, getter, setter, options)`
- `layout:inputField(elementID, textOrOptions, width, height, options)` (alias `layout:input`)
- `layout:dropdown(elementID, textOrOptions, optionsList, getter, setter, options)`
- `layout:accordion(elementID, textOrOptions, populateFn, options)` (tarjeta colapsable con sub-`LayoutModel` aislado y re-anclaje automático de hermanos verticales)

### 4.4 Secciones Agrupadas (`beginSection` / `endSection`)
Agrupa elementos dentro de una tarjeta con fondo y bordes del tema usando un sub-layout aislado:
```lua
layout:beginSection() -- width opcional; nil para ancho fluido
    layout:header("Sec1_Header", "Configuración de Módulos")
    layout:toggle("Sec1_Toggle", getter, setter)
layout:endSection()
```

### 4.5 Columnas Responsivas: Patrón Moderno (`row` / `ColumnGroup`) vs Legacy
**Patrón moderno recomendado (`layout:row` / `Context:createColumnGroup`)**:
Construye una fila multi-columna autónoma de forma declarativa sin mutar el estado de cursores del `layout` padre:
```lua
layout:row({
    gap = 12,
    threshold = 480,
    columns = {
        {
            width = 0.5, -- <= 1 proporcional, > 1 píxeles fijos, nil automático
            populate = function(colLayout, colFrame)
                colLayout:header("DisplayHeader", "Visualización")
                colLayout:sliderWithStepper("Scale", "Escala", 0.5, 2.0, 0.1,
                    function() return db.scale end,
                    function(v) db.scale = v end
                )
            end,
        },
        {
            width = 0.5,
            populate = function(colLayout, colFrame)
                colLayout:header("ColorsHeader", "Colores")
                colLayout:colorPicker("BorderColor", "Color de Borde", false,
                    function() return unpack(db.borderColor) end,
                    function(r, g, b, a) db.borderColor = { r, g, b, a } end,
                    true
                )
            end,
        },
    },
})
```
**Adaptador legacy (`beginColumn` / `endColumn` / `columnsFinalize`)**:
Soportado por compatibilidad hacia atrás (internamente delega a `createColumnGroup`):
```lua
layout:beginColumn({ width = 0.5, gap = 12 })
    layout:header("Col1_Header", "Opciones Izquierda")
layout:endColumn()
layout:beginColumn({ width = 0.5, gap = 12 })
    layout:header("Col2_Header", "Opciones Derecha")
layout:endColumn()
layout:columnsFinalize(masterContentFrame, 20)
```

### 4.6 Patrón Canónico Completo de Panel de Opciones
```lua
local function BuildSettingsPanel(uiContext, parentFrame, db)
    local layout = uiContext:createLayoutModel(parentFrame, {
        scrollable = true,
        threshold = 500,
        verticalGap = 12,
        bottomPadding = 24,
    })

    layout:header("MainHeader", "Panel de Configuración")
    layout:paragraph("MainDesc", "Ajusta las opciones y comportamientos principales del addon.")
    layout:addSpace(8)

    layout:beginSection()
        layout:header("Section1", "Opciones Generales")
        layout:toggle("EnableAddon", {
            getter = function() return db.enabled end,
            setter = function(val) db.enabled = val end,
            tooltip = false, -- Opcional en wrappers LayoutBuilder (lo normaliza), obligatorio en Context:createToggle
        })
    layout:endSection()

    layout:addSpace(10)

    layout:row({
        columns = {
            {
                width = 0.5,
                populate = function(colLayout)
                    colLayout:header("DisplayHeader", "Visualización")
                    colLayout:sliderWithStepper("Scale", "Escala", 0.5, 2.0, 0.1,
                        function() return db.scale end,
                        function(v) db.scale = v end
                    )
                end,
            },
            {
                width = 0.5,
                populate = function(colLayout)
                    colLayout:header("ColorsHeader", "Colores")
                    colLayout:colorPicker("BorderColor", "Color de Borde", false,
                        function() return unpack(db.borderColor) end,
                        function(r, g, b, a) db.borderColor = { r, g, b, a } end,
                        true
                    )
                end,
            },
        },
    })

    return layout
end
```

---

## 5. Catálogo de Constructores de Bajo Nivel y Validaciones Estrictas

| Archivo | Constructor | Parámetros Obligatorios | Valores por Defecto Clave |
| :--- | :--- | :--- | :--- |
| `01Frame.lua` | `Context:createFrame(opt)` | `name`, `parent`, `width`, `height`, `savePosition` (si `movable=true`), `saveSize` (si `resizable=true`) | `point="CENTER"`, `relativePoint="CENTER"`, `clamped=true`, `movable=false`, `resizable=false` |
| `01Frame.lua` | `Context:createMainFrame(opt)` | `name`, `parent`, `width`, `height`, `minWidth`, `minHeight`, `savePosition`, `saveSize` | `anchor="CENTER"`, `strata="HIGH"`, `movable=true`, `resizable=true`, `closableWithEscape=true`, `showCloseButton=true` |
| `02TabbedInterface.lua` | `Context:createTabbedInterface(opt)` | `name`, `parent`, `startY`, `tabs`, `sidebarWidth` | `initialIndex=1`, `collapsedWidth=40`, `collapseThreshold=550`, `collapsibleSidebar=true`, `autoScroll=true` |
| `03TwoColumn.lua` | `Context:createTwoColumns(opt)` | `name`, `parent` | `gap=10`, `stackThreshold=480`, `responsive=true` |
| `03ColumnGroup.lua` | `Context:createColumnGroup(opt)` | `parent` | `name=auto`, `gap=10`, `threshold=480`, `bottomPadding=0`, `rightOffset=0`, `fluidWidth=true` |
| `04Text.lua` | `Context:createHeader(opt)` | `name`, `parent`, `text` | `fontSize=24`, `justifyH="LEFT"`, `wordWrap=true`, `elasticWidth=true` |
| `04Text.lua` | `Context:createLabel(opt)` | `name`, `parent`, `text` | `fontSize=18`, `justifyH="LEFT"`, `wordWrap=true`, `elasticWidth=true` |
| `04Text.lua` | `Context:createParagraph(opt)` | `name`, `parent`, `text` | `fontSize=12`, `justifyH="LEFT"`, `wordWrap=true`, `elasticWidth=true` |
| `05Button.lua` | `Context:createButton(opt)` | `name`, `parent`, `width`, `height`, `tooltip` (`false`, `string`, `table` o `function`) | `text=""`, `clickTypes={"AnyUp"}` |
| `05Button.lua` | `Context:createIconButton(opt)` | `name`, `parent`, `iconType`, `size`, `tooltip` (`false`, `string`, `table` o `function`) | `iconColor=styles.colors.white` |
| `05Button.lua` | `Context:createDialogButton(opt)` | `name`, `parent`, `variant`, `tooltip` (`false`, `string`, `table` o `function`) | `width=90` (auto-expande), `height=26`, `fluidWidth=false` |
| `05Button.lua` | `Context:createDialogButtonGroup(opt)` | `name`, `parent`, `buttons` | `stackThreshold=400`, `buttonHeight=26`, `buttonWidth=90`, `gap=8` |
| `06Toggle.lua` | `Context:createToggle(opt)` | `name`, `parent`, `tooltip` (`false`, `string`, `table` o `function`) | `width=52`, `height=24`, `padding=2`, `flexRow=false` |
| `07Checkbox.lua` | `Context:createCheckbox(opt)` | `name`, `parent`, `tooltip` (`false`, `string`, `table` o `function`) | `checked=false`, `boxSize=25`, `flexRow=false` |
| `08InputField.lua` | `Context:createInputField(opt)` | `name`, `parent`, `height`, `tooltip` (`false`), `width` (salvo `fluidWidth=true`) | `multiLine=false`, `numeric=false`, `showClear=false` |
| `09Slider.lua` | `Context:createSlider(opt)` | `name`, `parent`, `orientation`, `minValue`, `maxValue`, `step`, `tooltip` (`false`), `length` (salvo `fluidWidth=true`) | `thickness=16` (H) / `14` (V), `thumbShape="diamond"`, `showFill=false` |
| `09Slider.lua` | `Context:createSliderWithStepper(opt)` | `name`, `parent`, `minValue`, `maxValue`, `step`, `tooltip` (`false`), `length` (salvo `fluidWidth=true`) | `orientation="HORIZONTAL"`, `stepperGap=4`, `stepperHeight=24` |
| `10Stepper.lua` | `Context:createStepper(opt)` | `name`, `parent`, `minValue`, `maxValue`, `step`, `tooltip` (`false`), `width` (salvo `fluidWidth=true`) | `height=24`, `decimals=auto` |
| `11Tooltip.lua` | `Context:createTooltip(opt)` | `name` | `parent=_G.UIParent`, `maxWidth=1/3 pantalla`, `maxHeight=9/10 pantalla`, `padding=12` |
| `12Dropdown.lua` | `Context:createDropdown(opt)` | `name`, `parent`, `tooltip` (`false`), `width` (salvo `fluidWidth=true`) | `options={}`, `height=26`, `itemHeight=24`, `maxVisibleItems=6` |
| `13ContextMenu.lua` | `Context:createContextMenu(opt)` | `name`, `parent`, `items` (`#items > 0`) | `minWidth=22`, `itemHeight=22` |
| `14Toast.lua` | `Context:createToast(opt)` / `showToast` | *Ninguno (todos opcionales)* | `parent=toastManager.frame`, `name=Auto`, `title=resolveCallerAddonTitle()`, `minWidth=50`, `maxWidth=240`, `duration=4` |
| `15ColorPicker.lua` | `Context:createColorPicker(opt)` | `name`, `parent`, `tooltip` (`false`, `string`, `table` o `function`) | `swatchSize=24`, `color={1,1,1,1}`, `hasAlpha=true`, `flexRow=false` |
| `16Accordion.lua` | `Context:createAccordion(opt)` | `name`, `parent`, `title` | `expanded=false`, `fluidWidth=true`, `rightOffset=-10`, `headerHeight=28`, `contentPadding=10`, `populate=fn` |
| `Core/PositionManager.lua` | `PositionManager:initPositionStorage` | `moduleKey` (`string` no vacío) | `defaultTable={point="CENTER", relativePoint="CENTER", x=0, y=0}`, `storageTableName="AscensionUIPositions"` |
| `UX/Draggable.lua` | `UX:makeMovable(frame, config)` | `frame`, `config.savePosition` (`true` o `false` explícito) | Delega guardado/lectura a `Core/PositionManager.lua` |
| `UX/Resizable.lua` | `UX:makeResizable(frame, options)` | `frame`, `options.saveSize` (`true` o `false` explícito) | `gripSize=24`, `gripThickness=8`, delega dimensiones a `Core/PositionManager.lua` |
| `UX/Responsive.lua` | `UX:makeResponsive(containerFrame, opt)` | `containerFrame` | `threshold=480`, `debounce=0.05` |
| `UX/Scrollable.lua` | `UX:makeScrollable(container, opt)` | `container` | `scrollBarWidth=12`, `step=30`, `thumbShape="capsule"`, `bottomPadding=16` |

### 5.1 Detalle Crítico en Lua para `options.tooltip` Obligatorio
En los 11 constructores interactivos directos de `Context` (`05Button`, `createIconButton`, `createDialogButton`, `06Toggle`, `07Checkbox`, `08InputField`, `09Slider`, `createSliderWithStepper`, `10Stepper`, `12Dropdown`, `15ColorPicker`), la propiedad `tooltip` es obligatoria (`assert(options.tooltip ~= nil)`).
- En Lua 5.1, pasar `tooltip = nil` omite la clave en la tabla. Por ello, al llamar directamente a `Context:create*` sin tooltip, **siempre pasa `tooltip = false`**.
- Los wrappers de `LayoutBuilder` (`layout:toggle`, `layout:colorPicker`, etc.) sí aceptan omitir `tooltip` o pasar `nil`, porque internamente asignan `if opts.tooltip == nil then opts.tooltip = false end`.

---

## 6. Estructura y Estilo Canónico de Archivo

Todo archivo en `Components/`, `Core/` o `UX/` debe estructurarse con bloques numerados, cabeceras descriptivas y validaciones explícitas al inicio:

```lua
-------------------------------------------------------------------------------
-- Project: AscensionFactory
-- Author: Aka-DoctorCode
-- File: <NombreComponente>.lua
-------------------------------------------------------------------------------
---@diagnostic disable: undefined-global, undefined-field, inject-field

-------------------------------------------------------------------------------
-- 1. INITIALIZATION & NAMESPACE REGISTRATION
-------------------------------------------------------------------------------
local MAJOR = "AscensionFactory"
local lib = LibStub:GetLibrary(MAJOR)
if not lib then return end

local Context = lib.Context
if not Context then return end

-------------------------------------------------------------------------------
-- 2. <NOMBRE> FACTORY
-------------------------------------------------------------------------------
function Context:create<Widget>(options)
    assert(type(options) == "table", "options table required for create<Widget>")
    assert(options.parent, "options.parent is required for create<Widget>")
    assert(options.name, "options.name is required for create<Widget>")
    -- Validaciones adicionales obligatorias según el componente...

    local styles = self.styles
    local ux = lib.UX
    local parent = options.parent

    -- 2.1 BASE ELEMENT ACQUISITION (Pooling obligatorio)
    local widget = self:acquireElement("<Type>", parent, options)
    _G[options.name] = widget
    widget.globalName = options.name

    -- 2.2 POSITIONING & ANCHORING
    -- 2.3 STYLING & TEXTURES (Obsidian Cyberpunk de self.styles)
    -- 2.4 INTERACTION & SCRIPTS (Hoverable, Draggable, PositionManager, Callbacks)
    -- 2.5 PUBLIC API METHODS

    return widget
end
```
