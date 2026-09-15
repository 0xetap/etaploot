# EtapLoot

EtapLoot is a customizable loot display for World of Warcraft: Midnight. 

It keeps the rewards you receive in a compact on-screen window, where they remain easy to review without opening your bags or searching through chat. The addon was developed out of (my own, personal) belief that chat is for communication and has nothing to do with items, loot, currencies, and so on - so loot must go somewhere else.

## Installation

1. Close World of Warcraft.
2. Place the complete `EtapLoot` folder in:
   `World of Warcraft/_retail_/Interface/AddOns/`
3. Start the game and enable EtapLoot in the AddOns list if necessary.

EtapLoot is made for World of Warcraft: Midnight. Maybe it works for the various iterations of Classic or the upcoming Forever - but it's untested.

## Getting started

Left-click the EtapLoot minimap button to open the settings. Right-click it to show or hide the loot window. Middle-click to lock and unlock the loot window.

You can also use:

- `/el` - show or hide the loot window
- `/el config` - open the settings
- `/el clear` - clear the Personal or Group tab currently being viewed

## Using the loot window

The **Personal** tab shows rewards received by your active profile. The **Group** tab shows items received by other players in your party or raid.

- Hover an entry for its tooltip.
- Left-click a Group entry to open a quick Whisper button for easy trading.
- Shift-click an item while chat is open to insert its link.
- **Clear** erases only the tab currently being viewed.

Unlock the window in the settings to move or resize it. Its corner handle changes the width and number of visible rows. Auto-collapse can shrink inactive Personal and Group windows; hovering restores their rows temporarily.

## Profiles

EtapLoot creates a profile for each character. Profiles keep their own settings and Personal and Group histories. The Profiles page lets you activate another profile, copy its settings, or restore default settings.

## If loot does not appear

Open `/el config` and check:

- **Enable loot tracking** is selected.
- The relevant looted- or crafted-item option is selected.
- Item-quality and equippable-item filters are not excluding the entry.
- You are viewing the correct Personal or Group tab.