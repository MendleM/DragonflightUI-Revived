-- Spanish Translations (originally by Woopy; new/updated entries AI-generated. Community review welcome.)
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')
local L = {}

-- modules - config.lua
do
    L["ModuleModules"] = "Módulos"

    L["ModuleTooltipActionbar"] =
        "Este módulo mejora la barra de acción predeterminada, incluyendo el micromenú y los botones de bolsas.\nAñade opciones separadas para las barras de acción 1-8, barra de mascotas, EXP, reputación, posesión, actitud, tótems, bolsas y micromenú."
    L["ModuleTooltipBossframe"] = "Este módulo añade marcos personalizados para los jefes.\nEN DESARROLLO."
    L["ModuleTooltipBuffs"] =
        "Este módulo modifica el marco de beneficios predeterminado.\nAñade opciones separadas para Beneficios y Perjuicios."
    L["ModuleTooltipCastbar"] =
        "Este módulo modifica la barra de lanzamiento predeterminada.\nAñade opciones separadas para la barra de lanzamiento del Jugador, Enfoque y Objetivo."
    L["ModuleTooltipChat"] = "Este módulo modifica la ventana de chat predeterminada.\nEN DESARROLLO."
    L["ModuleTooltipCompatibility"] = "Este módulo añade compatibilidad adicional con otros addons."
    L["ModuleTooltipDarkmode"] =
        "Este módulo añade un modo oscuro a múltiples marcos de la interfaz de Dragonflight.\nEN DESARROLLO - ¡por favor, envía tus comentarios!"
    L["ModuleTooltipFlyout"] = "Desplegable"
    L["ModuleTooltipMinimap"] =
        "Este módulo mejora el minimapa y el rastreador de misiones.\nAñade opciones separadas para el minimapa y el rastreador de misiones."
    L["ModuleTooltipTooltip"] = "Este módulo mejora los tooltips del juego.\nEN DESARROLLO"
    L["ModuleTooltipUI"] =
        "Este módulo añade un estilo moderno a diferentes ventanas como el marco de personaje. También añade rediseños específicos de la Era con el nuevo libro de hechizos, el marco de talentos y la ventana de profesiones."
    L["ModuleTooltipUnitframe"] =
        "Este módulo mejora los marcos de unidad predeterminados y añade nuevas funciones como el color de clase o la salud de los enemigos (Era).\nAñade opciones separadas para los marcos de jugador, mascota, objetivo, enfoque y grupo."
    L["ModuleTooltipUtility"] = "Este módulo añade funciones y ajustes generales a la interfaz.\nEN DESARROLLO."

    L["ModuleFlyout"] = "Desplegable"
    L["ModuleActionbar"] = "Barra de acción"
    L["ModuleCastbar"] = "Barra de lanzamiento"
    L["ModuleChat"] = "Chat"
    L["ModuleBuffs"] = "Beneficios"
    L["ModuleDarkmode"] = "Modo oscuro"
    L["ModuleMinimap"] = "Minimapa"
    L["ModuleTooltip"] = "Tooltip"
    L["ModuleUI"] = "IU"
    L["ModuleUnitframe"] = "Marcos de unidad"
    L["ModuleUtility"] = "Utilidad"
    L["ModuleCompatibility"] = "Compatibilidad"
    L["ModuleBossframe"] = "Marcos de jefe"
end

-- config 
do
    L["ConfigGeneralWhatsNew"] = "Novedades"
    L["ConfigGeneralModules"] = "Módulos"
    L["ConfigGeneralInfo"] = "Información"
    L["MainMenuDragonflightUI"] = "DragonflightUI"
    L["MainMenuEditmode"] = "Modo edición"

    -- config.mixin.lua
    L["ConfigMixinQuickKeybindMode"] = "Modo rápido de asignación de teclas"
    L["ConfigMixinGeneral"] = "General"
    L["ConfigMixinModules"] = "Módulos"
    L["ConfigMixinActionBar"] = "Barra de acción"
    L["ConfigMixinCastBar"] = "Barra de lanzamiento"
    L["ConfigMixinMisc"] = "Varios"
    L["ConfigMixinUnitframes"] = "Marcos de unidad"

    -- modules.mixin.lua
    L["ModuleConditionalMessage"] =
        "'|cff8080ff%s|r' fue desactivado, pero la función correspondiente ya estaba enganchada, ¡por favor usa '|cff8080ff/reload|r'!"

    -- config
    L["ConfigToolbarCopyPopup"] = "Copia el enlace de abajo (Ctrl+C, Entrada):"
    L["ConfigToolbarDiscord"] = "Discord"
    L["ConfigToolbarDiscordTooltip"] = "Contribuye con ideas y obtén soporte."
    L["ConfigToolbarGithub"] = "Github"
    L["ConfigToolbarGithubTooltip"] = "Ver código, reportar problemas y contribuir."
end

-- profiles
do
    L["ProfilesSetActiveProfile"] = "Establecer perfil activo."
    L["ProfilesNewProfile"] = "Crear un nuevo perfil."
    L["ProfilesCopyFrom"] = "Copiar la configuración de un perfil existente en el perfil activo."
    L["ProfilesOpenCopyDialogue"] = "Abrir diálogo de copia."
    L["ProfilesDeleteProfile"] = "Eliminar un perfil existente de la base de datos."
    L["Profiles"] = "Añadir nuevo perfil"
    L["ProfilesOpenDeleteDialogue"] = "Abrir diálogo de eliminación."
    L["ProfilesAddNewProfile"] = "Añadir nuevo perfil"
    L["ProfilesChatNewProfile"] = "nuevo perfil: "
    L["ProfilesErrorNewProfile"] = "ERROR: ¡El nombre del nuevo perfil no puede estar vacío!"
    L["ProfilesDialogueDeleteProfile"] = "¿Eliminar el perfil \'%s\'?"
    L["ProfilesDialogueCopyProfile"] = "Añadir nuevo perfil (copiar de \'|cff8080ff%s|r\')"
    L["ProfilesImportShareHeader"] = "Importar/Compartir"
    L["ProfilesImportProfile"] = "Importar perfil"
    L["ProfilesImportProfileButton"] = HUD_EDIT_MODE_IMPORT_LAYOUT or "Importar"
    L["ProfilesImportProfileDesc"] = "Abre el diálogo de importación."
    L["ProfilesExportProfile"] = "Compartir perfil"
    L["ProfilesExportProfileButton"] = HUD_EDIT_MODE_SHARE_LAYOUT or "Compartir"
    L["ProfilesExportProfileDesc"] = "Abre el diálogo de compartir."

end

-- Editmode
do
    L["EditModeBasicOptions"] = "Opciones básicas"
    L["EditModeAdvancedOptions"] = "Opciones avanzadas"
    L["EditModeLayoutDropdown"] = "Perfil"
    L["EditModeCopyLayout"] = "Copiar perfil"
    L["EditModeRenameLayout"] = ""
    L["EditModeRenameOrCopyLayout"] = "Renombrar/copiar perfil"
    L["EditModeDeleteLayout"] = "Eliminar perfil"
    L["EditModeNewLayoutDisabled"] = "%s Nuevo perfil"
    L["EditModeNewLayout"] = "%s |cnPURE_GREEN_COLOR:Nuevo perfil|r"
    L["EditModeImportLayout"] = HUD_EDIT_MODE_IMPORT_LAYOUT or "Importar"
    L["EditModeShareLayout"] = HUD_EDIT_MODE_SHARE_LAYOUT or "Compartir"
    L["EditModeCopyToClipboard"] = "Copiar al portapapeles |cffffd100(para compartir en línea)|r"
    L["EditModeExportProfile"] = "Exportar perfil |cff8080ff%s|r"
    L["EditModeImportProfile"] = "Importar perfil como |cff8080ff%s|r"
end

