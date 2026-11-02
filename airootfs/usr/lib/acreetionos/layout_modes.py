#!/usr/bin/python3
"""AcreetionOS desktop layout modes.

Cinnamon describes the whole desktop arrangement with a handful of gsettings
keys, so a "layout mode" here is nothing more than a named snapshot of them.
This module holds the description of the four modes AcreetionOS ships and the
code that writes one of them into the running session.

Two rules keep the applier from eating a user's configuration:

* Only the applets a mode names are moved.  Everything else - the systray, the
  clock, the applets the user added themselves - is left exactly where it is.
* A panel the mode does not use is removed, but the applets that were on it
  are moved onto the main panel first, so nothing is thrown away.

The settings page in cinnamon-settings (cs_layout.py) and the
acreetionos-layout-mode command both come through here, so the two can never
drift apart.
"""

import gettext
import os

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

gettext.install("cinnamon", "/usr/share/locale", names=["ngettext"])

CINNAMON = "org.cinnamon"
WM = "org.cinnamon.desktop.wm.preferences"
MUFFIN = "org.cinnamon.muffin"

# Panel ids.  Panel 1 is the one Cinnamon creates by default and every mode
# keeps it; 90 is the dock the macOS mode needs.  The high id is deliberate:
# Cinnamon hands out the lowest free id when the user adds a panel, so 90
# cannot collide with a panel the user made themselves.
MAIN_PANEL = "1"
DOCK_PANEL = "90"

ZONES = ("left", "center", "right")

STATE_FILE = os.path.join(GLib.get_user_config_dir(), "acreetionos", "layout-mode")

# The applets a mode places.  Everything else on the panel is the user's and
# stays where it is.
MENU = "menu@cinnamon.org"
SEPARATOR = "separator@cinnamon.org"
WINDOW_LIST = "grouped-window-list@cinnamon.org"

MODES = {
    "acreetionos": {
        "label": "AcreetionOS",
        "summary": _("The AcreetionOS layout: one bar along the bottom with the "
                     "menu and the window list on the left and the system tray "
                     "on the right."),
        "panels": [
            {"id": MAIN_PANEL, "position": "bottom", "height": 40,
             "autohide": "intel"},
        ],
        "applets": {
            MENU: (MAIN_PANEL, "left", 0),
            SEPARATOR: (MAIN_PANEL, "left", 1),
            WINDOW_LIST: (MAIN_PANEL, "left", 2),
        },
        "button_layout": "menu:minimize,maximize,close",
        "edge_tiling": True,
        "tile_maximize": False,
    },
    "macos": {
        "label": "macOS",
        "summary": _("A menu bar along the top of the screen, a separate dock "
                     "along the bottom holding the window list, and the window "
                     "buttons on the left of every title bar."),
        "panels": [
            {"id": MAIN_PANEL, "position": "top", "height": 28,
             "autohide": "false"},
            {"id": DOCK_PANEL, "position": "bottom", "height": 48,
             "autohide": "false"},
        ],
        "applets": {
            MENU: (MAIN_PANEL, "left", 0),
            SEPARATOR: (MAIN_PANEL, "left", 1),
            WINDOW_LIST: (DOCK_PANEL, "center", 0),
        },
        "button_layout": "close,maximize,minimize:",
        "edge_tiling": True,
        "tile_maximize": False,
    },
    "windows": {
        "label": "Windows",
        "summary": _("A taskbar along the bottom: the menu as the start button "
                     "on the left, the window list in the middle and the system "
                     "tray on the right."),
        "panels": [
            {"id": MAIN_PANEL, "position": "bottom", "height": 40,
             "autohide": "false"},
        ],
        "applets": {
            MENU: (MAIN_PANEL, "left", 0),
            SEPARATOR: (MAIN_PANEL, "left", 1),
            WINDOW_LIST: (MAIN_PANEL, "center", 0),
        },
        "button_layout": "menu:minimize,maximize,close",
        "edge_tiling": True,
        "tile_maximize": False,
    },
    "windowmanager": {
        "label": _("Window Manager"),
        "summary": _("A slim bar that stays out of the way, the window list in "
                     "the middle, and tiling turned on so the desktop is driven "
                     "from the keyboard."),
        "panels": [
            {"id": MAIN_PANEL, "position": "bottom", "height": 32,
             "autohide": "true"},
        ],
        "applets": {
            MENU: (MAIN_PANEL, "left", 0),
            SEPARATOR: (MAIN_PANEL, "left", 1),
            WINDOW_LIST: (MAIN_PANEL, "center", 0),
        },
        "button_layout": "menu:minimize,maximize,close",
        "edge_tiling": True,
        "tile_maximize": True,
    },
}

