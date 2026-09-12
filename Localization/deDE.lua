local DF = LibStub("AceAddon-3.0"):GetAddon("DragonflightUI")
local L_DE = LibStub("AceLocale-3.0"):NewLocale("DragonflightUI", "deDE")
if not L_DE then return end

-- Note: German translations are AI-generated. Community review and contributions are welcome!
-- preprocess to reuse strings - without this L[XY] = L['X'] will fail in AceLocale
local L = {}

-- modules - config.lua
do
    L["ModuleModules"] = "Module"
    L["ModuleTooltipActionbar"] = "Dieses Modul überarbeitet die Standard-Aktionsleiste inklusive Mikromenü und Taschenleiste.\nFügt separate Optionen für Aktionsleiste 1-8, Begleiter-, Erfahrungs-, Ruf-, Übernahme-, Haltungs-, Totemleiste, Taschen und Mikromenü hinzu."
    L["ModuleTooltipBossframe"] = "Dieses Modul fügt benutzerdefinierte Boss-Einheitenfenster hinzu.\nIN ARBEIT."
    L["ModuleTooltipBuffs"] = "Dieses Modul überarbeitet das Standard-Stärkungszauber-Fenster.\nFügt separate Optionen für Stärkungs- und Schwächungszauber hinzu."
    L["ModuleTooltipCastbar"] = "Dieses Modul überarbeitet die Standard-Zauberleiste.\nFügt separate Optionen für Spieler-, Fokus- und Ziel-Zauberleiste hinzu."
    L["ModuleTooltipChat"] = "Dieses Modul überarbeitet das Standard-Chatfenster.\nIN ARBEIT."
    L["ModuleTooltipCompatibility"] = "Dieses Modul fügt zusätzliche Kompatibilität mit anderen Addons hinzu."
    L["ModuleTooltipDarkmode"] = "Dieses Modul fügt vielen Fenstern von DragonflightUI einen Dunkelmodus hinzu.\nIN ARBEIT – Feedback ist willkommen!"
    L["ModuleTooltipFlyout"] = "Zauberauswahl"
    L["ModuleTooltipMinimap"] = "Dieses Modul überarbeitet die Standard-Minimap und die Questverfolgung.\nFügt separate Optionen für Minimap und Questverfolgung hinzu."
    L["ModuleTooltipTooltip"] = "Dieses Modul verbessert die Tooltips im Spiel.\nIN ARBEIT"
    L["ModuleTooltipUI"] = "Dieses Modul verleiht verschiedenen Fenstern wie dem Charakterfenster den modernen UI-Stil. Fügt auch Ära-spezifische Überarbeitungen für Zauberbuch, Talentfenster und Berufsfenster hinzu."
    L["ModuleTooltipUnitframe"] = "Dieses Modul überarbeitet die Standard-Einheitenfenster und fügt neue Funktionen wie Klassenfarben oder MobHealth (Ära) hinzu.\nFügt separate Optionen für Spieler-, Begleiter-, Ziel-, Fokus- und Gruppenfenster hinzu."
    L["ModuleTooltipUtility"] = "Dieses Modul fügt allgemeine UI-Funktionen und Optimierungen hinzu.\nIN ARBEIT"
    L["ModuleTooltipGroupLoot"] = "Zeigt Beutewürfe in einer modernen Leiste an."
    L["ModuleFlyout"] = "Zauberauswahl"
    L["ModuleNameplates"] = "Namensplaketten"
    L["ModuleTooltipNameplates"] = "Aktiviert moderne Namensplaketten."
    L["ModuleActionbar"] = "Aktionsleiste"
    L["ModuleCastbar"] = "Zauberleiste"
    L["ModuleChat"] = "Chat"
    L["ModuleBuffs"] = "Stärkungszauber"
    L["ModuleDarkmode"] = "Dunkelmodus"
    L["ModuleMinimap"] = "Minimap"
    L["ModuleTooltip"] = "Tooltip"
    L["ModuleUI"] = "Benutzeroberfläche"
    L["ModuleUnitframe"] = "Einheitenfenster"
    L["ModuleUtility"] = "Nützliches"
    L["ModuleCompatibility"] = "Kompatibilität"
    L["ModuleBossframe"] = "Bossfenster"
    L["ModuleGroupLoot"] = "Gruppenbeute"
    L["ModuleAlreadyLoadedWasDeactivated"] = "Bereits geladenes Modul wurde deaktiviert, bitte '/reload' ausführen!"
    L["ModuleAlreadyLoadedWasDeactivatedMultiple"] = "Mehrere bereits geladene Module wurden deaktiviert, bitte '/reload' ausführen!"
end

-- config
do
    L["ConfigGeneralWhatsNew"] = "Was gibt's Neues"
    L["WhatsNewOpen"] = "Was gibt's Neues"
    L["WhatsNewOpenButton"] = "Öffnen"
    L["WhatsNewOpenDesc"] = "Öffnet das Fenster mit den neuesten Änderungen."
    L["ConfigGeneralModules"] = "Module"
    L["ConfigGeneralInfo"] = "Info"
    L["MainMenuDragonflightUI"] = "DragonflightUI"
    L["MainMenuEditmode"] = "Bearbeitungsmodus"

    -- config.mixin.lua
end

-- config.mixin.lua
do
    L["ConfigMixinQuickKeybindMode"] = "Schnellbelegungsmodus"
    L["ConfigMixinGeneral"] = "Allgemein"
    L["ConfigMixinModules"] = "Module"
    L["ConfigMixinActionBar"] = "Aktionsleiste"
    L["ConfigMixinCastBar"] = "Zauberleiste"
    L["ConfigMixinMisc"] = "Verschiedenes"
    L["ConfigMixinUnitframes"] = "Einheitenfenster"

    -- modules.mixin.lua
end

-- modules.mixin.lua
do
    L["ModuleConditionalMessage"] = "'|cff8080ff%s|r' wurde deaktiviert, aber die zugehörige Funktion war bereits eingehängt, bitte '|cff8080ff/reload|r' ausführen!"

    -- config
end

-- config
do
    L["ConfigToolbarCopyPopup"] = "Kopiere den untenstehenden Link (Strg+C, Eingabe):"
    L["ConfigToolbarDiscord"] = "Discord"
    L["ConfigToolbarDiscordTooltip"] = "Ideen einbringen & Hilfe erhalten."
    L["ConfigToolbarGithub"] = "GitHub"
    L["ConfigToolbarGithubTooltip"] = "Code ansehen, Probleme melden & beitragen."
end

-- profiles
do
    L["ProfilesSetActiveProfile"] = "Aktives Profil festlegen."
    L["ProfilesNewProfile"] = "Neues Profil"
    L["ProfilesCopyFrom"] = "Kopiert die Einstellungen eines vorhandenen Profils in das aktuell aktive Profil."
    L["ProfilesOpenCopyDialogue"] = "Öffnet den Kopieren-Dialog."
    L["ProfilesDeleteProfile"] = "Profil löschen"
    L["Profiles"] = "Neues Profil hinzufügen"
    L["ProfilesOpenDeleteDialogue"] = "Öffnet den Löschen-Dialog."
    L["ProfilesAddNewProfile"] = "Neues Profil hinzufügen"
    L["ProfilesChatNewProfile"] = "Neues Profil: "
    L["ProfilesErrorNewProfile"] = "FEHLER: Der Profilname darf nicht leer sein!"
    L["ProfilesDialogueDeleteProfile"] = "Profil '%s' wirklich löschen?"
    L["ProfilesDialogueCopyProfile"] = "Neues Profil hinzufügen (Kopie von '|cff8080ff%s|r')"
    L["ProfilesTitle"] = "Profile"
    L["ProfilesCurrentProfile"] = "Aktuelles Profil"
    L["ProfilesNewProfileTitle"] = "Neues Profil"
    L["ProfilesCreateButton"] = "Erstellen"
    L["ProfilesDeleteProfileTitle"] = "Profil löschen"
    L["ProfilesProfileToDelete"] = "Zu löschendes Profil"
    L["ProfilesDeleteButton"] = "Löschen"
    L["ProfilesImportShareHeader"] = "Importieren / Teilen"
    L["ProfilesImportProfile"] = "Profil importieren"
    L["ProfilesImportProfileButton"] = HUD_EDIT_MODE_IMPORT_LAYOUT or "Importieren"
    L["ProfilesImportProfileDesc"] = "Öffnet den Import-Dialog."
    L["ProfilesExportProfile"] = "Profil teilen"
    L["ProfilesExportProfileButton"] = HUD_EDIT_MODE_SHARE_LAYOUT or "Teilen"
    L["ProfilesExportProfileDesc"] = "Öffnet den Teilen-Dialog."
end