-- Compat
do
    L['CompatName'] = "Compatibilidad"
    L['CompatAuctionator'] = "Auctionator"
    L['CompatAuctionatorDesc'] =
        "Añade compatibilidad con Auctionator al usar el módulo de IU con 'Cambiar ventana de profesiones' activado."
    L['CompatBaganator'] = "Baganator_Skin"
    L['CompatBaganatorDesc'] = "Cambia la apariencia predeterminada de 'Blizzard' por una con estilo de DragonflightUI."
    L['CompatBaganatorEquipment'] = "Baganator_EquipmentSets"
    L['CompatBaganatorEquipmentDesc'] = "Añade compatibilidad para conjuntos de equipo como fuente de objetos."
    L['CompatCharacterStatsClassic'] = "CharacterStatsClassic"
    L['CompatCharacterStatsClassicDesc'] =
        "Añade compatibilidad con CharacterStatsClassic al usar el módulo de IU con 'Cambiar marco de personaje' activado."
    L['CompatClassicCalendar'] = "Classic Calendar"
    L['CompatClassicCalendarDesc'] = "Añade compatibilidad con Classic Calendar."
    L['CompatClique'] = "Clique"
    L['CompatCliqueDesc'] = "Añade compatibilidad con Clique"
    L['CompatLeatrixPlus'] = "Leatrix Plus"
    L['CompatLeatrixPlusDesc'] = "Añade compatibilidad con LeatrixPlus."
    L['CompatLFGBulletinBoard'] = "LFG Bulletin Board"
    L['CompatLFGBulletinBoardDesc'] = "Añade compatibilidad con LFG Bulletin Board."
    L['CompatMerInspect'] = "MerInspect"
    L['CompatMerInspectDesc'] =
        "Añade compatibilidad con MerInspect al usar el módulo de IU con 'Cambiar marco de personaje' activado."
    L['CompatRanker'] = "Ranker"
    L['CompatRankerDesc'] =
        "Añade compatibilidad con Ranker al usar el módulo de IU con 'Cambiar marco de personaje' activado."
    L['CompatTacoTip'] = "TacoTip"
    L['CompatTacoTipDesc'] =
        "Añade compatibilidad con TacoTip al usar el módulo de IU con 'Cambiar marco de personaje' activado."
    L['CompatTDInspect'] = "TDInspect"
    L['CompatTDInspectDesc'] =
        "Añade compatibilidad con TDInspect al usar el módulo de IU con 'Cambiar marco de personaje' activado."
    L['CompatWhatsTraining'] = "WhatsTraining"
    L['CompatWhatsTrainingDesc'] =
        "Añade compatibilidad con WhatsTraining al usar el módulo de IU con 'Cambiar libro de hechizos' activado."
end

-- __Settings
do
    L["Defaults"] = "Predeterminados"
    L["SettingsDefaultStringFormat"] = "\n(Predeterminado: |cff8080ff%s|r)"
    L["SettingsCharacterSpecific"] = "\n\n|cff8080ff[Configuración por personaje]|r"

    -- positionTable
    L["PositionTableHeader"] = "Escala y posición"
    L["PositionTableHeaderDesc"] = ""
    L["PositionTableScale"] = "Escala"
    L["PositionTableScaleDesc"] = ""
    L["PositionTableAnchor"] = "Ancla"
    L["PositionTableAnchorDesc"] = "Ancla"
    L["PositionTableAnchorParent"] = "Padre del ancla"
    L["PositionTableAnchorParentDesc"] = ""
    L["PositionTableAnchorFrame"] = "Marco del ancla"
    L["PositionTableAnchorFrameDesc"] = ""
    L["PositionTableCustomAnchorFrame"] = "Marco de anclaje (personalizado)"
    L["PositionTableCustomAnchorFrameDesc"] =
        "Usa este marco con nombre como marco de anclaje (si es válido). Por ejemplo: 'CharacterFrame', 'TargetFrame'..."
    L["PositionTableX"] = "X"
    L["PositionTableXDesc"] = ""
    L["PositionTableY"] = "Y"
    L["PositionTableYDesc"] = ""
end

-- darkmode
do
    L["DarkmodeColor"] = "Color"
    L["DarkmodeDesaturate"] = "Desaturar"
    L["DarkmodeDarkenPortraitExtra"] = "Oscurecer símbolo élite"
    L["DarkmodeDarkenPortraitExtraDesc"] = "Oscurece los bordes de dragón élite, raro y jefe alrededor de los marcos de unidad en el modo oscuro."
end

