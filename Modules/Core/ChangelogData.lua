local addonName, addonTable = ...;
local DF = LibStub('AceAddon-3.0'):GetAddon('DragonflightUI')

-- The release notes shown by the What's New window, mirroring CHANGELOG.md.
--
-- Kept as data rather than parsed from the file at runtime, because an addon
-- cannot read its own files. When CHANGELOG.md gains an entry, add it here too;
-- the top entry is the one a player sees after updating.
--
-- `version` must match X-DFUI-Version in the TOC for the release it describes.
-- That is what decides whether the window opens by itself.
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
                    'Vanilla gave shamans the paladin\'s pink, to the third decimal - the game\'s own colour file puts both at 0.96, 0.55, 0.73. It was never ambiguous at the time, because shamans were Horde and paladins Alliance and the two could never see each other. On Era they are still identical, which now reads as a bug.',
                    'Settings > Misc > Utility > Class Colors > Blue Shamans draws them in the blue TBC gave them, everywhere DragonflightUI colours by class - unit frames, tooltips, loot rolls, the friends list.',
                    'Off by default, and greyed out with an explanation on any client whose shamans already have a colour of their own.',
                    'Nameplates and the default chat are coloured by the game rather than by us, so those stay pink. If you run a class colour addon, this setting steps aside and lets it decide.'
                }
            }, {
                title = 'The target frame lights up in combat',
                items = {
                    'The in-combat glow traces the frame now instead of sitting near it: it is built from the frame\'s own art at the same cut and size, so it follows the outline exactly, including the bulge around the portrait.',
                    'The red ring replaces the gold one rather than hiding behind it.',
                    'Each frame keeps its own glow - the target, the focus, every boss frame and the edit mode preview no longer borrow the first one\'s position and shape.'
                }
            }, {
                title = 'Action bars',
                items = {
                    'Fixed being unable to place or move spells on a bar with Always show action bar turned off. The drag grid appeared and was taken away again in the same breath, so there was nothing to drop onto. TBC only, which is what made it hard to pin down.',
                    'Fixed a stack count left behind on the slot an item was dragged out of - "80 charges" still showing on an empty button.',
                    'Fixed the green equipped border staying on a trinket after you took it off. Swapping two trinkets left both looking equipped.',
                    'Fixed a renamed macro keeping its old name on the button.',
                    'Scrolling the main bar skips bars that are already on screen again, the way the game intends. It had started cycling all six pages, which laid a second copy of a bar you could already see over the one you were using. Hide a bar and its page returns to the cycle by itself.',
                    'The Paging setting now says outright that Smart differs from Default only for druids - on every other class the two are identical.'
                }
            }, {
                title = 'Unit frames',
                items = {
                    'Fixed an invisible frame that swallowed clicks where the target, target-of-target, pet and focus frames sit. Opening edit mode once - changing nothing - left their holders on screen and taking mouse input, so right-drag to turn the camera stopped working anywhere near them until a reload.',
                    'Fixed party frame settings not applying. Health and power bar changes, Class Color included, only appeared when somebody joined or left the group.',
                    'Fixed party members vanishing the moment a fight started and coming back when it ended.',
                    'The XP bar text is centred on the bar again. It never quite was, but rested XP makes the line long enough to notice it drifting right.'
                }
            }, {
                title = 'Edit mode',
                items = {
                    'The placeholder drawn for a frame with nothing to show keeps that frame\'s shape now. A stance bar stacked into a column was being handed a box five times wider than the bar it stood for.'
                }
            }, {
                title = 'Elsewhere',
                items = {
                    'Fixed guild and community list avatars silently failing to load. Nobody reported this one - it turned up in a log sent in for something else.',
                    'Fixed a blank gap where an out-of-range or offline player\'s name should be in the tooltip.',
                    'Aimed Shot gets a cast bar. The client does not report it the way it reports every other cast, so it is filled in from the cast being sent.'
                }
            }, {
                title = 'For bug reports',
                items = {
                    '/df log blockers lists everything taking mouse input over a spot - for "something invisible here is eating my clicks", which hovering cannot answer.',
                    '/df log tot reports every condition the game uses to decide whether the target-of-target frame should be visible, and says which one is failing.',
                    'A keybinding under DragonflightUI > Debug captures whatever is under the cursor, and a window opens to copy any of it out of for pasting into a report.',
                    'Repeated log lines are counted rather than repeated, so one noisy problem no longer buries everything else.',
                    'Builds installed from source now report their version with -dev on the end, so a checkout of main can be told apart from a packaged release.'
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