-- Editmode
do
    L["EditModeBasicOptions"] = "Grundlegende Optionen"
    L["EditModeAdvancedOptions"] = "Erweiterte Optionen"
    L["EditModeLayoutDropdown"] = "Profil"
    L["EditModeCopyLayout"] = "Profil kopieren"
    L["EditModeRenameLayout"] = "Profil umbenennen"
    L["EditModeRenameOrCopyLayout"] = "Profil umbenennen / kopieren"
    L["EditModeDeleteLayout"] = "Profil löschen"
    L["EditModeNewLayoutDisabled"] = "%s Neues Profil"
    L["EditModeNewLayout"] = "%s |cnPURE_GREEN_COLOR:Neues Profil|r"
    L["EditModeImportLayout"] = HUD_EDIT_MODE_IMPORT_LAYOUT or "Importieren"
    L["EditModeShareLayout"] = HUD_EDIT_MODE_SHARE_LAYOUT or "Teilen"
    L["EditModeCopyToClipboard"] = HUD_EDIT_MODE_COPY_TO_CLIPBOARD or "In die Zwischenablage kopieren"
    L["EditModeExportProfile"] = "Profil exportieren: |cff8080ff%s|r"
    L["EditModeImportProfile"] = "Profil importieren als: |cff8080ff%s|r"
    L["EditModeVisible"] = "Sichtbarkeit im Bearbeitungsmodus"
    L["EditModeVisibleDescFormat"] = "Legt die Sichtbarkeit des aktuellen Fensters und aller anderen Fenster derselben Kategorie (|cff8080ff%s|r) im Bearbeitungsmodus fest.\n\nKann jederzeit über die |cff8080ffErweiterten Optionen|r im Bearbeitungsmodus-Fenster oder im DragonflightUI-|cff8080ffKonfigurationsfenster|r angepasst werden."
    L["EditModeHeaderTitle"] = "HUD-Bearbeitungsmodus"
    L["EditModeRevertAllChanges"] = "Alle Änderungen verwerfen"
    L["EditModeSave"] = "Speichern"
    L["EditModeShowGrid"] = "Raster anzeigen"
    L["EditModeGridSize"] = "Rastergröße"
    L["EditModeSnapToGrid"] = "Am Raster ausrichten"
end

-- StateHandler
do
    L["StateHandlerHeaderVis"] = "Sichtbarkeit"
    L["StateHandlerAlphaNormal"] = "Transparenz"
    L["StateHandlerAlphaNormalDesc"] = "Fenstertransparenz außerhalb des Kampfes."
    L["StateHandlerAlphaCombat"] = "Transparenz (Im Kampf)"
    L["StateHandlerAlphaCombatDesc"] = "Fenstertransparenz während des Kampfes."
    L["StateHandlerShowMouseover"] = "Bei Mausberührung anzeigen"
    L["StateHandlerShowMouseoverDesc"] = "Hebt die untenstehenden Ausblendbedingungen bei Mausberührung vorübergehend auf."
    L["StateHandlerHideAlways"] = "Immer ausblenden"
    L["StateHandlerHideCombat"] = "Im Kampf ausblenden"
    L["StateHandlerHideOutOfCombat"] = "Außerhalb des Kampfes ausblenden"
    L["StateHandlerHideVehicle"] = "Mit Fahrzeug-UI ausblenden"
    L["StateHandlerHidePet"] = "Mit Begleiter ausblenden"
    L["StateHandlerHideNoPet"] = "Ohne Begleiter ausblenden"
    L["StateHandlerHideStance"] = "Ohne Haltung/Gestalt ausblenden"
    L["StateHandlerHideStealth"] = "In Verstohlenheit ausblenden"
    L["StateHandlerHideNoStealth"] = "Außerhalb von Verstohlenheit ausblenden"
    L["StateHandlerHideBattlePet"] = "Im Haustierkampf ausblenden"
    L["StateHandlerHideCustom"] = "Eigene Bedingung verwenden"
    L["StateHandlerHideCustomDesc"] = "Verwendet Makro-Bedingungssyntax.\n|cFFFF0000Hinweis: Dies deaktiviert alle obigen Einstellungen!|r"
    L["StateHandlerHideCustomCond"] = "Eigene Bedingung festlegen"
    L["StateHandlerHideCustomCondDesc"] = "Verwendet Makro-Bedingungssyntax, aber anstelle des Zaubernamens sollte die Rückgabe |cff8080ff'show'|r zum Einblenden oder |cff8080ff'hide'|r zum Ausblenden sein.\n\nBeispiel:\n|cff8080ff[combat]show;[@target,exists]show;hide|r\n(Blendet das Fenster im Kampf oder bei existierendem Ziel ein)"
    L["StateHandlerMacroCondition"] = "Makro-Bedingung: "
    L["RaidFrameSettings"] = "Schlachtzugsfenster-Einstellungen"
    L["Open"] = "Öffnen"
end

-- Compat
do
    L["CompatName"] = "Kompatibilität"
    L["CompatAuctionator"] = "Auctionator"
    L["CompatAuctionatorDesc"] = "Fügt Kompatibilität für Auctionator bei aktiviertem modernem Berufsfenster hinzu."
    L["CompatBaganator"] = "Baganator_Skin"
    L["CompatBaganatorDesc"] = "Ändert den Standard-'Blizzard'-Skin in einen DragonflightUI-Stil."
    L["CompatBaganatorEquipment"] = "Baganator_EquipmentSets"
    L["CompatBaganatorEquipmentDesc"] = "Fügt Unterstützung für Ausrüstungssets als Gegenstandsquelle hinzu."
    L["CompatBisTracker"] = "BISTracker"
    L["CompatBisTrackerDesc"] = "Fügt Kompatibilität für BISTracker bei aktiviertem modernem Charakterfenster hinzu."
    L["CompatCharacterStatsClassic"] = "CharacterStatsClassic"
    L["CompatCharacterStatsClassicDesc"] = "Fügt Unterstützung für Charakterwerte bei aktiviertem modernem Charakterfenster hinzu."
    L["CompatClassicCalendar"] = "Classic Calendar"
    L["CompatClassicCalendarDesc"] = "Fügt Kompatibilität für Classic Calendar hinzu."
    L["CompatClique"] = "Clique"
    L["CompatCliqueDesc"] = "Fügt Kompatibilität für Clique hinzu."
    L["CompatLeatrixPlus"] = "Leatrix_Plus"
    L["CompatLeatrixPlusDesc"] = "Deaktiviert die minimap-bezogenen Optionen von Leatrix Plus, um Inkompatibilitäten zu vermeiden."
    L["CompatLFGBulletinBoard"] = "LFG Bulletin Board"
    L["CompatLFGBulletinBoardDesc"] = "Fügt Kompatibilität für LFG Bulletin Board hinzu."
    L["CompatMerInspect"] = "MerInspect"
    L["CompatMerInspectDesc"] = "Fügt Kompatibilität für MerInspect bei aktiviertem modernem Charakterfenster hinzu."
    L["CompatPawn"] = "Pawn"
    L["CompatPawnDesc"] = "Fügt Unterstützung für Pawn-Gegenstandswerte hinzu."
    L["CompatQuestie"] = "Questie"
    L["CompatQuestieDesc"] = "Fügt Unterstützung für Questie am Kompass der Minimap hinzu."
    L["CompatRanker"] = "Ranker"
    L["CompatRankerDesc"] = "Fügt Unterstützung für das PvP-Addon Ranker im modernen Charakterfenster hinzu."
    L["CompatTacoTip"] = "TacoTip"
    L["CompatTacoTipDesc"] = "Fügt Unterstützung für TacoTip-Tooltips hinzu."
    L["CompatGearscore"] = "GearScore"
    L["CompatGearscoreDesc"] = "Fügt Unterstützung für GearScoreLite/Tacotip im modernen Charakterfenster hinzu."
    L["CompatTDInspect"] = "TDInspect"
    L["CompatTDInspectDesc"] = "Fügt Kompatibilität für TDInspect bei aktiviertem modernem Charakterfenster hinzu."
    L["CompatWhatsTraining"] = "WhatsTraining"
    L["CompatWhatsTrainingDesc"] = "Fügt einen Reiter für WhatsTraining im modernen Zauberbuch hinzu."
end

-- __Settings
do
    L["Defaults"] = "Standard"
    L["SettingsDefaultStringFormat"] = "\n(Standard: |cff8080ff%s|r)"
    L["SettingsCharacterSpecific"] = "\n\n|cff8080ff[Charakterspezifische Einstellung]|r"

    -- positionTable
end

-- positionTable
do
    L["PositionTableHeader"] = "Position"
    L["PositionTableHeaderDesc"] = ""
    L["PositionTableScale"] = "Skalierung"
    L["PositionTableScaleDesc"] = "Skalierung des Elements."
    L["PositionTableAnchor"] = "Ankerpunkt"
    L["PositionTableAnchorDesc"] = "Ankerpunkt des Fensters."
    L["PositionTableAnchorParent"] = "Übergeordneter Anker"
    L["PositionTableAnchorParentDesc"] = ""
    L["PositionTableStandalone"] = "Eigenständig"
    L["PositionTableStandaloneDesc"] = "Macht das Element unabhängig von anderen UI-Elementen beweglich."
    L["PositionTableAnchorFrame"] = "Anker-Fenster"
    L["PositionTableAnchorFrameDesc"] = ""
    L["PositionTableCustomAnchorFrame"] = "Eigener Ankerrahmen"
    L["PositionTableCustomAnchorFrameDesc"] = "Name des benutzerdefinierten Rahmens, an den verankert werden soll."
    L["PositionTableX"] = "X-Versatz"
    L["PositionTableXDesc"] = "Horizontaler Versatz in Pixeln."
    L["PositionTableY"] = "Y-Versatz"
    L["PositionTableYDesc"] = "Vertikaler Versatz in Pixeln."
end

-- darkmode
do
    L["DarkmodeColor"] = "Farbe"
    L["DarkmodeDesaturate"] = "Entsättigen"
    L["DarkmodeDarkenPortraitExtra"] = "Drachen-Symbol abdunkeln"
    L["DarkmodeDarkenPortraitExtraDesc"] = "Dunkelt das Drachensymbol (Elite/Selten) an Einheitenfenstern mit ab. Ist diese Option deaktiviert, bleibt es in normaler Helligkeit."
end

-- actionbar
do
    L["ActionbarName"] = "Aktionsleiste"
    L["ActionbarNameFormat"] = "Aktionsleiste %d"
end