-- actionbar
do
    L["ActionbarName"] = "Barra de acción"
    L["ActionbarNameFormat"] = "Barra de acción %d"

    -- bar names
    L["XPBar"] = "Barra de EXP"
    L["ReputationBar"] = "Barra de reputación"
    L["PetBar"] = "Barra de mascota"
    L["StanceBar"] = "Barra de actitud"
    L["PossessBar"] = "Barra de posesión"
    L["MicroMenu"] = "Micromenú"
    L["TotemBar"] = "Barra de tótems"

    -- gryphonsTable
    L["Default"] = "Predeterminado"
    L["Alliance"] = "Alianza"
    L["Horde"] = "Horda"
    L["None"] = "Ninguno"

    -- stateDriverTable
    L["ActionbarDriverDefault"] = "Predeterminado"
    L["ActionbarDriverSmart"] = "Inteligente"
    L["ActionbarDriverNoPaging"] = "Sin paginación"

    -- stateDriver
    L['ActionbarDriverName'] = "Paginación"
    L['ActionbarDriverNameDesc'] =
        "Cambia el comportamiento de paginación de la barra de acción principal, por ejemplo, al cambiar de actitud o al entrar en sigilo.\n'Predeterminado' - sin cambios\n'Inteligente' - añade una página personalizada para el sigilo en forma felina del druida\n'Sin paginación' - desactiva toda la paginación"

    -- targetStateDriver
    L["ActionbarTargetDriverConditionalFormat"] = "\n\n(This is equivalent to the macro conditional: |cff8080ff%s|r)\n"
    L["ActionbarTargetDriverMultipleConditionalFormat"] =
        "\n\n(This is equivalent to the following macro conditional (depending on the |cfffffffftype|r of spell): %s)\n"

    local function cond(str)
        return string.format(L["ActionbarTargetDriverConditionalFormat"], str)
    end

    local function condMultiple(t)
        local str = '';

        for k, v in ipairs(t) do
            --
            str = string.format('%s%s', str, string.format('\n(|cffffffff%s|r) |cff8080ff%s|r', v.type, v.str))
        end

        return string.format(L["ActionbarTargetDriverMultipleConditionalFormat"], str)
    end

    L['ActionbarTargetDriverHeader'] = "Selección de objetivo"
    L['ActionbarTargetDriverUseMouseover'] = "Usar lanzamiento por pasar el cursor"
    L['ActionbarTargetDriverUseMouseoverDesc'] =
        "Cuando está activado, los botones de acción intentan apuntar a la unidad bajo el cursor del ratón." ..
            condMultiple({
                {type = 'help', str = '[@mouseover, exists, help, mod:XY]'},
                {type = 'harm', str = '[@mouseover, nodead, exists, harm, mod:XY]'},
                {type = 'both', str = '[@mouseover, nodead, exists, mod:XY]'}
            })
    L['ActionbarTargetDriverMouseOverModifier'] = "Tecla para lanzar al pasar el cursor"
    L['ActionbarTargetDriverMouseOverModifierDesc'] =
        "Al mantener esta tecla, permitirá lanzar hechizos al objetivo bajo el cursor, incluso si hay una unidad ya seleccionada."
    L['ActionbarTargetDriverUseAutoAssist'] = "Usar lanzamiento con asistencia automática"
    L['ActionbarTargetDriverUseAutoAssistDesc'] =
        "Cuando está activado, los botones de acción intentan lanzar automáticamente sobre el objetivo de tu objetivo si tu objetivo actual no es válido para el hechizo seleccionado." ..
            condMultiple({
                {type = 'help', str = '[help]target; [@targettarget, help]targettarget'},
                {type = 'harm', str = '[harm]target; [@targettarget, harm]targettarget'}
            })
    L['ActionbarTargetDriverFocusCast'] = "Lanzamiento sobre objetivo focal"
    L['ActionbarTargetDriverFocusCastDesc'] =
        "Cuando está activado (y la 'Tecla de lanzamiento sobre objetivo focal' está configurada), los botones de acción intentan apuntar al objetivo focal." ..
            cond('[mod:FOCUSCAST, @focus, exists, nodead]')
    L['ActionbarTargetDriverFocusCastModifier'] = FOCUS_CAST_KEY_TEXT or "Tecla de lanzamiento sobre objetivo focal"
    L['ActionbarTargetDriverFocusCastModifierDesc'] =
        "Al mantener esta tecla, permitirá lanzar hechizos sobre el objetivo focal, incluso si hay una unidad ya seleccionada."
    L['ActionbarTargetDriverSelfCast'] = (SELF_CAST or "Autolanzamiento")
    L['ActionbarTargetDriverSelfCastDesc'] = (OPTION_TOOLTIP_AUTO_SELF_CAST or "") .. cond('[mod: SELFCAST]')
    L['ActionbarTargetDriverSelfCastModifier'] = AUTO_SELF_CAST_KEY_TEXT or "Tecla de autolanzamiento"
    L['ActionbarTargetDriverSelfCastModifierDesc'] = OPTION_TOOLTIP_AUTO_SELF_CAST_KEY_TEXT or ""

    -- buttonTable
    L["ButtonTableActive"] = "Activo"
    L["ButtonTableActiveDesc"] = ""
    L["ButtonTableButtons"] = "Botones"
    L["ButtonTableButtonsDesc"] = ""
    L["ButtonTableButtonScale"] = "Escala del botón"
    L["ButtonTableButtonScaleDesc"] = ""
    L["ButtonTableOrientation"] = "Orientación"
    L["ButtonTableOrientationDesc"] = "Orientación"
    L["ButtonTableGrowthDirection"] = "Dirección de crecimiento"
    L["ButtonTableGrowthDirectionDesc"] =
        "Establece la dirección en la que la barra 'crece' al usar múltiples filas(/columnas)."
    L["ButtonTableFlyoutDirection"] = "Dirección del desplegable"
    L["ButtonTableFlyoutDirectionDesc"] = "Establece la dirección del desplegable de hechizos."
    L["ButtonTableReverseButtonOrder"] = "Invertir orden de botones"
    L["ButtonTableReverseButtonOrderDesc"] = ""
    L["ButtonTableNumRows"] = "Número de filas"
    L["ButtonTableNumRowsDesc"] = ""
    L["ButtonTableNumButtons"] = "Número de botones"
    L["ButtonTableNumButtonsDesc"] = ""
    L["ButtonTablePadding"] = "Relleno"
    L["ButtonTablePaddingDesc"] = ""
    L["ButtonTableStyle"] = "Estilo"
    L["ButtonTableStyleDesc"] = ""
    L["ButtonTableAlwaysShowActionbar"] = "Mostrar siempre la barra de acción"
    L["ButtonTableAlwaysShowActionbarDesc"] = ""
    L["ButtonTableHideMacroText"] = "Ocultar texto de macro"
    L["ButtonTableHideMacroTextDesc"] = ""
    L["ButtonTableMacroNameFontSize"] = "Tamaño de fuente del nombre de macro"
    L["ButtonTableMacroNameFontSizeDesc"] = ""
    L["ButtonTableHideKeybindText"] = "Ocultar texto de asignación de teclas"
    L["ButtonTableHideKeybindTextDesc"] = ""
    L["ButtonTableShortenKeybindText"] = "Acortar texto de tecla"
    L["ButtonTableShortenKeybindTextDesc"] =
        "Acorta el texto de la tecla, por ejemplo 'sF' en lugar de 's-F' y reemplazos similares."
    L["ButtonTableKeybindFontSize"] = "Tamaño de fuente de asignación de teclas"
    L["ButtonTableKeybindFontSizeDesc"] = ""
    L["MoreOptionsHideBarArt"] = "Ocultar arte de la barra"
    L["MoreOptionsHideBarArtDesc"] = ""
    L["MoreOptionsHideBarScrolling"] = "Ocultar desplazamiento de barra"
    L["MoreOptionsHideBarScrollingDesc"] = ""
    L["MoreOptionsGryphons"] = "Grifos"
    L["MoreOptionsGryphonsDesc"] = "Grifos"
    L["MoreOptionsIconRangeColor"] = "Color del icono por alcance"
    L["MoreOptionsIconRangeColorDesc"] =
        "Cambia el color del icono cuando esté fuera de alcance, similar a RedRange/tullaRange"
    L["ExtraOptionsPreset"] = "Preajuste"
    L["ExtraOptionsResetToDefaultPosition"] = "Restablecer a la posición predeterminada"
    L["ExtraOptionsPresetDesc"] =
        "Establece la escala, anclaje, anchorparent, anchorframe, X y Y al preajuste elegido, pero no cambia ninguna otra configuración."
    L["ExtraOptionsModernLayout"] = "Diseño moderno (predeterminado)"
    L["ExtraOptionsModernLayoutDesc"] = ""
    L["ExtraOptionsClassicLayout"] = "Diseño clásico (barra lateral)"
    L["ExtraOptionsClassicLayoutDesc"] = ""

    -- XP
    L["XPOptionsName"] = "EXP"
    L["XPOptionsDesc"] = "EXP"
    L["XPOptionsStyle"] = L["ButtonTableStyle"]
    L["XPOptionsStyleDesc"] = ""
    L["XPOptionsWidth"] = "Anchura"
    L["XPOptionsWidthDesc"] = ""
    L["XPOptionsHeight"] = "Altura"
    L["XPOptionsHeightDesc"] = ""
    L["XPOptionsAlwaysShowXPText"] = "Mostrar siempre el texto de EXP"
    L["XPOptionsAlwaysShowXPTextDesc"] = ""
    L["XPOptionsShowXPPercent"] = "Mostrar porcentaje de EXP"
    L["XPOptionsShowXPPercentDesc"] = ""

    -- Reputación
    L["RepOptionsName"] = "Reputación"
    L["RepOptionsDesc"] = "Reputación"
    L["RepOptionsStyle"] = L["ButtonTableStyle"]
    L["RepOptionsStyleDesc"] = ""
    L["RepOptionsWidth"] = L["XPOptionsWidth"]
    L["RepOptionsWidthDesc"] = L["XPOptionsWidthDesc"]
    L["RepOptionsHeight"] = L["XPOptionsHeight"]
    L["RepOptionsHeightDesc"] = L["XPOptionsHeightDesc"]
    L["RepOptionsAlwaysShowRepText"] = "Siempre mostrar el texto de reputación"
    L["RepOptionsAlwaysShowRepTextDesc"] = ""

    -- Bags
    L["BagsOptionsName"] = "Bolsas"
    L["BagsOptionsDesc"] = "Bolsas"
    L["BagsOptionsStyle"] = L["ButtonTableStyle"]
    L["BagsOptionsStyleDesc"] = ""
    L["BagsOptionsExpanded"] = "Expandido"
    L["BagsOptionsExpandedDesc"] = ""
    L["BagsOptionsHideArrow"] = "Ocultar flecha"
    L["BagsOptionsHideArrowDesc"] = ""
    L["BagsOptionsHidden"] = "Oculto"
    L["BagsOptionsHiddenDesc"] = "Mochila oculta"
    L["BagsOptionsOverrideBagAnchor"] = "Sobrescribir BagAnchor"
    L["BagsOptionsOverrideBagAnchorDesc"] = ""
    L["BagsOptionsOffsetX"] = "Desplazamiento X de BagAnchor"
    L["BagsOptionsOffsetXDesc"] = ""
    L["BagsOptionsOffsetY"] = "Desplazamiento Y de BagAnchor"
    L["BagsOptionsOffsetYDesc"] = ""

    -- FPS
    L["FPSOptionsName"] = "FPS"
    L["FPSOptionsDesc"] = "FPS"
    L["FPSOptionsStyle"] = L["ButtonTableStyle"]
    L["FPSOptionsStyleDesc"] = ""
    L["FPSOptionsHideDefaultFPS"] = "Ocultar FPS predeterminado"
    L["FPSOptionsHideDefaultFPSDesc"] = "Oculta el texto de FPS predeterminado"
    L["FPSOptionsShowFPS"] = "Mostrar FPS"
    L["FPSOptionsShowFPSDesc"] = "Muestra el texto de FPS personalizado"
    L["FPSOptionsAlwaysShowFPS"] = "Mostrar FPS siempre"
    L["FPSOptionsAlwaysShowFPSDesc"] = "Muestra siempre el texto de FPS personalizado"
    L["FPSOptionsShowPing"] = "Mostrar latencia"
    L["FPSOptionsShowPingDesc"] = "Muestra la latencia en ms"

    -- Extra Action Button
    L["ExtraActionButtonOptionsName"] = "Botón de acción extra"
    L["ExtraActionButtonOptionsNameDesc"] = "IPS"
    L["ExtraActionButtonStyle"] = L["ButtonTableStyle"]
    L["ExtraActionButtonStyleDesc"] = ""
    L["ExtraActionButtonHideBackgroundTexture"] = "Ocultar textura de fondo"
    L["ExtraActionButtonHideBackgroundTextureDesc"] = ""

end

-- Buffs
do
    L["BuffsOptionsName"] = "Beneficios"
    L["BuffsOptionsStyle"] = L["ButtonTableStyle"]
    L["BuffsOptionsStyleDesc"] = ""

    L["BuffsOptionsExpanded"] = "Expandido"
    L["BuffsOptionsExpandedDesc"] = ""

    L["BuffsOptionsUseStateHandler"] = "Usar manejador de estado"
    L["BuffsOptionsUseStateHandlerDesc"] =
        "Sin esto, la configuración de visibilidad anterior no funcionará, pero podría mejorar la compatibilidad con otros complementos (por ejemplo, MinimapAlert), ya que no hace que los marcos sean seguros."
end

