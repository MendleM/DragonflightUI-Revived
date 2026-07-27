local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The release notes shown by the What's New window, mirroring CHANGELOG.md.
--
-- Kept as data rather than parsed from the file at runtime, because an addon
-- cannot read its own files. When CHANGELOG.md gains an entry, add it here too;
-- the top entry is the one a player sees after updating.
--
-- The top entry's `version` is what decides whether the window opens by itself:
-- adding notes is what makes them appear. Keep it matching X-DFUI-Version in
-- the TOC anyway - they describe the same release - and a mismatch is written
-- to the debug log at login, readable with /df log version before tagging.
--
-- Keep the bullets to a line each. These are read in a window in the middle of
-- a game, not a post-mortem: what changed, not why it broke.
DF.ChangelogData = {
    {
        version = '0.41.0-revived2',
        title = 'Revived 2',
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
                    'Repeated log lines are counted, not repeated.',
                    'Source builds report -dev, so they are not mistaken for a release.'
                }
            }
        }
    }, {
        version = '0.41.0-revived1',
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