-- bar names
do
    L["XPBar"] = "Erfahrungsleiste"
    L["ReputationBar"] = "Rufleiste"
    L["PetBar"] = "Begleiterleiste"
    L["StanceBar"] = "Haltungsleiste"
    L["PossessBar"] = "Übernahmeleiste"
    L["MicroMenu"] = "Mikromenü"
    L["TotemBar"] = "Totemleiste"

    -- gryphonsTable
end

-- gryphonsTable
do
    L["Default"] = "Standard"
    L["Alliance"] = "Allianz"
    L["Horde"] = "Horde"
    L["None"] = "Keine"

    -- stateDriverTable
end

-- stateDriverTable
do
    L["ActionbarDriverDefault"] = "Standard"
    L["ActionbarDriverSmart"] = "Intelligent"
    L["ActionbarDriverNoPaging"] = "Kein Seitenwechsel"

    -- stateDriver
end

-- stateDriver
do
    L["ActionbarDriverName"] = "Zustands-Treiber"
    L["ActionbarDriverNameDesc"] = ""
end

-- targetStateDriver
do
    L["ActionbarTargetDriverConditionalFormat"] = "Bedingung: %s"
    L["ActionbarTargetDriverMultipleConditionalFormat"] = "Mehrere Bedingungen: %s"
    L["ActionbarTargetDriverHeader"] = "Automatischer Zielwechsel & Zauberziele"
    L["ActionbarTargetDriverUseMouseover"] = "Mouseover-Zaubern verwenden"
    L["ActionbarTargetDriverUseMouseoverDesc"] = "Wirkt Zauber auf die Einheit unter dem Mauszeiger."
    L["ActionbarTargetDriverMouseOverModifier"] = "Mouseover-Modifikator"
    L["ActionbarTargetDriverMouseOverModifierDesc"] = "Tastenmodifikator für Mouseover-Zauber."
    L["ActionbarTargetDriverUseAutoAssist"] = "Automatisches Unterstützen (Auto-Assist)"
    L["ActionbarTargetDriverUseAutoAssistDesc"] = "Greift automatisch das Ziel des anvisierten Verbündeten an."
    L["ActionbarTargetDriverFocusCast"] = "Fokus-Zauber"
    L["ActionbarTargetDriverFocusCastDesc"] = "Aktiviert das Wirken auf das Fokusziel."
    L["ActionbarTargetDriverFocusCastModifier"] = "Fokus-Modifikator"
    L["ActionbarTargetDriverFocusCastModifierDesc"] = "Tastenmodifikator für Fokus-Zauber."
    L["ActionbarTargetDriverSelfCast"] = "Selbstzauber"
    L["ActionbarTargetDriverSelfCastDesc"] = "Aktiviert das Wirken auf sich selbst."
    L["ActionbarTargetDriverSelfCastModifier"] = "Selbstzauber-Modifikator"
    L["ActionbarTargetDriverSelfCastModifierDesc"] = "Tastenmodifikator für Selbstzauber."
end

-- buttonTable
do
    L["ButtonTableActive"] = "Aktiviert"
    L["ButtonTableActiveDesc"] = "Aktiviert diese Aktionsleiste."
    L["ButtonTableButtons"] = "Anzahl der Tasten"
    L["ButtonTableButtonsDesc"] = "Anzahl der angezeigten Schaltflächen auf dieser Leiste."
    L["ButtonTableButtonScale"] = "Tastenskalierung"
    L["ButtonTableButtonScaleDesc"] = "Skalierung der Schaltflächen."
    L["ButtonTableOrientation"] = "Ausrichtung"
    L["ButtonTableOrientationDesc"] = "Horizontale oder vertikale Ausrichtung der Leiste."
    L["ButtonTableGrowthDirection"] = "Wachsrichtung"
    L["ButtonTableGrowthDirectionDesc"] = "Richtung, in die zusätzliche Tastenreihen wachsen."
    L["ButtonTableFlyoutDirection"] = "Flyout-Richtung"
    L["ButtonTableFlyoutDirectionDesc"] = "Richtung für das Ausklappmenü."
    L["ButtonTableReverseButtonOrder"] = "Tastenreihenfolge umkehren"
    L["ButtonTableReverseButtonOrderDesc"] = "Kehrt die Reihenfolge der Tasten um."
    L["ButtonTableNumRows"] = "Anzahl der Zeilen"
    L["ButtonTableNumRowsDesc"] = "Anzahl der Zeilen der Leiste."
    L["ButtonTableNumButtons"] = "Anzahl Tasten"
    L["ButtonTableNumButtonsDesc"] = "Legt fest, wie viele Tasten auf dieser Leiste angezeigt werden."
    L["ButtonTablePadding"] = "Abstand"
    L["ButtonTablePaddingDesc"] = "Abstand zwischen Tasten."
    L["ButtonTableStyle"] = "Stil"
    L["ButtonTableStyleDesc"] = ""
    L["ButtonTableAlwaysShowActionbar"] = "Aktionsleiste immer anzeigen"
    L["ButtonTableAlwaysShowActionbarDesc"] = "Hält die Aktionsleiste dauerhaft sichtbar."
    L["ButtonTableHideMacroText"] = "Makronamen ausblenden"
    L["ButtonTableHideMacroTextDesc"] = "Blendet Makronamen auf den Tasten aus."
    L["ButtonTableMacroNameFontSize"] = "Schriftgröße des Makronamens"
    L["ButtonTableMacroNameFontSizeDesc"] = "Schriftgröße für Makronamen."
    L["ButtonTableHideKeybindText"] = "Tastenbelegung ausblenden"
    L["ButtonTableHideKeybindTextDesc"] = "Blendet Hotkey-Texte auf den Tasten aus."
    L["ButtonTableShortenKeybindText"] = "Tastenbelegungs-Text kürzen"
    L["ButtonTableShortenKeybindTextDesc"] = "Kürzt Tastenbezeichnungen wie 'Mausrad' zu 'M', 'Umschalt' zu 's-' etc."
    L["ButtonTableKeybindFontSize"] = "Schriftgröße der Tastenbelegung"
    L["ButtonTableKeybindFontSizeDesc"] = "Schriftgröße für Hotkeys."
    L["MoreOptionsHideBarArt"] = "Leistengrafik ausblenden"
    L["MoreOptionsHideBarArtDesc"] = "Blendet die Hintergrundgrafik und Randverzierungen der Aktionsleisten aus."
    L["MoreOptionsHideBarScrolling"] = "Leistenwechsel-Pfeile ausblenden"
    L["MoreOptionsHideBarScrollingDesc"] = "Blendet die Pfeile zum Wechseln der Hauptaktionsleiste aus."
    L["MoreOptionsHideBorder"] = "Rahmen ausblenden"
    L["MoreOptionsHideBorderDesc"] = "Blendet den Rahmen um die Aktionsschaltflächen aus."
    L["MoreOptionsBorderFill"] = "Rahmenfüllung"
    L["MoreOptionsBorderFillDesc"] = "Dunkle Hintergrundfüllung innerhalb des Rahmens."
    L["MoreOptionsHideDivider"] = "Trennlinien ausblenden"
    L["MoreOptionsHideDividerDesc"] = "Blendet die dünnen Trennlinien zwischen Aktionsschaltflächen aus."
    L["MoreOptionsGryphons"] = "Greifen / Wyvern"
    L["MoreOptionsGryphonsDesc"] = "Verzierungen an den Enden der Hauptaktionsleiste."
    L["MoreOptionsUseKeyDown"] = ACTION_BUTTON_USE_KEY_DOWN or "Bei Tastendruck auslösen"
    L["MoreOptionsUseKeyDownDesc"] = OPTION_TOOLTIP_ACTION_BUTTON_USE_KEY_DOWN or "Löst Fähigkeiten bereits beim Herunterdrücken der Taste aus, nicht erst beim Loslassen."
    L["MoreOptionsIconRangeColor"] = "Reichweiten-Symbolfarbe"
    L["MoreOptionsIconRangeColorDesc"] = "Färbt das gesamte Symbol rot, wenn das Ziel außer Reichweite ist.\nFür Einstellungen siehe Kategorie 'Aktionsleisten-Reichweite'."
    L["ExtraOptionsPreset"] = "Vorlage"
    L["ExtraOptionsResetToDefaultPosition"] = "Auf Standardposition zurücksetzen"
    L["ExtraOptionsPresetDesc"] = "Setzt Skalierung, Anker und Koordinaten auf die Werte der ausgewählten Vorlage zurück, ändert aber keine anderen Einstellungen."
    L["ExtraOptionsModernLayout"] = "Modernes Layout (Standard)"
    L["ExtraOptionsModernLayoutDesc"] = ""
    L["ExtraOptionsClassicLayout"] = "Klassisches Layout (Seitenleiste)"
    L["ExtraOptionsClassicLayoutDesc"] = ""
end

-- Range
do
    L["ActionbarRangeName"] = "Aktionsleisten-Reichweite"
    L["ActionbarRangeNameDesc"] = ""
    L["ActionbarRangeHeader"] = "Reichweiteneinstellungen"
    L["ActionbarRangeHeaderDesc"] = ""
    L["ActionbarRangeHeaderHotkey"] = "Tastenbelegung"
    L["ActionbarRangeHeaderHotkeyDesc"] = ""
    L["ActionbarRangeHotkeyColor"] = "Normal"
    L["ActionbarRangeHotkeyColorDesc"] = "Schriftfarbe der Tastenbelegung bei normaler Reichweite."
    L["ActionbarRangeHotkeyOutOfRangeColor"] = "Außer Reichweite"
    L["ActionbarRangeHotkeyOutOfRangeColorDesc"] = "Schriftfarbe der Tastenbelegung, wenn das Ziel außer Reichweite ist."
    L["ActionbarRangeHeaderNotUsable"] = "Nicht benutzbar"
    L["ActionbarRangeHeaderNotUsableDesc"] = ""
    L["ActionbarRangeHeaderOutOfRange"] = "Außer Reichweite"
    L["ActionbarRangeHeaderOutOfRangeDesc"] = ""
    L["ActionbarRangeHeaderOutOfMana"] = "Zu wenig Mana"
    L["ActionbarRangeHeaderOutOfManaDesc"] = ""