-- Flyout
do
    L["FlyoutHeader"] = "Desplegable"
    L["FlyoutHeaderDesc"] = ""
    L["FlyoutDirection"] = "Dirección del desplegable"
    L["FlyoutDirectionDesc"] = "Dirección del desplegable"
    L["FlyoutSpells"] = "Hechizos"
    L["FlyoutSpellsDesc"] = "Inserta los SpellIDs separados por comas, por ejemplo: '688, 697'."
    L["FlyoutSpellsAlliance"] = "Hechizos (Alianza)"
    L["FlyoutSpellsAllianceDesc"] = L["FlyoutSpellsDesc"] .. "\n(Solo se usa en el lado de la Alianza.)"
    L["FlyoutSpellsHorde"] = "Hechizos (Horda)"
    L["FlyoutSpellsHordeDesc"] = L["FlyoutSpellsDesc"] .. "\n(Solo se usa en el lado de la Horda.)"
    L["FlyoutItems"] = "Objetos"
    L["FlyoutItemsDesc"] = "Inserta los ItemIDs separados por comas, por ejemplo: '6948, 8490'."
    L["FlyoutCloseAfterClick"] = "Cerrar después de hacer clic"
    L["FlyoutCloseAfterClickDesc"] = "Cierra el desplegable después de presionar uno de sus botones."
    L["FlyoutAlwaysShow"] = "Mostrar siempre los botones"
    L["FlyoutAlwaysShowDesc"] =
        "Muestra siempre los (sub)botones, incluso cuando están vacíos.\nÚsalo si quieres arrastrar y soltar."
    L["FlyoutIcon"] = "Icono"
    L["FlyoutIconDesc"] = "Inserta el FileID o la ruta de archivo de una textura."
    L["FlyoutDisplayname"] = "Nombre para mostrar"
    L["FlyoutDisplaynameDesc"] = ""
    L["FlyoutTooltip"] = "Tooltip"
    L["FlyoutTooltipDesc"] = ""

    L["FlyoutButtonWarlock"] = "Desplegable de invocación (Brujo)"
    L["FlyoutButtonMagePort"] = "Desplegable de teletransporte"
    L["FlyoutButtonMagePortals"] = "Desplegable de portales"
    L["FlyoutButtonMageFood"] = "Desplegable de comida conjurada"
    L["FlyoutButtonMageWater"] = "Desplegable de agua conjurada"
    L["FlyoutWarlock"] = "Invocar demonio"
    L["FlyoutWarlockDesc"] = "Invoca a uno de tus demonios."
    L["FlyoutMagePort"] = "Teletransporte"
    L["FlyoutMagePortDesc"] = "Te teletransporta a una ciudad principal."
    L["FlyoutMagePortals"] = "Portal"
    L["FlyoutMagePortalsDesc"] = "Crea un portal que permite a los miembros del grupo viajar a una ciudad principal."
    L["FlyoutMageWater"] = "Conjurar agua"
    L["FlyoutMageWaterDesc"] = "Los objetos conjurados desaparecen si sales del juego por más de 15 minutos."
    L["FlyoutMageFood"] = "Conjurar comida"
    L["FlyoutMageFoodDesc"] = L["FlyoutMageWaterDesc"]

    L["FlyoutButtonCustomFormat"] = "Desplegable personalizado %d"
    L["FlyoutCustomNameFormat"] = "Desplegable personalizado %d"
    L["FlyoutCustomNameDescFormat"] = "Botón desplegable por personaje con hasta 12 botones de acción adicionales."

    L["FlyoutHeaderClassPresets"] = "Preajustes de clase"
    L["FlyoutHeaderClassPresetsDesc"] =
        "Establece la configuración del desplegable y también los botones del desplegable según un preajuste específico del personaje."

end

-- Castbar
do
    L["CastbarName"] = "Barra de lanzamiento"
    L["CastbarNameFormat"] = "Barra de lanzamiento %s"
    L["CastbarTableActive"] = "Activo"
    L["CastbarTableActivateDesc"] = ""
    L["CastbarTableStyle"] = L["ButtonTableStyle"]
    L["CastbarTableStyleDesc"] = ""
    L["CastbarTableWidth"] = L["XPOptionsWidth"]
    L["CastbarTableWidthDesc"] = L["XPOptionsWidthDesc"]
    L["CastbarTableHeight"] = L["XPOptionsHeight"]
    L["CastbarTableHeightDesc"] = L["XPOptionsHeightDesc"]
    L["CastbarTablePrecisionTimeLeft"] = "Precisión (tiempo restante)"
    L["CastbarTablePrecisionTimeLeftDesc"] = ""
    L["CastbarTablePrecisionTimeMax"] = "Precisión (tiempo máximo)"
    L["CastbarTablePrecisionTimeMaxDesc"] = ""
    L["CastbarTableShowCastTimeText"] = "Mostrar texto de tiempo de lanzamiento"
    L["CastbarTableShowCastTimeTextDesc"] = ""
    L["CastbarTableShowCastTimeMaxText"] = "Mostrar texto de tiempo máximo de lanzamiento"
    L["CastbarTableShowCastTimeMaxTextDesc"] = ""
    L["CastbarTableCompactLayout"] = "Diseño compacto"
    L["CastbarTableCompactLayoutDesc"] = ""
    L["CastbarTableHoldTimeSuccess"] = "Tiempo de retención (éxito)"
    L["CastbarTableHoldTimeSuccessDesc"] =
        "Tiempo antes de que la barra de lanzamiento comience a desvanecerse tras un lanzamiento exitoso."
    L["CastbarTableHoldTimeInterrupt"] = "Tiempo de retención (interrupción)"
    L["CastbarTableHoldTimeInterruptDesc"] =
        "Tiempo antes de que la barra de lanzamiento comience a desvanecerse tras una interrupción."
    L["CastbarTableShowIcon"] = "Mostrar icono"
    L["CastbarTableShowIconDesc"] = ""
    L["CastbarTableIconSize"] = "Tamaño del icono"
    L["CastbarTableIconSizeDesc"] = ""
    L["CastbarTableShowTicks"] = "Mostrar tics"
    L["CastbarTableShowTicksDesc"] = ""
    L["CastbarTableAutoAdjust"] = "Ajuste automático"
    L["CastbarTableAutoAdjustDesc"] =
        "Aplica un desplazamiento en Y dependiendo de la cantidad de beneficios/afectaciones - útil cuando se ancla la barra de lanzamiento debajo del marco de objetivo/enfoque."
    L["CastbarTableShowRank"] = "Mostrar rango"
    L["CastbarTableShowRankDesc"] = ""
    L["CastbarTableShowChannelName"] = "Mostrar nombre de canal"
    L["CastbarTableShowChannelNameDesc"] =
        "Muestra el nombre del hechizo en lugar del texto de visualización (ej. 'Canalizando')"

    L["ExtraOptionsResetToDefaultStyle"] = "Restablecer al estilo predeterminado"
    L["ExtraOptionsPresetStyleDesc"] =
        "Restablece todas las configuraciones que cambian el estilo de la barra de lanzamiento, pero no modifica ninguna otra configuración."

    -- mirror timer
    L["CastbarMirrorTimerName"] = "Temporizador espejo del jugador"
    L["CastbarMirrorTimerNameDesc"] = ""
    L["CastbarMirrorHideBlizzard"] = "Ocultar Blizzard"
    L["CastbarMirrorHideBlizzardDesc"] = "Oculta el temporizador espejo predeterminado de Blizzard."
end

-- Minimap
do
    L["MinimapName"] = "Minimapa"
    L["MinimapStyle"] = L["ButtonTableStyle"]
    L["MinimapShowPing"] = "Mostrar ping"
    L["MinimapNotYetImplemented"] = "(NO IMPLEMENTADO AÚN)"
    L["MinimapShowPingInChat"] = "Mostrar ping en el chat"
    L["MinimapHideCalendar"] = "Ocultar calendario"
    L["MinimapHideCalendarDesc"] = "Oculta el botón del calendario"
    L["MinimapHideZoomButtons"] = "Ocultar botones de zoom"
    L["MinimapHideZoomDesc"] = "Oculta los botones de zoom (+) (-)"
    L["MinimapSkinMinimapButtons"] = "Personalizar botones del minimapa"
    L["MinimapSkinMinimapButtonsDesc"] =
        "Cambia el estilo de los botones del minimapa usando LibDBIcon (la mayoría de los addons lo usan)"
    L["MinimapSkinMinimapHideButtons"] = "Ocultar botones del minimapa"
    L["MinimapSkinMinimapHideButtonsDesc"] = "Oculta los botones del minimapa cuando el cursor no está sobre él." ..
                                                 "\n\nNota: solo funciona con botones que usan LibDBIcon"
    L["MinimapZonePanelPosition"] = "Posición del panel de zona"
    L["MinimapZonePanelPositionDesc"] =
        "Establece la posición del panel de texto de la zona, incluyendo los marcos anclados a él (por ejemplo, calendario, rastreo, correo, etc.)."
    L["MinimapUseStateHandler"] = "Usar controlador de estado"
    L["MinimapUseStateHandlerDesc"] =
        "Sin esto, la configuración de visibilidad anterior no funcionará, pero podría mejorar la compatibilidad con otros addons (por ejemplo, MinimapAlert) ya que no hace que los marcos sean seguros."
end