# Aliases so the command line reads the way people expect it to.
ALIASES = {
    "wm": "windowmanager",
    "window-manager": "windowmanager",
    "mac": "macos",
    "macosx": "macos",
    "osx": "macos",
    "acreetion": "acreetionos",
    "acreetion-os": "acreetionos",
}


def get_mode(mode_id):
    """Return the mode with this id, or None if there is no such mode."""
    if not mode_id:
        return None
    mode_id = ALIASES.get(mode_id, mode_id)
    mode = MODES.get(mode_id)
    if mode is None:
        return None
    # Hand out a copy so a caller cannot edit the table by accident.
    mode = dict(mode)
    mode["id"] = mode_id
    return mode


def list_modes():
    """Return the modes in the order they are shown to the user."""
    return [get_mode(mode_id) for mode_id in MODES]


# ---------------------------------------------------------------------------
# Reading the current desktop
# ---------------------------------------------------------------------------

def _parse_entry(raw, index):
    """Split an enabled-applets entry into its parts.

    The format is 'panel:zone:order:uuid:applet-id', with an optional sixth
    field holding the applet's overrides.  Entries that do not fit the format
    are kept as they are rather than dropped - they may well be something a
    newer Cinnamon understands.
    """
    parts = raw.split(":", 5)
    entry = {"raw": raw, "index": index, "valid": False}

    if len(parts) < 5:
        return entry

    try:
        order = int(parts[2])
    except ValueError:
        order = 0

    entry["panel_id"] = parts[0].replace("panel", "", 1)
    entry["zone"] = parts[1]
    entry["order"] = order
    entry["uuid"] = parts[3]
    entry["instance"] = parts[4]
    entry["overrides"] = parts[5] if len(parts) > 5 else ""
    entry["valid"] = True
    return entry


def _format_entry(entry, order):
    raw = "panel%s:%s:%d:%s:%s" % (entry["panel_id"], entry["zone"], order,
                                   entry["uuid"], entry["instance"])
    if entry["overrides"]:
        raw += ":" + entry["overrides"]
    return raw


def _panel_value(settings, key, panel_id):
    """Read the 'panel_id:value' entry of a per-panel setting."""
    for raw in settings.get_strv(key):
        parts = raw.split(":")
        if len(parts) >= 2 and parts[0] == panel_id:
            return parts[1]
    return None


def _set_panel_value(settings, key, panel_id, value):
    """Write the 'panel_id:value' entry of a per-panel setting."""
    values = []
    replaced = False
    for raw in settings.get_strv(key):
        parts = raw.split(":")
        if parts and parts[0] == panel_id:
            if not replaced:
                values.append("%s:%s" % (panel_id, value))
                replaced = True
            continue
        values.append(raw)
    if not replaced:
        values.append("%s:%s" % (panel_id, value))
    settings.set_strv(key, values)


# ---------------------------------------------------------------------------
# Applying a mode
# ---------------------------------------------------------------------------