end

-- XP
do
    L["XPOptionsName"] = "Erfahrungsleiste"
    L["XPOptionsDesc"] = "Optionen für die Erfahrungsleiste"
    L["XPOptionsStyle"] = L["ButtonTableStyle"]
    L["XPOptionsStyleDesc"] = ""
    L["XPOptionsWidth"] = "Breite"
    L["XPOptionsWidthDesc"] = "Breite der Erfahrungsleiste."
    L["XPOptionsHeight"] = "Höhe"
    L["XPOptionsHeightDesc"] = "Höhe der Erfahrungsleiste."
    L["XPOptionsAlwaysShowXPText"] = "Erfahrungstext dauerhaft anzeigen"
    L["XPOptionsAlwaysShowXPTextDesc"] = "Zeigt den Erfahrungstext dauerhaft auf der Leiste an."
    L["XPOptionsShowXPPercent"] = "Prozentwert anzeigen"
    L["XPOptionsShowXPPercentDesc"] = "Zeigt die Erfahrung in Prozent an."
end

-- rep
do
    L["RepOptionsName"] = "Rufleiste"
    L["RepOptionsDesc"] = "Optionen für die Rufleiste"
    L["RepOptionsStyle"] = L["ButtonTableStyle"]
    L["RepOptionsStyleDesc"] = ""
    L["RepOptionsWidth"] = "Breite"
    L["RepOptionsWidthDesc"] = "Breite der Rufleiste."
    L["RepOptionsHeight"] = "Höhe"
    L["RepOptionsHeightDesc"] = "Höhe der Rufleiste."
    L["RepOptionsAlwaysShowRepText"] = "Ruftext dauerhaft anzeigen"
    L["RepOptionsAlwaysShowRepTextDesc"] = "Zeigt den Ruf-Status dauerhaft auf der Leiste an."
end

-- Bags
do
    L["BagsOptionsName"] = "Taschen"
    L["BagsOptionsDesc"] = "Optionen für Taschen und Rucksack"
    L["BagsOptionsStyle"] = L["ButtonTableStyle"]
    L["BagsOptionsStyleDesc"] = ""
    L["BagsOptionsExpanded"] = "Ausgeklappt"
    L["BagsOptionsExpandedDesc"] = "Zeigt alle Taschenplätze ausgeklappt an."
    L["BagsOptionsHideArrow"] = "Pfeil ausblenden"
    L["BagsOptionsHideArrowDesc"] = "Blendet den Ausklapp-Pfeil der Taschenleiste aus."
    L["BagsOptionsHidden"] = "Ausgeblendet"
    L["BagsOptionsHiddenDesc"] = "Blendet die Taschenleiste aus."
    L["BagsOptionsOverrideBagAnchor"] = "Taschenfenster-Anker überschreiben"
    L["BagsOptionsOverrideBagAnchorDesc"] = "Überschreibt die Standardposition des geöffneten Taschenfensters."
    L["BagsOptionsOffsetX"] = "Taschenfenster X-Versatz"
    L["BagsOptionsOffsetXDesc"] = "Horizontaler Versatz des Taschenfensters."
    L["BagsOptionsOffsetY"] = "Taschenfenster Y-Versatz"
    L["BagsOptionsOffsetYDesc"] = "Vertikaler Versatz des Taschenfensters."
end

-- FPS
do
    L["FPSOptionsName"] = "FPS-Anzeige"
    L["FPSOptionsDesc"] = "Optionen für die Bildraten- und Latenzanzeige"
    L["FPSOptionsStyle"] = L["ButtonTableStyle"]
    L["FPSOptionsStyleDesc"] = ""
    L["FPSOptionsHideDefaultFPS"] = "Standard-FPS ausblenden"
    L["FPSOptionsHideDefaultFPSDesc"] = "Blendet den Standard-FPS-Text von WoW aus."
    L["FPSOptionsShowFPS"] = "FPS anzeigen"
    L["FPSOptionsShowFPSDesc"] = "Zeigt die aktuellen Bilder pro Sekunde an."
    L["FPSOptionsAlwaysShowFPS"] = "FPS dauerhaft anzeigen"
    L["FPSOptionsAlwaysShowFPSDesc"] = "Zeigt die FPS immer an."
    L["FPSOptionsShowPing"] = "Latenz anzeigen"
    L["FPSOptionsShowPingDesc"] = "Zeigt die aktuelle Serverlatenz in Millisekunden an."
end

-- Extra Action Button
do
    L["ExtraActionButtonOptionsName"] = "Zusatzaktions-Taste"
    L["ExtraActionButtonOptionsNameDesc"] = "Optionen für die Zusatzaktions-Taste"
    L["ExtraActionButtonStyle"] = "Stil"
    L["ExtraActionButtonStyleDesc"] = "Stil der Zusatzaktions-Taste"
    L["ExtraActionButtonHideBackgroundTexture"] = "Hintergrundtextur ausblenden"
    L["ExtraActionButtonHideBackgroundTextureDesc"] = "Blendet die Hintergrundgrafik der Zusatztaste aus."
end

-- Roll
do
    L["GroupLootContainerName"] = "Gruppenbeute-Fenster"
    L["GroupLootContainerDesc"] = "Optionen für das Beutewürfelfenster bei Gruppenbeute."
end

-- widget below
do
    L["WidgetBelowName"] = "Widget unter Minimap"
    L["WidgetBelowNameDesc"] = "Position des UI-Widgets unter der Minimap (z. B. Belagerungswagen, Eroberungsbalken)."
end

-- widget below
do
    L["VehicleLeaveButton"] = "Fahrzeug verlassen"
    L["VehicleLeaveButtonDesc"] = "Schaltfläche zum Verlassen von Fahrzeugen."
end

-- Buffs
do
    L["BuffsOptionsName"] = "Stärkungszauber"
    L["DebuffsOptionsName"] = "Schwächungszauber"
    L["BuffsOptionsStyle"] = L["ButtonTableStyle"]
end

-- asking about this page lives in the section's tooltip.
do
    L["BuffsOptionsStyleDesc"] = "|cffbbbbbbDie Spieloption |cffffffffStärkungszauber zusammenfassen|r|cffbbbbbb hat hier keine Wirkung. Sie wird nur vom Standard-Blizzard-Fenster gelesen, während DragonflightUI eigene Aurenleisten verwendet.|r"
    L["BuffsOptionsExpanded"] = "Ausgeklappt"
    L["BuffsOptionsExpandedDesc"] = ""
    L["BuffsOptionsUseStateHandler"] = "Status-Handler verwenden"
    L["BuffsOptionsUseStateHandlerDesc"] = "Ohne diese Option funktionieren die Sichtbarkeitseinstellungen nicht, kann aber die Kompatibilität mit anderen Addons verbessern (z. B. MinimapAlert)."
    L["BuffsAura"] = "Aura"
end

-- aura header
do
    L["BuffsHeaderAura"] = "Aura Header"
    L["BuffsHeaderAuraDesc"] = ""
    L["BuffsPaddingX"] = "Abstand X"
    L["BuffsPaddingXDesc"] = "Der X-Abstand zwischen Auren."
    L["BuffsPaddingY"] = "Abstand Y"
    L["BuffsPaddingYDesc"] = "Der Y-Abstand zwischen Aura-Reihen."
    L["BuffsWrapAfter"] = "Umbruch nach"
    L["BuffsWrapAfterDesc"] = "Beginnt eine neue Zeile nach dieser Anzahl an Auren.\nBei 0 wird nie umbrochen."
    L["BuffsMaxWraps"] = "Maximale Zeilen / Spalten"
    L["BuffsMaxWrapsDesc"] = "Begrenzt die Anzahl der Zeilen.\nBei 0 gibt es keine Begrenzung."
    L["BuffsSeperateOwn"] = "Eigene Auren abtrennen"
    L["BuffsSeperateOwnDesc"] = "Legt fest, ob selbst gewirkte Zauber davor (1) oder danach (-1) platziert werden sollen.\nBei (0) erfolgt keine Trennung."
    L["BuffsSortMethod"] = "Sortiermethode"
    L["BuffsSortMethodDesc"] = "Bestimmt, wie die Gruppe sortiert wird."
    L["BuffsSortDirection"] = "Sortierreihenfolge"
    L["BuffsSortDirectionDesc"] = "Bestimmt die Reihenfolge der Sortierung."
    L["BuffsPoint"] = "Ankerpunkt"
    L["BuffsPointDesc"] = ""
    L["BuffsOrientation"] = "Ausrichtung"
    L["BuffsOrientationDesc"] = "Horizontale Ausrichtung der Auren."
    L["BuffsGrowthDirection"] = "Wachsrichtung"
    L["BuffsGrowthDirectionDesc"] = "Vertikale Wachstumsrichtung der Zeilen."
    L["BuffsHeaderStylingAura"] = "Auren-Darstellung"
    L["BuffsHeaderStylingAuraDesc"] = ""
    L["BuffsHideDurationText"] = "Dauertext ausblenden"
    L["BuffsHideDurationTextDesc"] = "Blendet die Restzeitanzeige der Auren aus."
    L["BuffsHideCooldownSwipe"] = "Abklingzeit-Animation ausblenden"
    L["BuffsHideCooldownSwipeDesc"] = "Blendet die Kreis-Animation der Abklingzeit aus."
    L["BuffsHideCooldownDurationText"] = "Abklingzeit-Text ausblenden"
    L["BuffsHideCooldownDurationTextDesc"] = "Blendet den Zahlenwert der Abklingzeit aus."