-- UI
do
    L["UIUtility"] = "Utilidad"
    L["UIChangeBags"] = "Cambiar bolsas"
    L["UIChangeBagsDesc"] = ""
    L["UIColoredInventoryItems"] = "Colorear objetos del inventario"
    L["UIColoredInventoryItemsDesc"] = "Activa para colorear los objetos del inventario según su calidad."
    L["UIShowQuestlevel"] = "Mostrar nivel de misión"
    L["UIShowQuestlevelDesc"] = "Muestra el nivel de la misión junto al nombre de la misión."
    L["UIFrames"] = "Marcos"
    L["UIFramesDesc"] = "Opciones para modificar varios marcos del juego."
    L["UIChangeCharacterFrame"] = "Cambiar marco de personaje"
    L["UIChangeCharacterFrameDesc"] = "Cambia la apariencia del marco de personaje."
    L["UIChangeProfessionWindow"] = "Cambiar ventana de profesiones"
    L["UIChangeProfessionWindowDesc"] = "Modifica la apariencia de la ventana de profesiones."
    L["UIChangeInspectFrame"] = "Cambiar marco de inspección"
    L["UIChangeInspectFrameDesc"] = "Cambia la apariencia del marco de inspección."
    L["UIChangeTrainerWindow"] = "Cambiar ventana de instructor"
    L["UIChangeTrainerWindowDesc"] = "Cambia la apariencia de la ventana del instructor."
    L["UIChangeTalentFrame"] = "Cambiar marco de talentos"
    L["UIChangeTalentFrameDesc"] = "Cambia el diseño o apariencia del marco de talentos. (No disponible en Wrath)"
    L["UIChangeSpellBook"] = "Cambiar libro de hechizos"
    L["UIChangeSpellBookDesc"] = "Cambia la apariencia del libro de hechizos."
    L["UIChangeSpellBookProfessions"] = "Cambiar profesiones en el libro de hechizos"
    L["UIChangeSpellBookProfessionsDesc"] = "Modifica el diseño del libro de hechizos para las profesiones."

    -- ProfessionFrame
    L["ProfessionFrameHasSkillUp"] = "Has subido de habilidad"
    L["ProfessionFrameHasMaterials"] = CRAFT_IS_MAKEABLE
    L["ProfessionFrameSubclass"] = "Subclase"
    L["ProfessionFrameSlot"] = "Ranura"
    L["ProfessionCheckAll"] = "Marcar todo"
    L["ProfessionUnCheckAll"] = "Desmarcar todo"
    L["ProfessionFavorites"] = "Favoritos"
end

-- Tooltip
do
    L["TooltipName"] = "Tooltip"
    L["TooltipHeaderGameToltip"] = "Información del juego"
    L["TooltipHeaderSpellTooltip"] = "Información de hechizo"
    L["TooltipCursorAnchorHeader"] = "Anclaje del cursor"
    L["TooltipCursorAnchorHeaderDesc"] = ""
    L["TooltipAnchorToMouse"] = "Anclar al cursor"
    L["TooltipAnchorToMouseDesc"] =
        "Ancla algunas herramientas (por ejemplo, UnitTooltip en WorldFrame) al cursor del ratón."
    L["TooltipMouseAnchor"] = "Anclaje al cursor"
    L["TooltipMouseAnchorDesc"] = ""
    L["TooltipMouseX"] = "X"
    L["TooltipMouseXDesc"] = ""
    L["TooltipMouseY"] = "Y"
    L["TooltipMouseYDesc"] = ""

    -- spelltooltip
    L["TooltipAnchorSpells"] = "Anclar hechizos"
    L["TooltipAnchorSpellsDesc"] =
        "Ancla el SpellTooltip en las barras de acción al botón en lugar del anclaje predeterminado."
    L["TooltipShowSpellID"] = "Mostrar ID del hechizo"
    L["TooltipShowSpellIDDesc"] = ""
    L["TooltipShowSpellSource"] = "Mostrar fuente del hechizo"
    L["TooltipShowSpellSourceDesc"] = ""
    L["TooltipShowSpellIcon"] = "Mostrar icono del hechizo"
    L["TooltipShowSpellIconDesc"] = ""
    L["TooltipShowIconID"] = "Mostrar ID del icono"
    L["TooltipShowIconIDDesc"] = ""
    L["TooltipShowIcon"] = "Mostrar icono"
    L["TooltipShowIconDesc"] = ""

    -- itemtooltip
    L["TooltipHeaderItemTooltip"] = "Información del objeto"
    L["TooltipHeaderItemTooltipDesc"] = ""
    L["TooltipShowItemQuality"] = "Borde de calidad del objeto"
    L["TooltipShowItemQualityDesc"] = ""
    L["TooltipShowItemQualityBackdrop"] = "Fondo de calidad del objeto"
    L["TooltipShowItemQualityBackdropDesc"] = ""
    L["TooltipShowItemStackCount"] = "Mostrar tamaño de pila"
    L["TooltipShowItemStackCountDesc"] = ""
    L["TooltipShowItemID"] = "Mostrar ID del objeto"
    L["TooltipShowItemIDDesc"] = ""

    -- backdrop
    L["TooltipBackdropHeader"] = "Fondo"
    L["TooltipBackdropHeaderDesc"] = ""
    L["TooltipBackdropColor"] = "Color de fondo"
    L["TooltipBackdropColorDesc"] = ""
    L["TooltipBackdropAlpha"] = "Opacidad del fondo"
    L["TooltipBackdropAlphaDesc"] = ""
    L["TooltipBackdropCustomTexture"] = "Textura del fondo"
    L["TooltipBackdropCustomTextureDesc"] = ""

    -- border
    L["TooltipBorderName"] = "Borde"
    L["TooltipBorderNameDesc"] = ""
    L["TooltipBorderCustomTexture"] = "Textura del borde"
    L["TooltipBorderCustomTextureDesc"] = ""
    L["TooltipBorderColor"] = "Color del borde"
    L["TooltipBorderColorDesc"] = ""
    L["TooltipBorderAlpha"] = "Opacidad del borde"
    L["TooltipBorderAlphaDesc"] = ""

    L["TooltipBorderInsetLeft"] = "Margen izquierdo"
    L["TooltipBorderInsetRight"] = "Margen derecho"
    L["TooltipBorderInsetTop"] = "Margen superior"
    L["TooltipBorderInsetBottom"] = "Margen inferior"
    L["TooltipBorderInsetDesc"] = ""

    L["TooltipBorderInsetEdgeSize"] = "Tamaño del borde"
    L["TooltipBorderInsetEdgeSizeDesc"] = ""

    -- statusbar
    L["TooltipUnitHealthbarName"] = "Barra de estado"
    L["TooltipUnitHealthbarNameDesc"] = ""
    L["TooltipUnitHealthbar"] = "Mostrar barra de vida"
    L["TooltipUnitHealthbarDesc"] = ""
    L["TooltipUnitHealthbarHeight"] = "Altura de la barra de vida"
    L["TooltipUnitHealthbarHeightDesc"] = "."
    L["TooltipUnitHealthbarText"] = "Mostrar texto de la barra de vida"
    L["TooltipUnitHealthbarTextDesc"] = ""

    -- unittooltip
    L["TooltipUnitTooltip"] = "Información de la unidad"
    L["TooltipUnitTooltipDesc"] = ""
    L["TooltipUnitClassBorder"] = "Borde de clase"
    L["TooltipUnitClassBorderDesc"] = ""
    L["TooltipUnitClassBackdrop"] = "Fondo de clase"
    L["TooltipUnitClassBackdropDesc"] = ""
    L["TooltipUnitReactionBorder"] = "Borde de reacción"
    L["TooltipUnitReactionBorderDesc"] = ""
    L["TooltipUnitReactionBackdrop"] = "Fondo de reacción"
    L["TooltipUnitReactionBackdropDesc"] = ""
    L["TooltipUnitClassName"] = "Nombre de clase"
    L["TooltipUnitClassNameDesc"] = ""
    L["TooltipUnitTitle"] = "Mostrar título"
    L["TooltipUnitTitleDesc"] = ""
    L["TooltipUnitRealm"] = "Mostrar reino"
    L["TooltipUnitRealmDesc"] = ""
    L["TooltipUnitGuild"] = "Mostrar hermandad"
    L["TooltipUnitGuildDesc"] = ""
    L["TooltipUnitGuildRank"] = "Mostrar rango de hermandad"
    L["TooltipUnitGuildRankDesc"] = ""
    L["TooltipUnitGuildRankIndex"] = "Mostrar índice de rango de hermandad"
    L["TooltipUnitGuildRankIndexDesc"] = ""
    L["TooltipUnitGrayOutOnDeath"] = "Aturdir al morir"
    L["TooltipUnitGrayOutOnDeathDesc"] = ""
    L["TooltipUnitZone"] = "Mostrar texto de zona"
    L["TooltipUnitZoneDesc"] = ""
    L["TooltipUnitHealthbar"] = "Mostrar barra de salud"
    L["TooltipUnitHealthbarDesc"] = ""
    L["TooltipUnitHealthbarText"] = "Mostrar texto de la barra de salud"
    L["TooltipUnitHealthbarTextDesc"] = ""
    L["TooltipUnitTarget"] = "Mostrar objetivo"
    L["TooltipUnitTargetDesc"] = "Mostrar objetivo de la unidad"
