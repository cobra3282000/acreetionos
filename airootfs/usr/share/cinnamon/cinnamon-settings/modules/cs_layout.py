#!/usr/bin/python3

import os
import sys

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

from SettingsWidgets import SidePage
from xapp.GSettingsWidgets import *

# The layout modes themselves live outside of Cinnamon, so that the command
# line tool and this page always agree on what a mode means.
for _path in ("/usr/lib/acreetionos",
              os.path.join(os.path.dirname(os.path.dirname(
                  os.path.dirname(os.path.realpath(__file__)))),
                  "lib", "acreetionos")):
    if os.path.isdir(_path):
        sys.path.insert(0, _path)
        break

import layout_modes


class Module:
    name = "layout"
    category = "prefs"
    comment = _("Manage the AcreetionOS desktop layout modes")

    def __init__(self, content_box):
        keywords = _("layout, mode, modes, macos, mac, osx, windows, window "
                     "manager, acreetionos, dock, taskbar, menu bar, panel")
        self.sidePage = SidePage(_("Layout Modes"), "cs-layout", keywords,
                                 content_box, module=self)
        self.buttons = {}
        self.updating = False

    def on_module_selected(self):
        if not self.loaded:
            print("Loading Layout Modes module")

            page = SettingsPage()
            self.sidePage.add_widget(page)

            section = page.add_section(
                _("Desktop layout"),
                _("Pick the way the desktop is arranged. The change is made "
                  "straight away - nothing is lost, the applets you added "
                  "yourself stay on the panel."))

            group = None
            for mode in layout_modes.list_modes():
                button = Gtk.RadioButton()
                if group is None:
                    group = button
                else:
                    button.join_group(group)

                box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
                title = Gtk.Label()
                title.set_markup("<b>%s</b>" % mode["label"])
                title.set_xalign(0)
                description = Gtk.Label(label=mode["summary"])
                description.set_xalign(0)
                description.set_line_wrap(True)
                description.get_style_context().add_class("dim-label")
                box.pack_start(title, False, False, 0)
                box.pack_start(description, False, False, 0)
                button.add(box)

                button.connect("toggled", self.on_mode_toggled, mode["id"])
                self.buttons[mode["id"]] = button
                section.add_row(button)

            self.status = Gtk.Label()
            self.status.set_xalign(0)
            self.status.get_style_context().add_class("dim-label")
            page.add(self.status)

        self.show_current_mode()

    def show_current_mode(self):
        """Mark the mode that is in use."""
        mode_id = layout_modes.current_mode()
        self.updating = True
        try:
            for button_id, button in self.buttons.items():
                button.set_active(button_id == mode_id)
        finally:
            self.updating = False

        if mode_id is None:
            self.status.set_text(_("The desktop is set up by hand, so no "
                                   "layout mode is marked as active."))
        else:
            mode = layout_modes.get_mode(mode_id)
            self.status.set_text(_("The %s layout is in use.") % mode["label"])

    def on_mode_toggled(self, button, mode_id):
        if self.updating or not button.get_active():
            return

        # Re-applying the mode that is already in use would rewrite the same
        # settings for nothing.
        if mode_id == layout_modes.current_mode():
            return

        try:
            mode = layout_modes.apply_mode(mode_id)
        except Exception as error:
            label = layout_modes.get_mode(mode_id)["label"]
            self.status.set_text(_("The %s layout could not be applied: %s") %
                                 (label, error))
            return

        self.status.set_text(_("The %s layout is in use.") % mode["label"])