end

-- Flyout
do
    L["FlyoutHeader"] = "Flyout-Leiste"
    L["FlyoutHeaderDesc"] = "Optionen für ausklappbare Zaubermenüs (z. B. Dämonenbeschwörung, Teleportation, Portale, Tierbegleiter)."
    L["FlyoutDirection"] = "Ausklapprichtung"
    L["FlyoutDirectionDesc"] = "Richtung, in die das Menü aufklappt."
    L["FlyoutSpells"] = "Zauber"
    L["FlyoutSpellsDesc"] = "Wählt aus, welche Zauber im Auswahlmenü erscheinen."
    L["FlyoutSpellsAlliance"] = "Allianz-Zauber"
    L["FlyoutSpellsAllianceDesc"] = "Zauber für Allianz-Charaktere."
    L["FlyoutSpellsHorde"] = "Horde-Zauber"
    L["FlyoutSpellsHordeDesc"] = "Nur auf Hordenseite aktiv."
    L["FlyoutItems"] = "Gegenstände"
    L["FlyoutItemsDesc"] = "Gegenstände in diesem Flyout."
    L["FlyoutCloseAfterClick"] = "Nach Klick schließen"
    L["FlyoutCloseAfterClickDesc"] = "Schließt das Flyout nach der Auswahl."
    L["FlyoutAlwaysShow"] = "Immer anzeigen"
    L["FlyoutAlwaysShowDesc"] = "Lässt das Ausklappmenü dauerhaft geöffnet."
    L["FlyoutIcon"] = "Symbol"
    L["FlyoutIconDesc"] = "Symbol für das Flyout."
    L["FlyoutDisplayname"] = "Anzeigename"
    L["FlyoutDisplaynameDesc"] = "Name des Flyout-Menüs."
    L["FlyoutTooltip"] = "Tooltip"
    L["FlyoutTooltipDesc"] = "Tooltips an Flyout-Tasten anzeigen."
    L["FlyoutInventoryCount"] = "Gegenstandsanzahl anzeigen"
    L["FlyoutInventoryCountDesc"] = "Zeigt die verbleibende Anzahl von Reagenzien auf der Taste an (z. B. Runen der Portale)."
    L["FlyoutButtonWarlock"] = "Dämonenbeschwörung"
    L["FlyoutButtonMagePort"] = "Teleportation"
    L["FlyoutButtonMagePortals"] = "Portale"
    L["FlyoutButtonMageFood"] = "Essen herbeizaubern"
    L["FlyoutButtonMageWater"] = "Wasser herbeizaubern"
    L["FlyoutWarlock"] = "Hexenmeister: Dämonen"
    L["FlyoutWarlockDesc"] = "Flyout für Hexenmeister-Begleiter."
    L["FlyoutMagePort"] = "Magier: Teleport"
    L["FlyoutMagePortDesc"] = "Flyout für Teleportzauber."
    L["FlyoutMagePortals"] = "Magier: Portale"
    L["FlyoutMagePortalsDesc"] = "Flyout für Portalzauber."
    L["FlyoutMageWater"] = "Magier: Wasser"
    L["FlyoutMageWaterDesc"] = "Flyout für Wasser herbeizaubern."
    L["FlyoutMageFood"] = "Magier: Essen"
    L["FlyoutMageFoodDesc"] = "Flyout für Essen herbeizaubern."
    L["FlyoutButtonCustomFormat"] = "Benutzerdefiniertes Flyout %d"
    L["FlyoutCustomNameFormat"] = "Flyout %d"
    L["FlyoutCustomNameDescFormat"] = "Optionen für Flyout %d"
    L["FlyoutHeaderClassPresets"] = "Klassen-Vorlagen"
    L["FlyoutHeaderClassPresetsDesc"] = "Vordefinierte Ausklappmenüs für Fähigkeiten deiner Klasse."
end

-- Castbar
do
    L["CastbarName"] = "Zauberleiste"
    L["CastbarNameFormat"] = "Zauberleiste (%s)"
    L["CastbarNamePlayer"] = "Spieler"
    L["CastbarNameTarget"] = "Ziel"
    L["CastbarNameFocus"] = "Fokus"
    L["CastbarTableActive"] = "Aktiviert"
    L["CastbarTableActivateDesc"] = "Aktiviert die moderne Zauberleiste."
    L["CastbarTableStyle"] = "Stil"
    L["CastbarTableStyleDesc"] = "Designstil der Zauberleiste."
    L["CastbarTableWidth"] = "Breite"
    L["CastbarTableWidthDesc"] = "Breite der Zauberleiste."
    L["CastbarTableHeight"] = "Höhe"
    L["CastbarTableHeightDesc"] = "Höhe der Zauberleiste."
    L["CastbarTablePrecisionTimeLeft"] = "Genauigkeit (Verbleibend)"
    L["CastbarTablePrecisionTimeLeftDesc"] = "Dezimalstellen für die verbleibende Zeit."
    L["CastbarTablePrecisionTimeMax"] = "Genauigkeit (Gesamtzeit)"
    L["CastbarTablePrecisionTimeMaxDesc"] = "Dezimalstellen für die maximale Zauberzeit."
    L["CastbarTableShowCastTimeText"] = "Zauberzeit anzeigen"
    L["CastbarTableShowCastTimeTextDesc"] = "Zeigt die verbleibende Zauberzeit als Zahl an."
    L["CastbarTableShowCastTimeMaxText"] = "Maximale Zauberzeit anzeigen"
    L["CastbarTableShowCastTimeMaxTextDesc"] = "Zeigt die Gesamtzauberzeit an (z. B. 1.5s / 3.0s)."
    L["CastbarTableCompactLayout"] = "Kompaktes Layout"
    L["CastbarTableCompactLayoutDesc"] = "Verwendet ein kompakteres Design für die Zauberleiste."
    L["CastbarTableHoldTimeSuccess"] = "Verweildauer bei Erfolg"
    L["CastbarTableHoldTimeSuccessDesc"] = "Dauer in Sekunden, die eine erfolgreich gewirkte Zauberleiste sichtbar bleibt."
    L["CastbarTableHoldTimeInterrupt"] = "Verweildauer bei Unterbrechung"
    L["CastbarTableHoldTimeInterruptDesc"] = "Dauer in Sekunden, die eine unterbrochene Zauberleiste sichtbar bleibt."
    L["CastbarTableShowIcon"] = "Symbol anzeigen"
    L["CastbarTableShowIconDesc"] = "Zeigt das Zaubersymbol an."
    L["CastbarTableIconSize"] = "Symbolgröße"
    L["CastbarTableIconSizeDesc"] = "Größe des Zaubersymbols."
    L["CastbarTableShowTicks"] = "Zauberticks anzeigen"
    L["CastbarTableShowTicksDesc"] = "Zeigt Markierungen für Ticks bei kanalisierten Zaubern."
    L["CastbarTableShowRank"] = "Zauberrang anzeigen"
    L["CastbarTableShowRankDesc"] = "Zeigt den Rang des Zaubers an."
    L["CastbarTableShowChannelName"] = "Kanalisierten Zaubernamen anzeigen"
    L["CastbarTableShowChannelNameDesc"] = "Zeigt den Namen bei kanalisierten Zaubern an."
    L["ExtraOptionsResetToDefaultStyle"] = "Auf Standardstil zurücksetzen"
    L["ExtraOptionsPresetStyleDesc"] = "Setzt Stil-Optionen auf eine Vorlage zurück."
    L["CastbarTableAutoAdjustHeader"] = "Automatische Positionierung"
    L["CastbarTableAutoAdjustHeaderDesc"] = "Passt die Position der Zauberleiste automatisch an Auren oder Leisten an."
    L["CastbarTableAutoAdjust"] = "Automatisch anpassen"
    L["CastbarTableAutoAdjustDesc"] = "Verschiebt die Zauberleiste bei sichtbaren Auren oder Fenstern automatisch."
end

-- local info = "\n\n" .. [[(Auto Adjust uses "SetPoint('TOPLEFT', parent, 'BOTTOMLEFT', dx, autoDy + dy)")]]
do
    L["CastbarTableAutoAdjustX"] = "Automatischer X-Versatz"
    L["CastbarTableAutoAdjustXDesc"] = ""
    L["CastbarTableAutoAdjustY"] = "Automatischer Y-Versatz"
    L["CastbarTableAutoAdjustYDesc"] = ""
end

-- mirror timer
do
    L["CastbarMirrorTimerName"] = "Spiegel-Timer"
    L["CastbarMirrorTimerNameDesc"] = "Optionen für Spiegeltimer (Atem, Erschöpfung)."
    L["CastbarMirrorHideBlizzard"] = "Blizzard-Spiegeltimer ausblenden"
    L["CastbarMirrorHideBlizzardDesc"] = "Blendet die Standard-Blizzard-Atemleiste aus."
end