end

-- Unitframes
do
    L["UnitFramesName"] = "Marcos de unidad"

    -- Player
    L["PlayerFrameDesc"] = "Configuración del marco del jugador"
    L["PlayerFrameStyle"] = L["ButtonTableStyle"]
    L["PlayerFrameClassColor"] = "Color de clase"
    L["PlayerFrameClassColorDesc"] = "Activa los colores de clase para la barra de vida"
    L["PlayerFrameGradientColor"] = "Color del degradado"
    L["PlayerFrameGradientColorDesc"] =
        "Activa colores degradados para la barra de vida que dependen del porcentaje de vida.\nNo es compatible con los colores de clase."
    L["PlayerFrameClassIcon"] = "Retrato con icono de clase"
    L["PlayerFrameClassIconDesc"] = "Activa el icono de clase como retrato (actualmente desactivado)"
    L["PlayerFrameBreakUpLargeNumbers"] = "Separar números grandes"
    L["PlayerFrameBreakUpLargeNumbersDesc"] =
        "Activa la separación de números grandes en el texto de estado (por ejemplo, 7588 K en lugar de 7588000)"
    L["PlayerFrameBiggerHealthbar"] = "Barra de vida más grande"
    L["PlayerFrameBiggerHealthbarDesc"] = "Activa una barra de vida más grande"
    L["PlayerFramePortraitExtra"] = "Retrato extra"
    L["PlayerFramePortraitExtraDesc"] =
        "Muestra un dragón de élite, raro o jefe de mundo alrededor del marco del jugador."
    L["PlayerFrameHideRedStatus"] = "Ocultar resplandor rojo en combate"
    L["PlayerFrameHideRedStatusDesc"] = "Oculta el resplandor rojo de estado en combate"
    L["PlayerFrameHideHitIndicator"] = "Ocultar indicador de golpe"
    L["PlayerFrameHideHitIndicatorDesc"] = "Oculta el indicador de golpe en el marco del jugador"
    L["PlayerFrameHideSecondaryRes"] = "Ocultar recurso secundario"
    L["PlayerFrameHideSecondaryResDesc"] = "Oculta el recurso secundario, por ejemplo, fragmentos de alma."
    L["PlayerFrameHideAlternatePowerBar"] = "Ocultar barra de poder alternativo de druida"
    L["PlayerFrameHideAlternatePowerBarDesc"] =
        "Oculta la barra de poder alternativo de druida (barra de maná en forma de oso/gato)."
    L["PlayerFrameHideRestingGlow"] = "Ocultar iluminación de descanso"
    L["PlayerFrameHideRestingGlowDesc"] = "Oculta la iluminación de estado de descanso en el marco del jugador."
    L["PlayerFrameHideRestingIcon"] = "Ocultar icono de descanso"
    L["PlayerFrameHideRestingIconDesc"] = "Oculta el icono de descanso en el marco del jugador."
    L["PlayerFrameHidePVP"] = "Ocultar icono JcJ"
    L["PlayerFrameHidePVPDesc"] = "Oculta el icono de JcJ."

    local note =
        "\n\nNOTA: Las texturas personalizadas usan el color de barra predeterminado de Blizzard.\nSi deseas algo diferente, debes modificarlo mediante código.\n"
    L["PlayerFrameCustomHealthbarTexture"] = "Textura de la barra de vida"
    L["PlayerFrameCustomHealthbarTextureDesc"] =
        "Cambia la textura de la barra de vida por una personalizada de LibSharedMedia." .. note
    L["PlayerFrameCustomPowerbarTexture"] = "Textura de la barra de poder"
    L["PlayerFrameCustomPowerbarTextureDesc"] =
        "Cambia la textura de la barra de poder por una personalizada de LibSharedMedia." .. note

    -- Player Secondary< Res
    L["PlayerSecondaryResName"] = "Recurso secundario del jugador"
    L["PlayerSecondaryResNameDesc"] = ""

    -- TotemFrame
    L["PlayerTotemFrameName"] = "Marco de tótems del jugador"
    L["PlayerTotemFrameNameDesc"] = ""

    -- PowerBar_Alt
    L["PowerBarAltName"] = "Barra de poder alternativa del jugador"
    L["PowerBarAltNameDesc"] = ""

    -- Target
    L["TargetFrameDesc"] = "Configuraciones del marco del objetivo"
    L["TargetFrameStyle"] = L["ButtonTableStyle"]
    L["TargetFrameClassColor"] = L["PlayerFrameClassColor"]
    L["TargetFrameClassColorDesc"] = "Activar colores de clase para la barra de vida"
    L["TargetFrameClassIcon"] = L["PlayerFrameClassIcon"]
    L["TargetFrameClassIconDesc"] = L["PlayerFrameClassIconDesc"]
    L["TargetFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["TargetFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["TargetFrameNumericThreat"] = "Amenaza numérica"
    L["TargetFrameNumericThreatDesc"] = "Activar visualización numérica de amenaza"
    L["TargetFrameNumericThreatAnchor"] = "Ancla de amenaza numérica"
    L["TargetFrameNumericThreatAnchorDesc"] = "Establece la posición del ancla de amenaza numérica"
    L["TargetFrameThreatGlow"] = "Resplandor de amenaza"
    L["TargetFrameThreatGlowDesc"] = "Activar efecto de resplandor de amenaza"
    L["TargetFrameHideNameBackground"] = "Ocultar fondo del nombre"
    L["TargetFrameHideNameBackgroundDesc"] = "Ocultar el fondo del nombre del objetivo"
    L["TargetFrameComboPointsOnPlayerFrame"] = "Puntos de combo en el marco del jugador"
    L["TargetFrameComboPointsOnPlayerFrameDesc"] = "Mostrar puntos de combo en el marco del jugador"
    L["TargetFrameHideComboPoints"] = "Ocultar puntos de combo"
    L["TargetFrameHideComboPointsDesc"] = "Ocultar el marco de puntos de combo"
    L["TargetFrameFadeOut"] = "Desvanecimiento"
    L["TargetFrameFadeOutDesc"] =
        "Desvanece el marco de objetivo cuando el objetivo está a más de *Distancia de desvanecimiento* de distancia."
    L["TargetFrameFadeOutDistance"] = "Distancia de desvanecimiento"
    L["TargetFrameFadeOutDistanceDesc"] =
        "Establece la distancia en yardas para comprobar el efecto de desvanecimiento.\nNota: no todos los valores pueden hacer diferencia, ya que usa 'LibRangeCheck-3.0'.\nSe calcula por 'minRange >= fadeOutDistance'."

    L["TargetFrameHeaderBuffs"] = "Beneficios/Perjuicios"
    L["TargetFrameAuraSizeSmall"] = "Tamaño pequeño de auras"
    L["TargetFrameAuraSizeSmallDesc"] =
        "Establece el tamaño de las auras no del jugador en el marco de objetivo cuando se usa 'Tamaño dinámico de beneficios'."
    L["TargetFrameAuraSizeLarge"] = "Tamaño de auras"
    L["TargetFrameAuraSizeLargeDesc"] = "Establece el tamaño de una aura en el marco de objetivo."
    L["TargetFrameNoDebuffFilter"] = "Mostrar todos los perjuicios enemigos"
    L["TargetFrameNoDebuffFilterDesc"] =
        "Muestra perjuicios aliados y enemigos en el marco de objetivo, y no solo los tuyos."
    L["TargetFrameDynamicBuffSize"] = "Tamaño dinámico de beneficios"
    L["TargetFrameDynamicBuffSizeDesc"] =
        "Aumenta el tamaño de los beneficios y perjuicios del jugador en el objetivo."

    -- Pet
    L["PetFrameDesc"] = "Configuraciones del marco de la mascota"
    L["PetFrameStyle"] = L["ButtonTableStyle"]
    L["PetFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["PetFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["PetFrameThreatGlow"] = L["TargetFrameThreatGlow"]
    L["PetFrameThreatGlowDesc"] = L["TargetFrameThreatGlowDesc"]
    L["PetFrameHideStatusbarText"] = "Ocultar texto de la barra de estado"
    L["PetFrameHideStatusbarTextDesc"] = "Ocultar el texto de la barra de estado"
    L["PetFrameHideIndicator"] = "Ocultar indicador de golpe"
    L["PetFrameHideIndicatorDesc"] = "Ocultar el indicador de golpe"

    -- Focus
    L["FocusFrameDesc"] = "Configuraciones del marco de enfoque"
    L["FocusFrameStyle"] = L["ButtonTableStyle"]
    L["FocusFrameClassColor"] = L["PlayerFrameClassColor"]
    L["FocusFrameClassColorDesc"] = "Activar colores de clase para la barra de vida"
    L["FocusFrameClassIcon"] = L["PlayerFrameClassIcon"]
    L["FocusFrameClassIconDesc"] = "Activar icono de clase como retrato para el marco de enfoque"
    L["FocusFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["FocusFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["FocusFrameHideNameBackground"] = L["TargetFrameHideNameBackground"]
    L["FocusFrameHideNameBackgroundDesc"] = "Ocultar el fondo del nombre"

    -- party
    L["PartyFrameDesc"] = "Configuraciones del marco de grupo"
    L["PartyFrameStyle"] = L["ButtonTableStyle"]
    L["PartyFrameClassColor"] = L["PlayerFrameClassColor"]
    L["PartyFrameClassColorDesc"] = "Activar colores de clase para la barra de vida"
    L["PartyFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["PartyFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
end

-- keybindings
do
    -- local KEY_REPLACEMENTS = {
    --     ["ALT%-"] = "a",
    --     ["CTRL%-"] = "c",
    --     ["SHIFT%-"] = "s",
    --     ["META%-"] = "c", -- Note: META is also mapped to C like CTRL
    --     ["NUMPAD"] = "N",
    --     ["PLUS"] = "+",
    --     ["MINUS"] = "-",
    --     ["MULTIPLY"] = "*",
    --     ["DIVIDE"] = "/",
    --     ["BACKSPACE"] = "BS",
    --     ["CAPSLOCK"] = "CP",
    --     ["CLEAR"] = "CL",
    --     ["DELETE"] = "Del",
    --     ["END"] = "En",
    --     ["HOME"] = "HM",
    --     ["INSERT"] = "Ins",
    --     ["MOUSEWHEELDOWN"] = "WD",
    --     ["MOUSEWHEELUP"] = "WU",
    --     ["NUMLOCK"] = "NL",
    --     ["PAGEDOWN"] = "PD",
    --     ["PAGEUP"] = "PU",
    --     ["SCROLLLOCK"] = "SL",
    --     ["SPACEBAR"] = "SP",
    --     ["SPACE"] = "SP",
    --     ["TAB"] = "TB",
    --     ["DOWNARROW"] = "Dn",
    --     ["LEFTARROW"] = "Lf",
    --     ["RIGHTARROW"] = "Rt",
    --     ["UPARROW"] = "Up"
    -- }

    -- local NUM_MOUSE_BUTTONS = 31
    -- for i = 1, NUM_MOUSE_BUTTONS do KEY_REPLACEMENTS["BUTTON" .. i] = "B" .. i end

    -- for k, v in pairs(KEY_REPLACEMENTS) do L[k] = v; end
    -- DF.KEY_REPLACEMENTS = KEY_REPLACEMENTS;
end


-- Missing options, StateHandler, EditMode, Buffs & New Features
do
    L["ActionbarRangeName"] = "Rango de barra de acción"
    L["ActionbarRangeNameDesc"] = ""
    L["ActionbarRangeHeader"] = "Ajustes de rango"
    L["ActionbarRangeHeaderDesc"] = ""
    L["ActionbarRangeHeaderHotkey"] = "Atajo de teclado"
    L["ActionbarRangeHeaderHotkeyDesc"] = ""
    L["ActionbarRangeHotkeyColor"] = "Normal"
    L["ActionbarRangeHotkeyColorDesc"] = "Color normal del texto del atajo."
    L["ActionbarRangeHotkeyOutOfRangeColor"] = "Fuera de rango"
    L["ActionbarRangeHotkeyOutOfRangeColorDesc"] = "Color del texto del atajo cuando está fuera de rango."
    L["ActionbarRangeHeaderNotUsable"] = "No utilizable"
    L["ActionbarRangeHeaderNotUsableDesc"] = ""
    L["ActionbarRangeHeaderOutOfMana"] = "Sin maná"
    L["ActionbarRangeHeaderOutOfManaDesc"] = ""
    L["ActionbarRangeHeaderOutOfRange"] = "Fuera de rango"
    L["ActionbarRangeHeaderOutOfRangeDesc"] = ""

    L["BossFrameName"] = "Marcos de jefe"
    L["BossFrameNameDesc"] = "Opciones para marcos de jefe"

    L["CastbarNameFocus"] = "Foco"
    L["CastbarNamePlayer"] = "Jugador"
    L["CastbarNameTarget"] = "Objetivo"
    L["CastbarTableAutoAdjustHeader"] = "Ajuste automático"
    L["CastbarTableAutoAdjustHeaderDesc"] = "Ajusta la posición automáticamente con respecto a auras o barras."
    L["CastbarTableAutoAdjustX"] = "Desplazamiento X automático"
    L["CastbarTableAutoAdjustXDesc"] = ""
    L["CastbarTableAutoAdjustY"] = "Desplazamiento Y automático"
    L["CastbarTableAutoAdjustYDesc"] = ""
    L["CastbarTableAutoAdjust"] = "Ajustar automáticamente"
    L["CastbarTableAutoAdjustDesc"] = "Mueve la barra de lanzamiento automáticamente."

    L["CharacterStatsArp"] = "Penetración de armadura"
    L["CharacterStatsArpTooltipFormat"] = "Penetración de armadura: %s"
    L["CharacterStatsHitMeleeTooltipFormat"] = "Índice de golpe cuerpo a cuerpo: %s"
    L["CharacterStatsHitSpellTooltipFormat"] = "Índice de golpe con hechizos: %s"
    L["CharacterStatsSpellPen"] = "Penetración de hechizos"
    L["CharacterStatsSpellPenTooltipFormat"] = "Penetración de hechizos: %s"

    L["CompatBisTracker"] = "BISTracker"
    L["CompatBisTrackerDesc"] = "Añade compatibilidad con BISTracker en el marco de personaje."
    L["CompatPawn"] = "Pawn"
    L["CompatPawnDesc"] = "Añade soporte para estadísticas de Pawn."
    L["DebuffsOptionsName"] = "Perjuicios"

    L["EditModeVisible"] = "Visibilidad en modo edición"
    L["EditModeVisibleDescFormat"] = "Establece la visibilidad en modo edición para este marco."

    L["FocusFrameName"] = "Marco de foco"
    L["FocusFrameToTName"] = "Objetivo del foco"

    L["GroupLootContainerName"] = "Contenedor de botín de grupo"
    L["GroupLootContainerDesc"] = "Opciones para las tiradas de botín en grupo."

    L["MinimapDurabilityName"] = "Durabilidad"
    L["MinimapHideClock"] = "Ocultar reloj"
    L["MinimapHideClockDesc"] = "Oculta el reloj en el minimapa."
    L["MinimapHideHeader"] = "Ocultar"
    L["MinimapHideHeaderDesc"] = ""
    L["MinimapHideZoneText"] = "Ocultar texto de zona"
    L["MinimapHideZoneTextDesc"] = "Oculta el nombre de la zona sobre el minimapa."
    L["MinimapLFGName"] = "Buscador de grupo"
    L["MinimapRotateDescAdditional"] = ""
    L["MinimapShape"] = "Forma"
    L["MinimapShapeDesc"] = "Forma del minimapa (Redondo o Cuadrado)."
    L["MinimapTrackerName"] = "Seguimiento de objetivos"

    L["ModuleAlreadyLoadedWasDeactivated"] = "El módulo ya estaba cargado y fue desactivado: %s"
    L["ModuleAlreadyLoadedWasDeactivatedMultiple"] = "Los módulos ya estaban cargados y fueron desactivados:\n%s"

    L["MoreOptionsHideBorder"] = "Ocultar borde"
    L["MoreOptionsHideBorderDesc"] = "Oculta el borde de los botones de acción."
    L["MoreOptionsHideDivider"] = "Ocultar divisor"
    L["MoreOptionsHideDividerDesc"] = "Oculta las líneas divisorias entre botones."
    L["MoreOptionsUseKeyDown"] = ACTION_BUTTON_USE_KEY_DOWN or "Activar al presionar tecla"
    L["MoreOptionsUseKeyDownDesc"] = OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN or "Activa habilidades al presionar la tecla en lugar de soltarla."

    L["PartyFrameDisableBuffTooltip"] = "Desactivar tooltip de auras"
    L["PartyFrameDisableBuffTooltipDesc"] = "Desactiva los tooltips en los beneficios de grupo."
    L["PartyFrameName"] = "Marco de grupo"

    L["PetFrameHideDebuffs"] = "Ocultar perjuicios"
    L["PetFrameHideDebuffsDesc"] = "Oculta los perjuicios en la mascota."
    L["PetFrameName"] = "Marco de mascota"
    L["PlayerFrameName"] = "Marco del jugador"
    L["ProfessionExpansionFormat"] = "Expansión: %s"
    L["RaidFrameName"] = "Marco de banda"

    L["TargetFrameAuraOffsetY"] = "Desplazamiento Y de auras"
    L["TargetFrameAuraOffsetYDesc"] = "Espacio vertical entre filas de auras."
    L["TargetFrameAuraRowWidth"] = "Ancho de fila de auras"
    L["TargetFrameAuraRowWidthDesc"] = "Ancho máximo de la fila de auras."
    L["TargetFrameAuraRowWidthToT"] = "Ancho de fila de auras (OdO)"
    L["TargetFrameAuraRowWidthToTDesc"] = "Ancho reducido para dejar espacio al objetivo del objetivo."
    L["TargetFrameHeaderBuffsAdvanced"] = "Auras (Avanzado)"
    L["TargetFrameName"] = "Marco del objetivo"
    L["TargetFrameReactionColor"] = "Color de reacción"
    L["TargetFrameReactionColorDesc"] = "Colorea la barra según la actitud (Amigo/Enemigo)."
    L["TargetFrameToTAuraRows"] = "Filas de auras OdO"
    L["TargetFrameToTAuraRowsDesc"] = "Número de filas de auras con ancho reducido."
    L["TargetOfTargetFrameDesc"] = "Opciones para objetivo del objetivo"
    L["TargetOfTargetFrameName"] = "Objetivo del objetivo"

    L["TooltipAnchorName"] = "Anclaje del tooltip"
    L["TooltipDefaultAnchorWhileCombat"] = "Posición predeterminada en combate"
    L["TooltipDefaultAnchorWhileCombatDesc"] = "Usa la posición fija en lugar del cursor en combate."
    L["UIName"] = "Interfaz de usuario"
    L["VehicleLeaveButton"] = "Salir del vehículo"
    L["VehicleLeaveButtonDesc"] = "Botón para salir de vehículos."
    L["WidgetBelowName"] = "Widget debajo del minimapa"
    L["WidgetBelowNameDesc"] = "Posición del widget debajo del minimapa."

    L["BuffsAura"] = "Aura"
    L["BuffsHeaderAura"] = "Encabezado de auras"
    L["BuffsHeaderAuraDesc"] = ""
    L["BuffsPaddingX"] = "Espaciado X"
    L["BuffsPaddingXDesc"] = "Espaciado X entre auras."
    L["BuffsPaddingY"] = "Espaciado Y"
    L["BuffsPaddingYDesc"] = "Espaciado Y entre filas de auras."
    L["BuffsWrapAfter"] = "Ajustar tras"
    L["BuffsWrapAfterDesc"] = "Comienza una nueva fila tras esta cantidad de auras.\nSi es 0, no se ajusta."
    L["BuffsMaxWraps"] = "Máx. filas"
    L["BuffsMaxWrapsDesc"] = "Limita el número de filas.\nSi es 0, sin límite."
    L["BuffsSeperateOwn"] = "Separar auras propias"
    L["BuffsSeperateOwnDesc"] = "Indica si los beneficios propios deben colocarse antes (1) o después (-1).\nSi es (0), no se separan."
    L["BuffsSortMethod"] = "Método de ordenación"
    L["BuffsSortMethodDesc"] = "Define cómo se ordena el grupo."
    L["BuffsSortDirection"] = "Dirección de ordenación"
    L["BuffsSortDirectionDesc"] = "Define el orden de clasificación."
    L["BuffsPoint"] = "Punto de anclaje"
    L["BuffsPointDesc"] = ""
    L["BuffsOrientation"] = "Orientación"
    L["BuffsOrientationDesc"] = ""
    L["BuffsGrowthDirection"] = "Dirección de crecimiento"
    L["BuffsGrowthDirectionDesc"] = ""
    L["BuffsHeaderStylingAura"] = "Estilo de auras"
    L["BuffsHeaderStylingAuraDesc"] = ""
    L["BuffsHideDurationText"] = "Ocultar texto de duración"
    L["BuffsHideDurationTextDesc"] = ""
    L["BuffsHideCooldownSwipe"] = "Ocultar animación de reutilización"
    L["BuffsHideCooldownSwipeDesc"] = ""
    L["BuffsHideCooldownDurationText"] = "Ocultar texto de reutilización"
    L["BuffsHideCooldownDurationTextDesc"] = ""

    L["CompatGearscore"] = "GearScore"
    L["CompatGearscoreDesc"] = "Añade compatibilidad con GearScore/Tacotip en el marco de personaje."
    L["CompatQuestie"] = "Questie"
    L["CompatQuestieDesc"] = "Añade soporte para Questie en el minimapa."

    L["EditModeGridSize"] = "Tamaño de cuadrícula"
    L["EditModeHeaderTitle"] = "Modo edición de HUD"
    L["EditModeRevertAllChanges"] = "Revertir todos los cambios"
    L["EditModeSave"] = "Guardar"
    L["EditModeShowGrid"] = "Mostrar cuadrícula"
    L["EditModeSnapToGrid"] = "Ajustar a cuadrícula"

    L["FlyoutInventoryCount"] = "Mostrar cantidad de objetos"
    L["FlyoutInventoryCountDesc"] = "Muestra la cantidad restante de reactivos en el botón."

    L["ModuleGroupLoot"] = "Botín de grupo"
    L["ModuleNameplates"] = "Placas de nombre"
    L["ModuleTooltipGroupLoot"] = "Muestra tiradas de botín en una barra moderna."
    L["ModuleTooltipNameplates"] = "Habilita placas de nombre modernas."

    L["MoreOptionsBorderFill"] = "Relleno del borde"
    L["MoreOptionsBorderFillDesc"] = "Relleno oscuro dentro del borde del botón de acción."

    L["Open"] = "Abrir"
    L["PlayerFrameGradientColor"] = "Color en degradado"
    L["PlayerFrameGradientColorDesc"] = "Usa un degradado suave en la barra de salud."
    L["PositionTableStandalone"] = "Independiente"
    L["PositionTableStandaloneDesc"] = "Hace que el marco se pueda mover independientemente."
    L["RaidFrameSettings"] = "Ajustes de marco de banda"

    L["StateHandlerAlphaCombat"] = "Transparencia (en combate)"
    L["StateHandlerAlphaCombatDesc"] = "Transparencia del marco durante el combate."
    L["StateHandlerAlphaNormal"] = "Transparencia"
    L["StateHandlerAlphaNormalDesc"] = "Transparencia del marco fuera de combate."
    L["StateHandlerHeaderVis"] = "Visibilidad"
    L["StateHandlerHideAlways"] = "Ocultar siempre"
    L["StateHandlerHideBattlePet"] = "Ocultar en duelo de mascotas"
    L["StateHandlerHideCombat"] = "Ocultar en combate"
    L["StateHandlerHideCustom"] = "Usar condición personalizada"
    L["StateHandlerHideCustomCond"] = "Definir condición personalizada"
    L["StateHandlerHideCustomCondDesc"] = "Usa sintaxis condicional de macros que devuelvan 'show' o 'hide'."
    L["StateHandlerHideCustomDesc"] = "Usa condiciones de macros.\n|cFFFF0000Nota: ¡Esto desactivará los ajustes superiores!|r"
    L["StateHandlerHideNoPet"] = "Ocultar sin mascota"
    L["StateHandlerHideNoStealth"] = "Ocultar fuera de sigilo"
    L["StateHandlerHideOutOfCombat"] = "Ocultar fuera de combate"
    L["StateHandlerHidePet"] = "Ocultar con mascota"
    L["StateHandlerHideStance"] = "Ocultar sin postura/forma"
    L["StateHandlerHideStealth"] = "Ocultar en sigilo"
    L["StateHandlerHideVehicle"] = "Ocultar con interfaz de vehículo"
    L["StateHandlerMacroCondition"] = "Condición de macro: "
    L["StateHandlerShowMouseover"] = "Mostrar al pasar el ratón"
    L["StateHandlerShowMouseoverDesc"] = "Invalida temporalmente las condiciones de ocultación al pasar el ratón."

    L["WhatsNewOpen"] = "Novedades"
    L["WhatsNewOpenButton"] = "Abrir"
    L["WhatsNewOpenDesc"] = "Abre la ventana con las notas de la versión."

    L["DropdownBefore"] = "Antes"
    L["DropdownAfter"] = "Después"
    L["DropdownNoSeperation"] = "Sin separación"
    L["DropdownSortIndex"] = "Índice"
    L["DropdownSortName"] = "Nombre"
    L["DropdownSortTime"] = "Tiempo"
    L["DropdownLeftToRight"] = "De izquierda a derecha"
    L["DropdownRightToLeft"] = "De derecha a izquierda"
    L["DropdownHorizontal"] = "Horizontal"
    L["DropdownVertical"] = "Vertical"
    L["DropdownUp"] = "Arriba"
    L["DropdownDown"] = "Abajo"
    L["DropdownLeft"] = "Izquierda"
    L["DropdownRight"] = "Derecha"
end

local L_ES = LibStub("AceLocale-3.0"):NewLocale("DragonflightUI", "esES")
local L_MX = LibStub("AceLocale-3.0"):NewLocale("DragonflightUI", "esMX")

if L_ES then for k, v in pairs(L) do L_ES[k] = v; end end

if L_MX then for k, v in pairs(L) do L_MX[k] = v; end end
