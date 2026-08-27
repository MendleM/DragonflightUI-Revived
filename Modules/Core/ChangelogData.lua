local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The release notes shown by the What's New window, mirroring CHANGELOG.md.
--
-- Kept as data rather than parsed from the file at runtime, because an addon
-- cannot read its own files. When CHANGELOG.md gains an entry, add it here too;
-- the top entry is the one a player sees after updating.
--
-- The top entry's `version` is what decides whether the window opens by itself:
-- adding notes is what makes them appear. Keep it matching the TOC's Version
-- anyway - they describe the same release - and a mismatch is written to the
-- debug log at login, readable with /df log version before packaging.
--
-- Keep the bullets to a line each. These are read in a window in the middle of
-- a game, not a post-mortem: what changed, not why it broke.
--
-- Versions are plain x.y.z and nothing else. The earlier "0.41.0-revived1" and
-- "Revived 2" tried to make the version carry the fact that the project has new
-- maintainers, which it announced once and then repeated forever, and left the
-- number unable to say the only thing a version is for: which build is newer.
-- The `title` is where a release gets a name, and it should describe the
-- release rather than number it - "Revived" was the launch, "Revived 2" was
-- just the one after it.
DF.ChangelogData = {
    {
        version = '0.44.0',
        title = 'The Definitive Refactor & Stability Overhaul',
        date = '26 August 2026',
        intro = 'Complete stability overhaul: permanent decoupling from Blizzard Edit Mode, combat reload visual preservation, robust TBC totem positioning, solid ChatFrame anchoring, and instant live Darkmode switching.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Decoupled from Blizzard EditMode & LibEditModeOverride: No more taint or frame interference.',
                    'Seamless combat reloads: Holder pre-positioning and immediate visual skinning prevent visual snapping.',
                    'Chat frame fix: Anchored permanently on TBC and Era without disappearing or resetting on reload.',
                    'Totem bar fix: Dynamic capability detection and anchored positioning for Shamans.',
                    'Darkmode toggle: Switch on and off live with zero reloads required.',
                    'Action bar dividers: Fixed logic so dividers only appear on the main bar frame with border art.'
                }
            }, {
                title = 'Core & Architecture',
                items = {
                    'Decoupled EditMode completely from LibEditModeOverride and permanently blocked Blizzard EditMode if DF UI is active.',
                    'Streamlined Version.API.lua with universal expansion detection (Era, TBC, Wrath, Cata, MoP) and capability mirroring.',
                    'Removed on-screen combat reload warning banner to keep UI clean during reloads.',
                    'Reduced post-combat reapply delay to 100ms for faster responsiveness.'
                }
            }, {
                title = 'Chat',
                items = {
                    'TBC: the chat window keeps its position through loading screens and reloads without disappearing.',
                    'All versions: decoupled ChatFrame1 from Blizzard EditModeManager and legacy position manager so position is preserved through window resizing and scaling.'
                }
            }, {
                title = 'Unit frames & Totems',
                items = {
                    'Shaman TotemFrame: added dynamic HasTotemBar capability detection and hooked positioning to keep active totems attached to DragonflightUI.',
                    'Added early holder pre-positioning and immediate visual skinning in combat reloads.',
                    'Pet frame anchoring: fixed position jumping on pet summon by locking PetFrame to DragonflightUIPetFrame.',
                    'Focus target is visible on TBC and MoP.',
                    'Era: faction icon sits on target frame properly.',
                    'No more error when reloading during combat from target-of-target not being built yet.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Pet bar sizing: standardized default button scale to 0.8 (36px) and centered icons at 45x45 base, resolving undersized buttons (Issue #13).',
                    'Action bar & Pet bar taint: neutralized Blizzard SetShown/UpdateShownButtons on background bars to eliminate ADDON BLOCKED errors on spellbook open and pet casts.',
                    'Pet bar clickability: disabled mouse interception on Blizzard container frames and fixed secure templates so pet buttons are clickable on login.',
                    'Bar dividers: restricted dividers strictly to Action Bar 1 with active border art, preventing stray divider lines across Action Bars 2-8.',
                    'Eliminated legacy Blizzard gryphon textures and duplicate visual elements on TBC.',
                    'Fixed Action Bar 1 scaling and in-combat alignment for backpack and bag bars.',
                    'Flyout Direction: choosing Up works properly.',
                    'MoP: the latency indicator sits on the bottom edge of the game menu button instead of in the middle of it.',
                    'Keyring (Cata & MoP): suppressed phantom keyring button on Cataclysm and MoP while maintaining full visibility on Classic Era, TBC, and Wrath.',
                    'MoP Bag Counter: fixed free bag slots counter positioning and text size inside the backpack button.'
                }
            }, {
                title = 'Professions',
                items = {
                    'Beast Training: restored Beast Training (Wildtierausbildung) and CraftFrame support for Hunter pets in Classic Era, Season of Discovery, and TBC with spellbook tab scanning, training points counter, and legacy craft frame suppression.',
                    'MoP & Cataclysm Crash Fix: included LibTradeSkillRecipes in MoP and Cata TOC files and hardened mixins to prevent startup errors and restore the Dragonflight UI profession window.'
                }
            }, {
                title = 'Dark Mode',
                items = {
                    'Live toggle: Darkmode can now be turned on and off live without requiring a /reload.',
                    'Dynamic state retrieval across unitframe hooks, actionbar buttons, and flyouts to cleanly restore original colors and saturation.'
                }
            }, {
                title = 'Nameplates',
                items = {
                    'Fixed an error that could repeat hundreds of times in a session, from asking a nameplate for its parent when it was not a frame at all. Reported with Plater.'
                }
            }
        }
    }, {
        version = '0.43.0',
        title = 'Party frames and professions',
        date = '13 August 2026',
        intro = 'Party frames stay put in combat, the profession window behaves, and TBC starts up again.',
        sections = {
            {
                title = 'Highlights',
                items = {
                    'Party frames survive combat.',
                    'One profession window, and you can move it.',
                    'TBC: fixed a crash on startup.',
                    'Hide Clock finally sticks.'
                }
            }, {
                title = 'Party frames',
                items = {
                    'Members no longer vanish, or collapse to a single member, when combat starts. This addon was applying Blizzard\'s edit mode layout at login, which tainted the party frames for the rest of the session.'
                }
            }, {
                title = 'Profession window',
                items = {
                    'Tradeskills open one window instead of two. Blizzard\'s was left sitting behind ours unless you happened to have BlizzMove installed. Enchanting still shows Blizzard\'s craft window, because the Enchant button lives on it.',
                    'Drag it by its header, and it stays where you put it.',
                    'No more empty profession window at every login.',
                    'The profession icon fills its ring instead of sitting inside a border.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'New setting: Disable Blizzard\'s Edit Mode, on by default. Saving in Blizzard\'s writes its whole layout over this one, so the game\'s own ways in are switched off.',
                    'Rotate Minimap survives a reload - it was written somewhere the game overwrites on every layout.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Stopped tainting the target frame\'s debuff buttons, a long-standing source of blocked actions.',
                    'TBC: fixed a flood of Invalid frame handle errors during combat.'
                }
            }, {
                title = 'Minimap',
                items = {'Hide Clock stays hidden after a reload or relog.'}
            }, {
                title = 'Castbar',
                items = {'TBC: fixed an error on startup when the target frame had not been placed yet.'}
            }, {
                title = 'Character pane',
                items = {
                    'Tab labels are vertically centred again, in both the selected and unselected tab.',
                    'The pane was building itself out of the game\'s script budget and getting cut off partway, leaving it half-made.'
                }
            }, {
                title = 'Action bars',
                items = {'The keyring stays on the end of the bag bar instead of wandering in among the bags.'}
            }, {
                title = 'Tooltips',
                items = {'Fixed the tooltip body flickering on and off while you hover it.'}
            }, {
                title = 'Under the hood',
                items = {
                    'Removed leftover debug messages that printed to chat.',
                    'The addon no longer writes a performance log to your SavedVariables every session.'
                }
            }
        }
    }, {
        version = '0.42.0',
        title = 'Fixes from the field',
        date = '30 July 2026',
        intro = 'Everything reported since the last CurseForge build, fixed.',
        sections = {
            {
                title = 'Loot rolls',
                items = {
                    'Hovering Need, Greed or Pass names who chose it again.',
                    'The count is back on each button; an empty Pass reads 0.',
                    'The line under the item name shows how many have yet to answer, then the winner - it no longer repeats those numbers.',
                    'The settings preview shows a live roll, tooltips included.'
                }
            }, {
                title = 'Request Stop button',
                items = {
                    'Sits above the top action bar, flush left, at button size, with the same frame as every other button.',
                    'Glows while it can actually be clicked - it had no usable-or-not look at all.',
                    'Can be turned off, and previewed from the settings without catching a flight.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Scrolling bar 1 no longer cycles through bars already on screen. This only ever worked on TBC.',
                    'The page number no longer sits offset on the first render.',
                    'Pet Bar works as an anchor - it pointed at a frame that does not exist.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Fixed a burst of Lua errors at login, from the player, target, pet and secondary resource frames.',
                    'Health and mana numbers show on party frames with Status Text on.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'Use Raid-Style Party Frames works again, and stays put after a reload or a dungeon.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'Fixed an error at login with Clique, which was also costing Clique its party frame mouse handling.',
                    'The buff settings page says plainly that the game\'s Consolidate Buffs option cannot reach our buff frame.',
                    'The Discord button opens this project\'s server, not the original author\'s.'
                }
            }, {
                title = 'For bug reports',
                items = {
                    'The version number is real - reports no longer read @project-version@.',
                    'New /df log watch: run it, reproduce the problem, run it again. It reports what moved and opens a window to copy.'
                }
            }
        }
    }, {
        version = '0.41.2',
        title = 'Bug reports, answered',
        date = '27 July 2026',
        intro = 'A week of bug reports from the Discord, answered.',
        sections = {
            {
                title = 'Blue shamans',
                new = true,
                items = {
                    'New setting under Misc > Utility > Class Colors. Era gives shamans the paladin\'s pink; this makes them TBC\'s blue.',
                    'Off by default. Nameplates and default chat stay pink - the game colours those, not us.'
                }
            }, {
                title = 'Target frame combat glow',
                items = {
                    'The glow traces the frame now instead of sitting beside it, and turns the ring red rather than hiding behind it.',
                    'Target, focus, boss frames and the edit mode preview each get their own.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Fixed placing and moving spells with Always show action bar off (TBC).',
                    'Fixed stack counts left behind on a slot you dragged an item out of.',
                    'Fixed the green equipped border staying on a trinket after you unequip it.',
                    'Fixed a renamed macro keeping its old name.',
                    'Scrolling the main bar skips bars already on screen again.',
                    'Paging: Smart only differs from Default on druids, and now says so.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Fixed an invisible frame eating clicks around the target, target-of-target, pet and focus frames after opening edit mode.',
                    'Fixed party frame settings only applying when someone joined or left the group.',
                    'Fixed party members vanishing when combat started.',
                    'XP bar text is centred again when rested XP is showing.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'The Empty placeholder keeps the frame\'s shape - no more oversized box over a narrow bar.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'Fixed guild and community list avatars not loading.',
                    'Fixed the blank gap where an out-of-range player\'s name goes in tooltips.',
                    'Aimed Shot shows a cast bar.'
                }
            }, {
                title = 'For bug reports',
                items = {
                    '/df log blockers - what is taking mouse input at a spot.',
                    '/df log tot - why the target-of-target frame is hidden.',
                    'Keybinding under DragonflightUI > Debug captures whatever is under the cursor, with a window to copy it out of.',
                    'Repeated log lines are counted, not repeated.'
                }
            }
        }
    }, {
        version = '0.41.1',
        title = 'Revived',
        date = '26 July 2026',
        intro = 'The community-maintained continuation of DragonflightUI Classic, picking up where the original left off.',
        sections = {
            {
                title = 'Undo and redo in edit mode',
                new = true,
                items = {
                    'Ctrl+Z (Cmd+Z on a Mac) undoes, Ctrl+Y or Ctrl+Shift+Z redoes, while the edit mode panel is open.',
                    'Covers everything you change there - dragging a frame, a slider, a dropdown - and a small note names what it just put back.',
                    'The history lasts for as long as edit mode is open.'
                }
            }, {
                title = 'Bars that stand on their own',
                new = true,
                items = {
                    'New Stand On Its Own checkbox at the top of each bar\'s Position settings.',
                    'On, it moves alone. Off, it goes back to moving with the frames it was attached to.',
                    'Neither switch moves anything on screen - things stay where they are, they just stop travelling together.',
                    'By default the main action bar is stuck to the reputation bar, which is stuck to the XP bar, so dragging the XP bar dragged all three. Tick it on the XP bar and it moves alone.'
                }
            }, {
                title = 'Movable windows',
                new = true,
                items = {
                    'The character pane, trade window, inspect, quest log, spellbook and talent window can be dragged by their title bar, and stay where you put them.',
                    'Settings > Misc > Movable Windows, with a Reset button that hands every window back to the game.',
                    'Windows you never move are left exactly where the game puts them. Moving one is also what lets it stay open alongside the others, so the character pane and trade window can finally sit side by side.'
                }
            }, {
                title = 'Errors and combat blocks',
                items = {
                    'Fixed the "Invalid frame handle" error thrown every time you entered combat. It also meant frames meant to fade in combat silently never did.',
                    'Fixed the error when casting certain spells, and when using a consumable in combat.',
                    'Fixed "action blocked" spam when hovering or clicking your action bars mid-fight.',
                    'Fixed the stutter caused by #showtooltip [@mouseover] macros.'
                }
            }, {
                title = 'Action bars vanishing',
                items = {
                    'Fixed every bar disappearing after anchoring the XP bar to an action bar.',
                    'An anchor choice that would form a loop is now refused politely, instead of erroring on every settings change.',
                    'MoP: fixed having no action bars at all while the options still showed them as on.',
                    'MoP: fixed an error on every drag in edit mode.',
                    'MoP: fixed the focus target frame being resized unexpectedly.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'Fixed the unit frames being shoved around when you open Blizzard\'s own Edit Mode.',
                    'Fixed frames disappearing when you left edit mode and only returning after a reload.',
                    'Frames with nothing to show get a labelled placeholder you can actually grab.',
                    'Frames can be dragged straight away instead of needing a click to select first, with live coordinates while you drag.',
                    'Only one edit mode open at a time - opening Blizzard\'s closes ours, and the other way round.'
                }
            }, {
                title = 'Party frames',
                items = {
                    'Class colour and gradient options work on the new party frames.',
                    'Health bars no longer stuck washed-out, and correct power bar art.',
                    'Names truncate before the role icon and stay on one line.',
                    'Party frames have their own settings page, edit mode entry and move handle.'
                }
            }, {
                title = 'Loot rolls',
                items = {
                    'Rebuilt on retail\'s actual loot roll frame, with retail need, greed and pass icons.',
                    'Preview button and real customization options in settings.',
                    'Adjustable gap between stacked rolls.'
                }
            }, {
                title = 'Chat',
                items = {
                    'The chat window can be selected and moved in DragonflightUI\'s edit mode.',
                    'Fixed tabs past the first rendering shifted upward when chat sits at the bottom of the screen.',
                    'An undocked tab can no longer be dragged off the screen and lost.',
                    'The combat log\'s filter bar no longer covers your other chat tabs.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'The Dragonflight paperdoll artwork shows only on the Character tab, instead of bleeding onto Reputation, Skills and Pet.',
                    'Turned-off features are marked (off) and can be switched back on from their own page.',
                    'The quest tracker can be disabled without disabling the whole Minimap module.',
                    'Bug reports show a real version number.',
                    'New /df log debug log, so bug reports can carry a real log.'
                }
            }
        }
    }, {
        version = '0.41.0',
        title = 'Classic Era 1.15.9 support',
        date = '22-25 July 2026',
        intro = 'Patch 1.15.9 replaced the Classic Era interface with a backport of the modern one, which broke most of the addon. This is the overhaul for it, and adds TBC 2.5.6 and MoP 5.5.4 support.',
        sections = {
            {
                title = 'Loading and stability',
                items = {
                    'The addon no longer half-loads and gives up partway through login.',
                    'The interface no longer visibly builds itself piece by piece after you log in.',
                    'Reloading mid-fight finishes the job the moment combat ends.',
                    'Fixed the quest tracker freezing the game.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Page arrows work again, cycle all 6 pages, and keep working in combat.',
                    'Shift-scrolling to change pages no longer strobes between two pages.',
                    'Keybinds on bars 6-8 fired nothing; bars 6-8 showed every spell twice.',
                    'Bar backgrounds were missing entirely.',
                    'Added the retail main bar frame, with an adjustable fill behind the buttons.',
                    'Pet bar restored to its proper size, with correct highlight and autocast art.'
                }
            }, {
                title = 'Raid and hover performance',
                items = {
                    'Fixed the big one: frame skips and stutter when moving the mouse across raid frames.',
                    'Buff timers no longer churn the garbage collector every frame.',
                    'Keeps Questie\'s raid safeguards working when the client cuts its startup short.'
                }
            }, {
                title = 'Nameplates',
                new = true,
                items = {'Dragonflight-styled enemy plates, outlined names and class-coloured enemy players.'}
            }, {
                title = 'Frames and art',
                items = {
                    'Full Dragonflight restyle for the new pooled party frames.',
                    'Retail Dragonflight character pane background, slot art and model border.',
                    'Pet buffs and pet happiness restored.',
                    'Buff and debuff timers keep their real remaining time across a reload.',
                    'Minimap sits in the corner at a sane default size.'
                }
            }
        }
    }
}