-- Minimap
do
    L["MinimapName"] = "Minimap"
    L["MinimapStyle"] = L["ButtonTableStyle"]
    L["MinimapShowPing"] = "Ping anzeigen"
    L["MinimapNotYetImplemented"] = "*Noch nicht implementiert*"
    L["MinimapShowPingInChat"] = "Ping im Chat anzeigen"
    L["MinimapShape"] = "Form"
    L["MinimapShapeDesc"] = "Form der Minimap (Rund oder Eckig)."
    L["MinimapRotateDescAdditional"] = ""
    L["MinimapHideCalendar"] = "Kalender ausblenden"
    L["MinimapHideCalendarDesc"] = "Blendet die Kalenderschaltfläche an der Minimap aus."
    L["MinimapHideHeader"] = "Ausblenden"
    L["MinimapHideHeaderDesc"] = ""
    L["MinimapHideClock"] = "Uhr ausblenden"
    L["MinimapHideClockDesc"] = "Blendet die Zeitanzeige an der Minimap aus."
    L["MinimapHideZoneText"] = "Zonentext ausblenden"
    L["MinimapHideZoneTextDesc"] = "Blendet den Namen des aktuellen Gebiets über der Minimap aus."
    L["MinimapHideZoomButtons"] = "Zoom-Tasten ausblenden"
    L["MinimapHideZoomDesc"] = "Blendet die Lupentasten (+ / -) an der Minimap aus."
    L["MinimapSkinMinimapButtons"] = "Minimap-Symbole anpassen"
    L["MinimapSkinMinimapButtonsDesc"] = "Passt Addon-Symbole an der Minimap an den modernen Stil an."
    L["MinimapSkinMinimapHideButtons"] = "Minimap-Symbole ausblenden"
    L["MinimapSkinMinimapHideButtonsDesc"] = "Blendet Addon-Symbole an der Minimap aus."
    L["MinimapZonePanelPosition"] = "Zonentext-Position"
    L["MinimapZonePanelPositionDesc"] = "Position des Zonentext-Feldes."
    L["MinimapUseStateHandler"] = "Status-Handler verwenden"
    L["MinimapUseStateHandlerDesc"] = ""
    L["MinimapTrackerName"] = "Zielverfolgung"
    L["MinimapDurabilityName"] = "Haltbarkeit"
    L["MinimapLFGName"] = "Dungeonsuche"
end

-- UI
do
    L["UIUtility"] = "Nützliches"
    L["UIName"] = "Benutzeroberfläche"
    L["UIChangeBags"] = "Moderne Taschen"
    L["UIChangeBagsDesc"] = "Aktiviert den modernen Stil für Taschen."
    L["UIColoredInventoryItems"] = "Farbige Gegenstandsplätze"
    L["UIColoredInventoryItemsDesc"] = "Färbt Gegenstandsplätze im Charakterfenster anhand der Qualität ein."
    L["UIShowQuestlevel"] = "Questlevel anzeigen"
    L["UIShowQuestlevelDesc"] = "Zeigt die Stufe der Quest im Questlog an."
    L["UIFrames"] = "Fenster-Skins"
    L["UIFramesDesc"] = "Optionen für überarbeitete Benutzeroberflächen-Fenster."
    L["UIChangeCharacterFrame"] = "Modernes Charakterfenster"
    L["UIChangeCharacterFrameDesc"] = "Aktiviert das moderne Charakterfenster."
    L["UIChangeProfessionWindow"] = "Modernes Berufsfenster"
    L["UIChangeProfessionWindowDesc"] = "Aktiviert das moderne Berufsfenster."
    L["UIChangeInspectFrame"] = "Modernes Betrachtungsfenster"
    L["UIChangeInspectFrameDesc"] = "Aktiviert das moderne Fenster beim Betrachten anderer Spieler."
    L["UIChangeTrainerWindow"] = "Modernes Lehrerfenster"
    L["UIChangeTrainerWindowDesc"] = "Aktiviert das moderne Fenster für Klassen- und Berufsausbilder."
    L["UIChangeTalentFrame"] = "Modernes Talentfenster"
    L["UIChangeTalentFrameDesc"] = "Aktiviert das moderne Talentfenster."
    L["UIChangeSpellBook"] = "Modernes Zauberbuch"
    L["UIChangeSpellBookDesc"] = "Aktiviert das moderne Zauberbuch."
    L["UIChangeSpellBookProfessions"] = "Berufe im Zauberbuch"
    L["UIChangeSpellBookProfessionsDesc"] = "Zeigt Berufe im Zauberbuch im modernen Stil an."
end

-- Characterstatspanel
do
    L["CharacterStatsHitMeleeTooltipFormat"] = "Nahkampf-Trefferwertung: %s"
    L["CharacterStatsArp"] = "Rüstungsdurchschlag"
    L["CharacterStatsArpTooltipFormat"] = "Rüstungsdurchschlag: %s"
    L["CharacterStatsHitSpellTooltipFormat"] = "Zauber-Trefferwertung: %s"
    L["CharacterStatsSpellPen"] = "Zauberdurchschlag"
    L["CharacterStatsSpellPenTooltipFormat"] = "Zauberdurchschlag: %s"
end

-- ProfessionFrame
do
    L["ProfessionFrameHasSkillUp"] = "Gewährt Fertigkeitspunkt"
    L["ProfessionFrameHasMaterials"] = "Materialien vorhanden"
    L["ProfessionFrameSubclass"] = "Unterklasse"
    L["ProfessionFrameSlot"] = "Platz"
    L["ProfessionCheckAll"] = "Alle auswählen"
    L["ProfessionUnCheckAll"] = "Alle abwählen"
    L["ProfessionFavorites"] = "Favoriten"
    L["ProfessionExpansionFormat"] = "Erweiterung: %s"
end

-- Tooltip
do
    L["TooltipName"] = "Tooltip"
    L["TooltipAnchorName"] = "Tooltip-Position"
    L["TooltipHeaderGameToltip"] = "Standard-Tooltip"
    L["TooltipHeaderSpellTooltip"] = "Zauber-Tooltip"
    L["TooltipCursorAnchorHeader"] = "Mauszeiger-Positionierung"
    L["TooltipCursorAnchorHeaderDesc"] = ""
    L["TooltipAnchorToMouse"] = "Am Mauszeiger anheften"
    L["TooltipAnchorToMouseDesc"] = "Heftet den Tooltip an den Mauszeiger an."
    L["TooltipDefaultAnchorWhileCombat"] = "Standardposition im Kampf"
    L["TooltipDefaultAnchorWhileCombatDesc"] = "Verwendet im Kampf die Standardposition anstelle des Mauszeigers."
    L["TooltipMouseAnchor"] = "Maus-Ankerpunkt"
    L["TooltipMouseAnchorDesc"] = "Ankerpunkt des Tooltips an der Maus."
    L["TooltipMouseX"] = "Maus-Versatz X"
    L["TooltipMouseXDesc"] = "Horizontaler Versatz zum Mauszeiger."
    L["TooltipMouseY"] = "Maus-Versatz Y"
    L["TooltipMouseYDesc"] = "Vertikaler Versatz zum Mauszeiger."
end

-- spelltooltip
do
    L["TooltipAnchorSpells"] = "Zauber anheften"
    L["TooltipAnchorSpellsDesc"] = "Heftet Zauber-Tooltips an."
    L["TooltipShowSpellID"] = "Zauber-ID anzeigen"
    L["TooltipShowSpellIDDesc"] = "Zeigt die Spell-ID im Tooltip an."
    L["TooltipShowSpellSource"] = "Zauber-Quelle anzeigen"
    L["TooltipShowSpellSourceDesc"] = "Zeigt an, wer den Zauber gewirkt hat."
    L["TooltipShowSpellIcon"] = "Zaubersymbol anzeigen"
    L["TooltipShowSpellIconDesc"] = "Zeigt das Symbol des Zaubers im Tooltip."
    L["TooltipShowIconID"] = "Symbol-ID anzeigen"
    L["TooltipShowIconIDDesc"] = "Zeigt die ID des Symbols im Tooltip an."
    L["TooltipShowIcon"] = "Symbol anzeigen"
    L["TooltipShowIconDesc"] = "Zeigt das Symbol des Gegenstands oder Zaubers."
end

-- itemtooltip
do
    L["TooltipHeaderItemTooltip"] = "Gegenstands-Tooltip"
    L["TooltipHeaderItemTooltipDesc"] = ""
    L["TooltipShowItemQuality"] = "Qualitätsfarbe"
    L["TooltipShowItemQualityDesc"] = "Färbt den Text anhand der Gegenstandsqualität."
    L["TooltipShowItemQualityBackdrop"] = "Qualitäts-Hintergrundfarbe"
    L["TooltipShowItemQualityBackdropDesc"] = "Färbt den Hintergrund anhand der Gegenstandsqualität."
    L["TooltipShowItemStackCount"] = "Stapelgröße anzeigen"
    L["TooltipShowItemStackCountDesc"] = "Zeigt die maximale Stapelgröße des Gegenstands an."
    L["TooltipShowItemID"] = "Gegenstands-ID anzeigen"
    L["TooltipShowItemIDDesc"] = "Zeigt die Item-ID im Tooltip an."
end

-- backdrop
do
    L["TooltipBackdropHeader"] = "Hintergrund"
    L["TooltipBackdropHeaderDesc"] = ""
    L["TooltipBackdropColor"] = "Hintergrundfarbe"
    L["TooltipBackdropColorDesc"] = "Farbe des Tooltip-Hintergrunds."
    L["TooltipBackdropAlpha"] = "Hintergrund-Transparenz"
    L["TooltipBackdropAlphaDesc"] = "Transparenz des Tooltip-Hintergrunds."
    L["TooltipBackdropCustomTexture"] = "Eigene Hintergrundtextur"
    L["TooltipBackdropCustomTextureDesc"] = "Aktiviert eine benutzerdefinierte Hintergrundtextur."