def _final_panels(settings, mode):
    """Return the panels the mode wants, as (id, monitor, position).

    A mode decides where a panel sits, not which screen it belongs to, so the
    monitor of a panel that already exists is kept.  Panels the mode does not
    use are dropped; their applets are rescued by _apply_applets().
    """
    enabled = settings.get_strv("panels-enabled")
    wanted = {panel["id"]: panel for panel in mode["panels"]}

    monitor = "0"
    for raw in enabled:
        parts = raw.split(":")
        if len(parts) == 3 and parts[0] == MAIN_PANEL:
            monitor = parts[1]
            break

    final = []
    for raw in enabled:
        parts = raw.split(":")
        if len(parts) != 3:
            continue
        panel_id = parts[0]
        if panel_id in wanted:
            final.append((panel_id, parts[1], wanted[panel_id]["position"]))

    for panel_id, panel in wanted.items():
        if not any(entry[0] == panel_id for entry in final):
            final.append((panel_id, monitor, panel["position"]))

    return final


def _apply_panels(settings, mode, final):
    """Put the panels where the mode wants them."""
    wanted = {panel["id"]: panel for panel in mode["panels"]}

    settings.set_strv("panels-enabled",
                      ["%s:%s:%s" % entry for entry in final])

    for panel_id, panel in wanted.items():
        _set_panel_value(settings, "panels-height", panel_id,
                         str(panel["height"]))
        _set_panel_value(settings, "panels-autohide", panel_id,
                         panel["autohide"])

        # A panel the session has not seen before needs the autohide delays as
        # well, or Cinnamon makes them up as it goes.
        if _panel_value(settings, "panels-show-delay", panel_id) is None:
            _set_panel_value(settings, "panels-show-delay", panel_id, "0")
        if _panel_value(settings, "panels-hide-delay", panel_id) is None:
            _set_panel_value(settings, "panels-hide-delay", panel_id, "0")

    # A panel that is not there any more has no business keeping its settings
    # around - they come back with the panel the next time a mode wants it.
    # Cinnamon puts some of them back itself while it tears a panel down, so
    # this does not always win, but it keeps the settings tidy where it can.
    for key in ("panels-height", "panels-autohide", "panels-show-delay",
                "panels-hide-delay"):
        settings.set_strv(key, [raw for raw in settings.get_strv(key)
                                if raw.split(":")[0] in wanted])


def _apply_applets(settings, mode, final):
    """Move the applets the mode places and leave the rest alone.

    The applets that are not touched keep the order numbers they already have,
    so nothing flickers.  The zones that are touched are renumbered from zero,
    which is the format Cinnamon itself writes.
    """
    raw_entries = settings.get_strv("enabled-applets")
    entries = [_parse_entry(raw, index) for index, raw in enumerate(raw_entries)]

    # Group the applets by the panel and zone they are in.
    zones = {}
    for entry in entries:
        if not entry["valid"]:
            continue
        zones.setdefault((entry["panel_id"], entry["zone"]), []).append(entry)

    for zone_entries in zones.values():
        zone_entries.sort(key=lambda entry: (entry["order"], entry["index"]))

    wanted_panels = {panel["id"] for panel in mode["panels"]}
    dirty = set()

    # Applets on a panel the mode drops move to the main panel, so that
    # switching modes never throws a panel's contents away.
    for entry in entries:
        if not entry["valid"] or entry["panel_id"] in wanted_panels:
            continue
        source = (entry["panel_id"], entry["zone"])
        target = (MAIN_PANEL, entry["zone"])
        if source == target:
            continue
        zones[source].remove(entry)
        dirty.add(source)
        entry["panel_id"] = MAIN_PANEL
        zones.setdefault(target, []).append(entry)
        dirty.add(target)

    # Take the applets the mode places out of the zone they are in now.
    placed = {}
    for uuid, (panel_id, zone, index) in mode["applets"].items():
        for zone_entries in zones.values():
            match = next((entry for entry in zone_entries
                          if entry["uuid"] == uuid), None)
            if match is not None:
                zone_entries.remove(match)
                dirty.add((match["panel_id"], match["zone"]))
                placed[uuid] = (match, panel_id, zone, index)
                break

    # Put them into their new zone at the position the mode asks for.  The
    # order the modes list their applets in is the order they appear on the
    # panel.
    for uuid, (entry, panel_id, zone, index) in placed.items():
        target = zones.setdefault((panel_id, zone), [])
        target.insert(min(index, len(target)), entry)
        entry["panel_id"] = panel_id
        entry["zone"] = zone
        dirty.add((panel_id, zone))

    for key in dirty:
        for position, entry in enumerate(zones.get(key, [])):
            entry["order"] = position

    # Write the list back, panel by panel and zone by zone, so that it reads
    # the same way the panel does.
    panel_order = [entry[0] for entry in final]
    for entry in entries:
        if entry["valid"] and entry["panel_id"] not in panel_order:
            panel_order.append(entry["panel_id"])

    new_entries = []
    for panel_id in panel_order:
        for zone in ZONES:
            for entry in zones.get((panel_id, zone), []):
                new_entries.append(_format_entry(entry, entry["order"]))

    # Anything we could not parse is kept verbatim at the end.
    new_entries.extend(entry["raw"] for entry in entries if not entry["valid"])

    settings.set_strv("enabled-applets", new_entries)