end

-- border
do
    L["TooltipBorderName"] = "Rahmen"
    L["TooltipBorderNameDesc"] = ""
    L["TooltipBorderCustomTexture"] = "Eigene Rahmentextur"
    L["TooltipBorderCustomTextureDesc"] = "Aktiviert eine benutzerdefinierte Rahmentextur."
    L["TooltipBorderColor"] = "Rahmenfarbe"
    L["TooltipBorderColorDesc"] = "Farbe des Tooltip-Rahmens."
    L["TooltipBorderAlpha"] = "Rahmen-Transparenz"
    L["TooltipBorderAlphaDesc"] = "Transparenz des Tooltip-Rahmens."
    L["TooltipBorderInsetLeft"] = "Einrückung links"
    L["TooltipBorderInsetRight"] = "Einrückung rechts"
    L["TooltipBorderInsetTop"] = "Einrückung oben"
    L["TooltipBorderInsetBottom"] = "Einrückung unten"
    L["TooltipBorderInsetDesc"] = "Einrückung des Tooltip-Rahmens."
    L["TooltipBorderInsetEdgeSize"] = "Kantengröße"
    L["TooltipBorderInsetEdgeSizeDesc"] = "Größe der Kanten des Tooltip-Rahmens."
end

-- statusbar
do
    L["TooltipUnitHealthbarName"] = "Lebensleiste"
    L["TooltipUnitHealthbarNameDesc"] = ""
    L["TooltipUnitHealthbar"] = "Lebensleiste anzeigen"
    L["TooltipUnitHealthbarDesc"] = "Blendet eine Lebensleiste im Spieler-/NPC-Tooltip ein."
    L["TooltipUnitHealthbarHeight"] = "Höhe der Lebensleiste"
    L["TooltipUnitHealthbarHeightDesc"] = "Höhe der Lebensleiste im Tooltip."
    L["TooltipUnitHealthbarText"] = "Lebensleistentext"
    L["TooltipUnitHealthbarTextDesc"] = "Zeigt Text auf der Lebensleiste im Tooltip an."
end

-- unittooltip
do
    L["TooltipUnitTooltip"] = "Einheiten-Tooltip"
    L["TooltipUnitTooltipDesc"] = ""
    L["TooltipUnitClassBorder"] = "Klassenfarbener Rahmen"
    L["TooltipUnitClassBorderDesc"] = "Färbt den Tooltip-Rahmen in der Klassenfarbe des Spielers."
    L["TooltipUnitClassBackdrop"] = "Klassenfarbener Hintergrund"
    L["TooltipUnitClassBackdropDesc"] = "Färbt den Hintergrund anhand der Spielerklasse."
    L["TooltipUnitReactionBorder"] = "Reaktions-Rahmen"
    L["TooltipUnitReactionBorderDesc"] = "Färbt den Rahmen anhand der Gesinnung (Freund/Feind)."
    L["TooltipUnitReactionBackdrop"] = "Reaktions-Hintergrund"
    L["TooltipUnitReactionBackdropDesc"] = "Färbt den Hintergrund anhand der Gesinnung (Freund/Feind)."
    L["TooltipUnitClassName"] = "Klassenname anzeigen"
    L["TooltipUnitClassNameDesc"] = "Zeigt den Klassennamen der Einheit an."
    L["TooltipUnitTitle"] = "Titel anzeigen"
    L["TooltipUnitTitleDesc"] = "Zeigt den Titel des Spielers an."
    L["TooltipUnitRealm"] = "Servername anzeigen"
    L["TooltipUnitRealmDesc"] = "Zeigt den Servernamen des Spielers an."
    L["TooltipUnitGuild"] = "Gildennamen anzeigen"
    L["TooltipUnitGuildDesc"] = "Zeigt den Gildennamen des Spielers an."
    L["TooltipUnitGuildRank"] = "Gildenrang anzeigen"
    L["TooltipUnitGuildRankDesc"] = "Zeigt den Namen des Gildenrangs an."
    L["TooltipUnitGuildRankIndex"] = "Gildenrang-Index anzeigen"
    L["TooltipUnitGuildRankIndexDesc"] = "Zeigt den numerischen Index des Gildenrangs an."
    L["TooltipUnitGrayOutOnDeath"] = "Bei Tod ausgrauen"
    L["TooltipUnitGrayOutOnDeathDesc"] = "Graut den Tooltip aus, wenn die Einheit tot ist."
    L["TooltipUnitZone"] = "Zone/Gebiet anzeigen"
    L["TooltipUnitZoneDesc"] = "Zeigt das aktuelle Gebiet der Einheit an."
    L["TooltipUnitTarget"] = "Ziel der Einheit anzeigen"
    L["TooltipUnitTargetDesc"] = "Zeigt das aktuelle Ziel der Einheit im Tooltip an."
end

-- Unitframes
do
    L["UnitFramesName"] = "Einheitenfenster"
end

-- Player
do
    L["PlayerFrameName"] = "Spielerfenster"
    L["PlayerFrameDesc"] = "Optionen für das Spielerfenster"
    L["PlayerFrameStyle"] = L["ButtonTableStyle"]
    L["PlayerFrameClassColor"] = "Klassenfarbe"
    L["PlayerFrameClassColorDesc"] = "Färbt die Lebensleiste in der Klassenfarbe ein."
    L["PlayerFrameGradientColor"] = "Farbverlauf"
    L["PlayerFrameGradientColorDesc"] = "Verwendet einen sanften Farbverlauf für die Lebensleiste."
    L["PlayerFrameClassIcon"] = "Klassensymbol"
    L["PlayerFrameClassIconDesc"] = "Zeigt das Klassensymbol anstelle des 3D-Porträts an."
    L["PlayerFrameBreakUpLargeNumbers"] = "Große Zahlen formatieren"
    L["PlayerFrameBreakUpLargeNumbersDesc"] = "Formatiert große Zahlen mit Trennzeichen (z. B. 10.000 statt 10000)."
    L["PlayerFrameBiggerHealthbar"] = "Größere Lebensleiste"
    L["PlayerFrameBiggerHealthbarDesc"] = "Macht die Lebensleiste breiter und markanter."
    L["PlayerFramePortraitExtra"] = "Drachen-Symbol"
    L["PlayerFramePortraitExtraDesc"] = "Wählt das Drachensymbol am Porträt (Normal, Elite, Selten etc.)."
    L["PlayerFrameHideRedStatus"] = "Rotes Kampf-Leuchten ausblenden"
    L["PlayerFrameHideRedStatusDesc"] = "Blendet das rote Leuchten während des Kampfes aus."
    L["PlayerFrameHideHitIndicator"] = "Trefferanzeige ausblenden"
    L["PlayerFrameHideHitIndicatorDesc"] = "Blendet eingehende Kampfzahlen auf dem Porträt aus."
    L["PlayerFrameHideSecondaryRes"] = "Sekundäre Ressource ausblenden"
    L["PlayerFrameHideSecondaryResDesc"] = "Blendet sekundäre Ressourcen (z. B. Seelensplitter, Runen) aus."
    L["PlayerFrameHideAlternatePowerBar"] = "Druiden-Ersatzmanaleiste ausblenden"
    L["PlayerFrameHideAlternatePowerBarDesc"] = "Blendet die zusätzliche Manaleiste in Bären-/Katzengestalt aus."
    L["PlayerFrameHideRestingGlow"] = "Ausgeruht-Leuchten ausblenden"
    L["PlayerFrameHideRestingGlowDesc"] = "Blendet das Glühen beim Ausruhen (z. B. im Gasthaus) aus."
    L["PlayerFrameHideRestingIcon"] = "Ausgeruht-Symbol ausblenden"
    L["PlayerFrameHideRestingIconDesc"] = "Blendet das 'zzz'-Symbol beim Ausruhen aus."
    L["PlayerFrameHidePVP"] = "PvP-Symbol ausblenden"
    L["PlayerFrameHidePVPDesc"] = "Blendet das PvP-Fraktionssymbol aus."
    L["PlayerFrameCustomHealthbarTexture"] = "Eigene Lebensleistentextur"
    L["PlayerFrameCustomHealthbarTextureDesc"] = "Verwendet eine benutzerdefinierte Statusbalkentextur."
    L["PlayerFrameCustomPowerbarTexture"] = "Kraftleisten-Textur"
    L["PlayerFrameCustomPowerbarTextureDesc"] = "Wählt eine benutzerdefinierte Kraftleistentextur via LibSharedMedia."
end

-- Player Secondary< Res
do
    L["PlayerSecondaryResName"] = "Zusatzressourcen"
    L["PlayerSecondaryResNameDesc"] = ""
end

-- TotemFrame
do
    L["PlayerTotemFrameName"] = "Totemleiste des Spielers"
    L["PlayerTotemFrameNameDesc"] = ""
end

-- PowerBar_Alt
do
    L["PowerBarAltName"] = "Alternative Energieleiste"
    L["PowerBarAltNameDesc"] = "Optionen für alternative Energieleisten bei Bosskämpfen."
end

-- Target
do
    L["TargetFrameName"] = "Zielfenster"
    L["TargetFrameDesc"] = "Optionen für das Zielfenster"
    L["TargetFrameStyle"] = L["ButtonTableStyle"]
    L["TargetFrameClassColor"] = L["PlayerFrameClassColor"]
    L["TargetFrameClassColorDesc"] = L["PlayerFrameClassColorDesc"]
    L["TargetFrameReactionColor"] = "Reaktionsfarbe"
    L["TargetFrameReactionColorDesc"] = "Färbt die Lebensleiste anhand der Gesinnung (Freund/Feind)."
    L["TargetFrameClassIcon"] = L["PlayerFrameClassIcon"]
    L["TargetFrameClassIconDesc"] = L["PlayerFrameClassIconDesc"]
    L["TargetFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["TargetFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["TargetFrameNumericThreat"] = "Numerische Bedrohungsanzeige"
    L["TargetFrameNumericThreatDesc"] = "Zeigt die Bedrohung als Prozentzahl an."
    L["TargetFrameNumericThreatAnchor"] = "Position der Bedrohungsanzeige"
    L["TargetFrameNumericThreatAnchorDesc"] = "Legt die Position der numerischen Bedrohungsanzeige fest."
    L["TargetFrameThreatGlow"] = "Bedrohungs-Leuchten"
    L["TargetFrameThreatGlowDesc"] = "Aktiviert den Bedrohungs-Leuchteffekt bei Aggro."
    L["TargetFrameHideNameBackground"] = "Namenshintergrund ausblenden"
    L["TargetFrameHideNameBackgroundDesc"] = "Blendet die dunkle Leiste hinter dem Namen des Ziels aus."
    L["TargetFrameComboPointsOnPlayerFrame"] = "Combopunkte auf Spielerfenster"
    L["TargetFrameComboPointsOnPlayerFrameDesc"] = "Zeigt Combopunkte auf dem Spielerfenster statt auf dem Ziel an."
    L["TargetFrameHideComboPoints"] = "Combopunkte ausblenden"
    L["TargetFrameHideComboPointsDesc"] = "Blendet die Combopunkte-Anzeige komplett aus."
    L["TargetFrameFadeOut"] = "Ausblenden bei Entfernung"
    L["TargetFrameFadeOutDesc"] = "Blendet das Zielfenster ab, wenn das Ziel außer Reichweite ist."
    L["TargetFrameFadeOutDistance"] = "Ausblend-Distanz"
    L["TargetFrameFadeOutDistanceDesc"] = "Entfernung in Metern für den Ausblendeffekt."
    L["TargetFrameHeaderBuffs"] = "Stärkungs- & Schwächungszauber"
    L["TargetFrameAuraSizeSmall"] = "Kleine Auragröße"
    L["TargetFrameAuraSizeSmallDesc"] = "Größe fremder Auren bei dynamischer Auragröße."
    L["TargetFrameAuraSizeLarge"] = "Auragröße"
    L["TargetFrameAuraSizeLargeDesc"] = "Standardgröße der Auren am Zielfenster."
    L["TargetFrameNoDebuffFilter"] = "Alle Schwächungszauber anzeigen"
    L["TargetFrameNoDebuffFilterDesc"] = "Zeigt alle Schwächungszauber auf dem Ziel an, nicht nur eigene."
    L["TargetFrameDynamicBuffSize"] = "Dynamische Auragröße"
    L["TargetFrameDynamicBuffSizeDesc"] = "Hebt eigene Zauber auf dem Ziel durch eine größere Darstellung hervor."
    L["TargetFrameHeaderBuffsAdvanced"] = "Auren (Erweitert)"
    L["TargetFrameAuraOffsetY"] = "Auren Y-Abstand"
    L["TargetFrameAuraOffsetYDesc"] = "Vertikaler Abstand zwischen den Aurenreihen."
    L["TargetFrameAuraRowWidth"] = "Auren Zeilenbreite"
    L["TargetFrameAuraRowWidthDesc"] = "Maximale Breite einer Aurenzeile."
    L["TargetFrameAuraRowWidthToT"] = "Auren Zeilenbreite (ZdZ)"
    L["TargetFrameAuraRowWidthToTDesc"] = "Zeilenbreite für die ersten Zeilen, um Platz für das Ziel-des-Ziels-Fenster zu lassen."
    L["TargetFrameToTAuraRows"] = "Anzahl ZdZ-Aurenzeilen"
    L["TargetFrameToTAuraRowsDesc"] = "Anzahl an Zeilen mit reduzierter Breite für das Ziel des Ziels."
end

-- ToT
do
    L["TargetOfTargetFrameName"] = "Ziel des Ziels"
    L["TargetOfTargetFrameDesc"] = "Optionen für das Ziel des Ziels"
end

-- Pet
do
    L["PetFrameName"] = "Begleiterfenster"
    L["PetFrameDesc"] = "Optionen für das Begleiterfenster"
    L["PetFrameStyle"] = L["ButtonTableStyle"]
    L["PetFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["PetFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["PetFrameThreatGlow"] = L["TargetFrameThreatGlow"]
    L["PetFrameThreatGlowDesc"] = L["TargetFrameThreatGlowDesc"]
    L["PetFrameHideStatusbarText"] = "Statustext ausblenden"
    L["PetFrameHideStatusbarTextDesc"] = "Blendet Text auf der Lebens- und Manaleiste des Begleiters aus."
    L["PetFrameHideIndicator"] = "Trefferanzeige ausblenden"
    L["PetFrameHideIndicatorDesc"] = "Blendet Kampfzahlen auf dem Begleiterporträt aus."
    L["PetFrameHideDebuffs"] = "Schwächungszauber ausblenden"
    L["PetFrameHideDebuffsDesc"] = "Blendet Schwächungszauber des Begleiters aus."
end

-- Focus
do
    L["FocusFrameName"] = "Fokusfenster"
    L["FocusFrameToTName"] = "Fokus-Ziel des Ziels"
    L["FocusFrameDesc"] = "Optionen für das Fokusfenster"
    L["FocusFrameStyle"] = L["ButtonTableStyle"]
    L["FocusFrameClassColor"] = L["PlayerFrameClassColor"]
    L["FocusFrameClassColorDesc"] = "Aktiviert Klassenfarben für die Lebensleiste."
    L["FocusFrameClassIcon"] = L["PlayerFrameClassIcon"]
    L["FocusFrameClassIconDesc"] = "Aktiviert das Klassensymbol als Porträt für das Fokusfenster."
    L["FocusFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["FocusFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["FocusFrameHideNameBackground"] = L["TargetFrameHideNameBackground"]
    L["FocusFrameHideNameBackgroundDesc"] = "Blendet den Namenshintergrund aus."

    -- party
end

-- party
do
    L["PartyFrameName"] = "Gruppenfenster"
    L["PartyFrameDesc"] = "Optionen für die Gruppenfenster"
    L["PartyFrameStyle"] = L["ButtonTableStyle"]
    L["PartyFrameClassColor"] = L["PlayerFrameClassColor"]
    L["PartyFrameClassColorDesc"] = "Aktiviert Klassenfarben für Gruppen-Lebensleisten."
    L["PartyFrameBreakUpLargeNumbers"] = L["PlayerFrameBreakUpLargeNumbers"]
    L["PartyFrameBreakUpLargeNumbersDesc"] = L["PlayerFrameBreakUpLargeNumbersDesc"]
    L["PartyFrameDisableBuffTooltip"] = "Auren-Tooltips deaktivieren"
    L["PartyFrameDisableBuffTooltipDesc"] = "Deaktiviert Tooltips für Stärkungs- und Schwächungszauber an Gruppenfenstern."
end

-- raid
do
    L["RaidFrameName"] = "Schlachtzugsfenster"
end

-- Bosss
do
    L["BossFrameName"] = "Bossfenster"
    L["BossFrameNameDesc"] = "Optionen für Boss-Einheitenfenster"
end

-- Dropdowns
do
    L["DropdownBefore"] = "Davor"
    L["DropdownAfter"] = "Danach"
    L["DropdownNoSeperation"] = "Keine Trennung"
    L["DropdownSortIndex"] = "Index"
    L["DropdownSortName"] = "Name"
    L["DropdownSortTime"] = "Dauer"
    L["DropdownLeftToRight"] = "Von links nach rechts"
    L["DropdownRightToLeft"] = "Von rechts nach links"
    L["DropdownHorizontal"] = "Horizontal"
    L["DropdownVertical"] = "Vertikal"
    L["DropdownUp"] = "Nach oben"
    L["DropdownDown"] = "Nach unten"
    L["DropdownLeft"] = "Nach links"
    L["DropdownRight"] = "Nach rechts"
end

do
    local KEY_REPLACEMENTS = {
        ["ALT"] = "A",
        ["CTRL"] = "C",
        ["SHIFT"] = "S",
        ["BACKSPACE"] = "BS",
        ["CAPSLOCK"] = "CP",
        ["CLEAR"] = "CL",
        ["DELETE"] = "Entf",
        ["END"] = "Ende",
        ["HOME"] = "Pos1",
        ["INSERT"] = "Einfg",
        ["MOUSEWHEELDOWN"] = "WD",
        ["MOUSEWHEELUP"] = "WU",
        ["NUMLOCK"] = "NL",
        ["PAGEDOWN"] = "BildRunter",
        ["PAGEUP"] = "BildHoch",
        ["SCROLLLOCK"] = "SL",
        ["SPACEBAR"] = "Leertaste",
        ["SPACE"] = "Leertaste",
        ["TAB"] = "Tab",
        ["DOWNARROW"] = "Runter",
        ["LEFTARROW"] = "Links",
        ["RIGHTARROW"] = "Rechts",
        ["UPARROW"] = "Hoch"
    }

    local NUM_MOUSE_BUTTONS = 31
    for i = 1, NUM_MOUSE_BUTTONS do KEY_REPLACEMENTS["BUTTON" .. i] = "B" .. i end

    for k, v in pairs(KEY_REPLACEMENTS) do L[k] = v; end
    DF.KEY_REPLACEMENTS = KEY_REPLACEMENTS;
end

-- see comment above
for k, v in pairs(L) do L_DE[k] = v; end