def apply_mode(mode_id):
    """Apply a layout mode to the running session."""
    mode = get_mode(mode_id)
    if mode is None:
        raise ValueError("unknown layout mode: %s" % mode_id)

    cinnamon = Gio.Settings.new(CINNAMON)
    wm = Gio.Settings.new(WM)
    muffin = Gio.Settings.new(MUFFIN)

    # The applets are moved before the panels are changed: Cinnamon keeps the
    # definition of an applet whose panel does not exist yet and puts it on the
    # panel as soon as that panel appears.
    final = _final_panels(cinnamon, mode)
    _apply_applets(cinnamon, mode, final)
    _apply_panels(cinnamon, mode, final)

    wm.set_string("button-layout", mode["button_layout"])
    muffin.set_boolean("edge-tiling", mode["edge_tiling"])
    muffin.set_boolean("tile-maximize", mode["tile_maximize"])

    write_state(mode["id"])
    return mode


# ---------------------------------------------------------------------------
# Which mode is active
# ---------------------------------------------------------------------------

def read_state():
    """Return the mode id that was applied last, or None."""
    try:
        with open(STATE_FILE, "r") as handle:
            mode_id = handle.read().strip()
    except OSError:
        return None
    return mode_id if get_mode(mode_id) else None


def write_state(mode_id):
    """Record the mode that is now in use."""
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w") as handle:
        handle.write("%s\n" % mode_id)


def detect_mode():
    """Work out which mode the desktop is currently set up like.

    This is what the settings page falls back on when no mode has been applied
    yet - a fresh install ships in the AcreetionOS layout but has never been
    through the applier.
    """
    cinnamon = Gio.Settings.new(CINNAMON)
    wm = Gio.Settings.new(WM)

    enabled = [raw.split(":") for raw in cinnamon.get_strv("panels-enabled")]
    enabled = [parts for parts in enabled if len(parts) == 3]
    positions = {parts[0]: parts[2] for parts in enabled}

    entries = [_parse_entry(raw, index)
               for index, raw in enumerate(cinnamon.get_strv("enabled-applets"))]
    placements = {}
    for entry in entries:
        if entry["valid"] and entry["uuid"] not in placements:
            placements[entry["uuid"]] = (entry["panel_id"], entry["zone"])

    button_layout = wm.get_string("button-layout")

    for mode in list_modes():
        if mode["button_layout"] != button_layout:
            continue
        if set(positions) != {panel["id"] for panel in mode["panels"]}:
            continue
        if any(positions[panel["id"]] != panel["position"]
               for panel in mode["panels"]):
            continue
        if any(placements.get(uuid) != (panel_id, zone)
               for uuid, (panel_id, zone, _) in mode["applets"].items()):
            continue
        return mode["id"]

    return None


def current_mode():
    """Return the mode that is in use, or None if the desktop is set up by hand."""
    state = read_state()
    if state:
        return state
    return detect_mode()
