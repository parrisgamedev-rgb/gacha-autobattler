"""
Gacha Autobattler Content Editor
A desktop application for managing game content
"""

import os
import sys
import shutil
import tkinter as tk
from tkinter import filedialog, messagebox
from typing import Optional, List, Dict, Any

try:
    import customtkinter as ctk
    from PIL import Image, ImageTk
except ImportError:
    print("Missing dependencies. Please run: pip install customtkinter pillow")
    sys.exit(1)

from tres_parser import TresParser, TresResource

# Theme configuration
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

# Colors matching the game's UI theme
COLORS = {
    'bg_dark': '#1a1a2e',
    'bg_medium': '#252542',
    'bg_light': '#2d2d4a',
    'primary': '#4a9eff',
    'secondary': '#7c5cff',
    'success': '#4ade80',
    'danger': '#f87171',
    'gold': '#fbbf24',
    'text': '#ffffff',
    'text_secondary': '#94a3b8',
}

ELEMENTS = ['fire', 'water', 'nature', 'light', 'dark']
ELEMENT_COLORS = {
    'fire': '#ff6b6b',
    'water': '#4a9eff',
    'nature': '#7bed9f',
    'light': '#fff68f',
    'dark': '#9b59b6',
}


class ContentEditor(ctk.CTk):
    """Main application window"""

    def __init__(self):
        super().__init__()

        self.title("Gacha Autobattler - Content Editor")
        self.geometry("1200x800")
        self.configure(fg_color=COLORS['bg_dark'])

        # Find game root directory
        self.game_root = self._find_game_root()
        if not self.game_root:
            messagebox.showerror("Error", "Could not find game directory. Please run from tools/content_editor/")
            sys.exit(1)

        self.parser = TresParser(self.game_root)

        # Data caches
        self.units: List[TresResource] = []
        self.abilities: List[TresResource] = []
        self.gear: List[TresResource] = []
        self.stages: List[TresResource] = []
        self.dungeons: List[TresResource] = []

        # Current selection
        self.current_panel = "units"
        self.selected_item: Optional[TresResource] = None

        self._create_ui()
        self._load_all_data()

    def _find_game_root(self) -> Optional[str]:
        """Find the game root directory"""
        # Try relative paths from different possible locations
        possible_paths = [
            os.path.join(os.path.dirname(__file__), '..', '..'),  # From tools/content_editor
            os.path.join(os.path.dirname(__file__), '..'),  # From tools
            os.path.dirname(__file__),  # Current dir
        ]

        for path in possible_paths:
            check_path = os.path.normpath(path)
            if os.path.exists(os.path.join(check_path, 'project.godot')):
                return check_path

        return None

    def _create_ui(self):
        """Create the main UI layout"""
        # Sidebar
        self.sidebar = ctk.CTkFrame(self, width=200, fg_color=COLORS['bg_medium'])
        self.sidebar.pack(side='left', fill='y', padx=0, pady=0)
        self.sidebar.pack_propagate(False)

        # Sidebar title
        title_label = ctk.CTkLabel(
            self.sidebar,
            text="Content Editor",
            font=ctk.CTkFont(size=18, weight="bold"),
            text_color=COLORS['text']
        )
        title_label.pack(pady=(20, 30))

        # Navigation buttons
        nav_buttons = [
            ("Units", "units"),
            ("Abilities", "abilities"),
            ("Gear", "gear"),
            ("Stages", "stages"),
            ("Dungeons", "dungeons"),
            ("Assets", "assets"),
        ]

        self.nav_buttons = {}
        for text, panel_name in nav_buttons:
            btn = ctk.CTkButton(
                self.sidebar,
                text=text,
                command=lambda p=panel_name: self._switch_panel(p),
                fg_color=COLORS['bg_light'],
                hover_color=COLORS['primary'],
                height=40,
                font=ctk.CTkFont(size=14)
            )
            btn.pack(fill='x', padx=10, pady=5)
            self.nav_buttons[panel_name] = btn

        # Main content area
        self.content_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_dark'])
        self.content_frame.pack(side='right', fill='both', expand=True, padx=10, pady=10)

        # Create all panels
        self.panels = {}
        self.panels['units'] = UnitsPanel(self.content_frame, self)
        self.panels['abilities'] = AbilitiesPanel(self.content_frame, self)
        self.panels['gear'] = GearPanel(self.content_frame, self)
        self.panels['stages'] = StagesPanel(self.content_frame, self)
        self.panels['dungeons'] = DungeonsPanel(self.content_frame, self)
        self.panels['assets'] = AssetsPanel(self.content_frame, self)

        # Show initial panel
        self._switch_panel('units')

    def _switch_panel(self, panel_name: str):
        """Switch to a different content panel"""
        # Update nav button styles
        for name, btn in self.nav_buttons.items():
            if name == panel_name:
                btn.configure(fg_color=COLORS['primary'])
            else:
                btn.configure(fg_color=COLORS['bg_light'])

        # Hide all panels
        for panel in self.panels.values():
            panel.pack_forget()

        # Show selected panel
        self.panels[panel_name].pack(fill='both', expand=True)
        self.current_panel = panel_name

        # Refresh panel data
        self.panels[panel_name].refresh()

    def _load_all_data(self):
        """Load all game data"""
        try:
            self.units = self.parser.get_all_units()
            self.abilities = self.parser.get_all_abilities()
            self.gear = self.parser.get_all_gear()
            self.stages = self.parser.get_all_stages()
            self.dungeons = self.parser.get_all_dungeons()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load game data: {e}")

    def get_ability_name(self, ability_id: str) -> str:
        """Get ability name by ID or ext_resource ID"""
        for ability in self.abilities:
            if ability.properties.get('ability_id') == ability_id:
                return ability.properties.get('ability_name', ability_id)
        return ability_id

    def get_unit_name(self, unit_id: str) -> str:
        """Get unit name by ID"""
        for unit in self.units:
            if unit.properties.get('unit_id') == unit_id:
                return unit.properties.get('unit_name', unit_id)
        return unit_id


class BasePanel(ctk.CTkFrame):
    """Base class for content panels"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, fg_color=COLORS['bg_dark'])
        self.app = app

    def refresh(self):
        """Override to refresh panel data"""
        pass


class UnitsPanel(BasePanel):
    """Panel for editing units"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        # Split into list and editor
        self.list_frame = ctk.CTkFrame(self, width=300, fg_color=COLORS['bg_medium'])
        self.list_frame.pack(side='left', fill='y', padx=(0, 10), pady=0)
        self.list_frame.pack_propagate(False)

        self.editor_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.editor_frame.pack(side='right', fill='both', expand=True)

        # List header
        header_frame = ctk.CTkFrame(self.list_frame, fg_color='transparent')
        header_frame.pack(fill='x', padx=10, pady=10)

        ctk.CTkLabel(
            header_frame,
            text="Units",
            font=ctk.CTkFont(size=16, weight="bold")
        ).pack(side='left')

        ctk.CTkButton(
            header_frame,
            text="+ New",
            width=60,
            command=self._create_new,
            fg_color=COLORS['success'],
            hover_color=COLORS['primary']
        ).pack(side='right')

        # Search/filter
        self.search_var = ctk.StringVar()
        self.search_var.trace('w', lambda *args: self._filter_list())
        ctk.CTkEntry(
            self.list_frame,
            placeholder_text="Search...",
            textvariable=self.search_var
        ).pack(fill='x', padx=10, pady=(0, 10))

        # Element filter
        self.element_filter = ctk.CTkComboBox(
            self.list_frame,
            values=["All Elements"] + [e.capitalize() for e in ELEMENTS],
            command=lambda _: self._filter_list()
        )
        self.element_filter.set("All Elements")
        self.element_filter.pack(fill='x', padx=10, pady=(0, 10))

        # Scrollable list
        self.list_scroll = ctk.CTkScrollableFrame(self.list_frame, fg_color='transparent')
        self.list_scroll.pack(fill='both', expand=True, padx=5)

        self.list_items = []

        # Editor area (initially hidden)
        self._create_editor()

    def _create_editor(self):
        """Create the editor form"""
        self.editor_scroll = ctk.CTkScrollableFrame(self.editor_frame, fg_color='transparent')
        self.editor_scroll.pack(fill='both', expand=True, padx=20, pady=20)

        # Title
        self.editor_title = ctk.CTkLabel(
            self.editor_scroll,
            text="Select a unit to edit",
            font=ctk.CTkFont(size=18, weight="bold")
        )
        self.editor_title.pack(anchor='w', pady=(0, 20))

        # Form fields
        self.fields = {}

        # Basic info section
        self._add_section("Basic Info")
        self.fields['unit_name'] = self._add_field("Name", "entry")
        self.fields['unit_id'] = self._add_field("ID", "entry")
        self.fields['element'] = self._add_field("Element", "combo", ELEMENTS)
        self.fields['star_rating'] = self._add_field("Star Rating", "combo", ["3", "4", "5"])

        # Stats section
        self._add_section("Base Stats")
        self.fields['max_hp'] = self._add_field("Max HP", "entry")
        self.fields['attack'] = self._add_field("Attack", "entry")
        self.fields['defense'] = self._add_field("Defense", "entry")
        self.fields['speed'] = self._add_field("Speed", "entry")

        # Abilities section
        self._add_section("Abilities")
        ability_names = ["None"] + [a.properties.get('ability_name', 'Unknown') for a in self.app.abilities]
        self.fields['ability_1'] = self._add_field("Ability 1", "combo", ability_names)
        self.fields['ability_2'] = self._add_field("Ability 2", "combo", ability_names)
        self.fields['ability_3'] = self._add_field("Ability 3", "combo", ability_names)

        # Save/Delete buttons
        btn_frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        btn_frame.pack(fill='x', pady=20)

        ctk.CTkButton(
            btn_frame,
            text="Save",
            command=self._save_current,
            fg_color=COLORS['success'],
            hover_color=COLORS['primary']
        ).pack(side='left', padx=(0, 10))

        ctk.CTkButton(
            btn_frame,
            text="Delete",
            command=self._delete_current,
            fg_color=COLORS['danger'],
            hover_color='#dc2626'
        ).pack(side='left')

    def _add_section(self, title: str):
        """Add a section header"""
        ctk.CTkLabel(
            self.editor_scroll,
            text=title,
            font=ctk.CTkFont(size=14, weight="bold"),
            text_color=COLORS['primary']
        ).pack(anchor='w', pady=(15, 5))

    def _add_field(self, label: str, field_type: str, options: List[str] = None):
        """Add a form field"""
        frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        frame.pack(fill='x', pady=5)

        ctk.CTkLabel(
            frame,
            text=label,
            width=100,
            anchor='w'
        ).pack(side='left')

        if field_type == "entry":
            widget = ctk.CTkEntry(frame, width=200)
        elif field_type == "combo":
            widget = ctk.CTkComboBox(frame, values=options or [], width=200)
        elif field_type == "checkbox":
            widget = ctk.CTkCheckBox(frame, text="")
        else:
            widget = ctk.CTkEntry(frame, width=200)

        widget.pack(side='left', padx=(10, 0))
        return widget

    def refresh(self):
        """Refresh the unit list"""
        self.app.units = self.app.parser.get_all_units()
        self._populate_list()
        self._update_ability_dropdowns()

    def _update_ability_dropdowns(self):
        """Update ability dropdown options"""
        ability_names = ["None"] + [a.properties.get('ability_name', 'Unknown') for a in self.app.abilities]
        for key in ['ability_1', 'ability_2', 'ability_3']:
            if key in self.fields:
                current = self.fields[key].get()
                self.fields[key].configure(values=ability_names)
                if current in ability_names:
                    self.fields[key].set(current)

    def _populate_list(self):
        """Populate the unit list"""
        # Clear existing items
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        # Filter units
        search = self.search_var.get().lower()
        element_filter = self.element_filter.get()

        for unit in self.app.units:
            name = unit.properties.get('unit_name', 'Unknown')
            element = unit.properties.get('element', 'fire')
            stars = unit.properties.get('star_rating', 3)

            # Apply filters
            if search and search not in name.lower():
                continue
            if element_filter != "All Elements" and element.capitalize() != element_filter:
                continue

            # Create list item
            item_frame = ctk.CTkFrame(self.list_scroll, fg_color=COLORS['bg_light'], height=50)
            item_frame.pack(fill='x', pady=2)
            item_frame.pack_propagate(False)

            # Element color indicator
            color_bar = ctk.CTkFrame(item_frame, width=4, fg_color=ELEMENT_COLORS.get(element, '#ffffff'))
            color_bar.pack(side='left', fill='y')

            # Unit info
            info_frame = ctk.CTkFrame(item_frame, fg_color='transparent')
            info_frame.pack(side='left', fill='both', expand=True, padx=10, pady=5)

            ctk.CTkLabel(
                info_frame,
                text=name,
                font=ctk.CTkFont(size=13, weight="bold"),
                anchor='w'
            ).pack(anchor='w')

            ctk.CTkLabel(
                info_frame,
                text=f"{'★' * stars} | {element.capitalize()}",
                font=ctk.CTkFont(size=11),
                text_color=COLORS['text_secondary'],
                anchor='w'
            ).pack(anchor='w')

            # Make clickable
            item_frame.bind('<Button-1>', lambda e, u=unit: self._select_unit(u))
            for child in item_frame.winfo_children():
                child.bind('<Button-1>', lambda e, u=unit: self._select_unit(u))
                for subchild in child.winfo_children():
                    subchild.bind('<Button-1>', lambda e, u=unit: self._select_unit(u))

            self.list_items.append(item_frame)

    def _filter_list(self):
        """Filter the list based on search/element"""
        self._populate_list()

    def _select_unit(self, unit: TresResource):
        """Select a unit for editing"""
        self.selected_unit = unit
        self.editor_title.configure(text=f"Editing: {unit.properties.get('unit_name', 'Unknown')}")

        # Populate fields
        self.fields['unit_name'].delete(0, 'end')
        self.fields['unit_name'].insert(0, unit.properties.get('unit_name', ''))

        self.fields['unit_id'].delete(0, 'end')
        self.fields['unit_id'].insert(0, unit.properties.get('unit_id', ''))

        self.fields['element'].set(unit.properties.get('element', 'fire'))
        self.fields['star_rating'].set(str(unit.properties.get('star_rating', 3)))

        self.fields['max_hp'].delete(0, 'end')
        self.fields['max_hp'].insert(0, str(unit.properties.get('max_hp', 100)))

        self.fields['attack'].delete(0, 'end')
        self.fields['attack'].insert(0, str(unit.properties.get('attack', 20)))

        self.fields['defense'].delete(0, 'end')
        self.fields['defense'].insert(0, str(unit.properties.get('defense', 10)))

        self.fields['speed'].delete(0, 'end')
        self.fields['speed'].insert(0, str(unit.properties.get('speed', 10)))

        # Load abilities
        abilities_prop = unit.properties.get('abilities', {'type': 'Array', 'items': []})
        ability_items = abilities_prop.get('items', []) if isinstance(abilities_prop, dict) else []

        for i, ability_field in enumerate(['ability_1', 'ability_2', 'ability_3']):
            if i < len(ability_items):
                ability_ref = ability_items[i]
                if isinstance(ability_ref, dict) and ability_ref.get('type') == 'ExtResource':
                    # Look up ability by ext_resource id
                    ext_id = ability_ref.get('id', '')
                    ext_info = unit.ext_resources.get(ext_id, {})
                    ability_path = ext_info.get('path', '')
                    # Find ability name from path
                    for ability in self.app.abilities:
                        if ability.file_path.replace('\\', '/').endswith(ability_path.replace('res://', '')):
                            self.fields[ability_field].set(ability.properties.get('ability_name', 'None'))
                            break
                    else:
                        self.fields[ability_field].set('None')
                else:
                    self.fields[ability_field].set('None')
            else:
                self.fields[ability_field].set('None')

    def _create_new(self):
        """Create a new unit"""
        # Generate new unit
        new_unit = TresResource()
        new_unit.resource_type = "Resource"
        new_unit.script_class = "UnitData"
        new_unit.uid = self.app.parser.generate_uid("unit")

        new_unit.ext_resources = {
            '1_script': {
                'type': 'Script',
                'uid': '',
                'path': 'res://scripts/data/unit_data.gd'
            }
        }

        new_unit.properties = {
            'script': {'type': 'ExtResource', 'id': '1_script'},
            'unit_name': 'New Unit',
            'unit_id': f'new_unit_{len(self.app.units) + 1:03d}',
            'star_rating': 3,
            'element': 'fire',
            'max_hp': 100,
            'attack': 20,
            'defense': 10,
            'speed': 10,
            'abilities': {'type': 'Array', 'element_type': 'Resource', 'items': []},
            'portrait_color': {'type': 'Color', 'values': [1.0, 1.0, 1.0, 1.0]}
        }

        # Save to file
        filename = f"{new_unit.properties['unit_id']}.tres"
        filepath = os.path.join(self.app.game_root, 'resources', 'units', filename)
        new_unit.file_path = filepath

        self.app.parser.write_file(new_unit, filepath)
        self.app.units.append(new_unit)
        self._populate_list()
        self._select_unit(new_unit)

        messagebox.showinfo("Success", f"Created new unit: {filename}")

    def _save_current(self):
        """Save the current unit"""
        if not hasattr(self, 'selected_unit') or not self.selected_unit:
            messagebox.showwarning("Warning", "No unit selected")
            return

        unit = self.selected_unit

        # Update properties from fields
        unit.properties['unit_name'] = self.fields['unit_name'].get()
        unit.properties['unit_id'] = self.fields['unit_id'].get()
        unit.properties['element'] = self.fields['element'].get()
        unit.properties['star_rating'] = int(self.fields['star_rating'].get())
        unit.properties['max_hp'] = int(self.fields['max_hp'].get())
        unit.properties['attack'] = int(self.fields['attack'].get())
        unit.properties['defense'] = int(self.fields['defense'].get())
        unit.properties['speed'] = int(self.fields['speed'].get())

        # Update abilities
        ability_refs = []
        ext_resource_id = 2  # Start after script
        new_ext_resources = {
            '1_script': unit.ext_resources.get('1_script', {
                'type': 'Script',
                'uid': '',
                'path': 'res://scripts/data/unit_data.gd'
            })
        }

        for ability_field in ['ability_1', 'ability_2', 'ability_3']:
            ability_name = self.fields[ability_field].get()
            if ability_name and ability_name != "None":
                # Find ability file
                for ability in self.app.abilities:
                    if ability.properties.get('ability_name') == ability_name:
                        res_id = f"{ext_resource_id}_ability"
                        ability_path = ability.file_path.replace(self.app.game_root, 'res:/').replace('\\', '/')
                        new_ext_resources[res_id] = {
                            'type': 'Resource',
                            'uid': ability.uid,
                            'path': ability_path
                        }
                        ability_refs.append({'type': 'ExtResource', 'id': res_id})
                        ext_resource_id += 1
                        break

        unit.ext_resources = new_ext_resources
        unit.properties['abilities'] = {
            'type': 'Array',
            'element_type': 'Resource',
            'items': ability_refs
        }

        # Save file
        self.app.parser.write_file(unit, unit.file_path)
        self._populate_list()

        messagebox.showinfo("Success", f"Saved unit: {unit.properties['unit_name']}")

    def _delete_current(self):
        """Delete the current unit"""
        if not hasattr(self, 'selected_unit') or not self.selected_unit:
            messagebox.showwarning("Warning", "No unit selected")
            return

        unit = self.selected_unit
        name = unit.properties.get('unit_name', 'Unknown')

        if messagebox.askyesno("Confirm Delete", f"Are you sure you want to delete '{name}'?"):
            try:
                os.remove(unit.file_path)
                self.app.units.remove(unit)
                self.selected_unit = None
                self._populate_list()
                self.editor_title.configure(text="Select a unit to edit")
                messagebox.showinfo("Success", f"Deleted unit: {name}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to delete: {e}")


class AbilitiesPanel(BasePanel):
    """Panel for editing abilities"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        # Split into list and editor
        self.list_frame = ctk.CTkFrame(self, width=300, fg_color=COLORS['bg_medium'])
        self.list_frame.pack(side='left', fill='y', padx=(0, 10))
        self.list_frame.pack_propagate(False)

        self.editor_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.editor_frame.pack(side='right', fill='both', expand=True)

        # List header
        header_frame = ctk.CTkFrame(self.list_frame, fg_color='transparent')
        header_frame.pack(fill='x', padx=10, pady=10)

        ctk.CTkLabel(header_frame, text="Abilities", font=ctk.CTkFont(size=16, weight="bold")).pack(side='left')

        ctk.CTkButton(
            header_frame, text="+ New", width=60, command=self._create_new,
            fg_color=COLORS['success'], hover_color=COLORS['primary']
        ).pack(side='right')

        # Search
        self.search_var = ctk.StringVar()
        self.search_var.trace('w', lambda *args: self._filter_list())
        ctk.CTkEntry(self.list_frame, placeholder_text="Search...", textvariable=self.search_var).pack(fill='x', padx=10, pady=(0, 10))

        # Scrollable list
        self.list_scroll = ctk.CTkScrollableFrame(self.list_frame, fg_color='transparent')
        self.list_scroll.pack(fill='both', expand=True, padx=5)

        self.list_items = []
        self._create_editor()

    def _create_editor(self):
        """Create the editor form"""
        self.editor_scroll = ctk.CTkScrollableFrame(self.editor_frame, fg_color='transparent')
        self.editor_scroll.pack(fill='both', expand=True, padx=20, pady=20)

        self.editor_title = ctk.CTkLabel(self.editor_scroll, text="Select an ability to edit", font=ctk.CTkFont(size=18, weight="bold"))
        self.editor_title.pack(anchor='w', pady=(0, 20))

        self.fields = {}

        # Basic info
        self._add_section("Basic Info")
        self.fields['ability_name'] = self._add_field("Name", "entry")
        self.fields['ability_id'] = self._add_field("ID", "entry")
        self.fields['description'] = self._add_field("Description", "entry")
        self.fields['ability_type'] = self._add_field("Type", "combo", ["0 (Active)", "1 (Passive)"])

        # Combat stats
        self._add_section("Combat Stats")
        self.fields['damage_multiplier'] = self._add_field("Damage Mult", "entry")
        self.fields['defense_multiplier'] = self._add_field("Defense Mult", "entry")
        self.fields['heal_amount'] = self._add_field("Heal Amount", "entry")
        self.fields['bonus_damage'] = self._add_field("Bonus Damage", "entry")
        self.fields['cooldown'] = self._add_field("Cooldown", "entry")

        # Special effects
        self._add_section("Special Effects")
        self.fields['ignores_element'] = self._add_field("Ignores Element", "checkbox")
        self.fields['guaranteed_survive'] = self._add_field("Guaranteed Survive", "checkbox")
        self.fields['counter_attack'] = self._add_field("Counter Attack", "checkbox")
        self.fields['piercing'] = self._add_field("Piercing", "checkbox")

        # Save/Delete
        btn_frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        btn_frame.pack(fill='x', pady=20)

        ctk.CTkButton(btn_frame, text="Save", command=self._save_current, fg_color=COLORS['success']).pack(side='left', padx=(0, 10))
        ctk.CTkButton(btn_frame, text="Delete", command=self._delete_current, fg_color=COLORS['danger']).pack(side='left')

    def _add_section(self, title: str):
        ctk.CTkLabel(self.editor_scroll, text=title, font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w', pady=(15, 5))

    def _add_field(self, label: str, field_type: str, options: List[str] = None):
        frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        frame.pack(fill='x', pady=5)

        ctk.CTkLabel(frame, text=label, width=120, anchor='w').pack(side='left')

        if field_type == "entry":
            widget = ctk.CTkEntry(frame, width=200)
        elif field_type == "combo":
            widget = ctk.CTkComboBox(frame, values=options or [], width=200)
        elif field_type == "checkbox":
            var = ctk.BooleanVar()
            widget = ctk.CTkCheckBox(frame, text="", variable=var)
            widget.var = var
        else:
            widget = ctk.CTkEntry(frame, width=200)

        widget.pack(side='left', padx=(10, 0))
        return widget

    def refresh(self):
        self.app.abilities = self.app.parser.get_all_abilities()
        self._populate_list()

    def _populate_list(self):
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        search = self.search_var.get().lower()

        for ability in self.app.abilities:
            name = ability.properties.get('ability_name', 'Unknown')
            if search and search not in name.lower():
                continue

            item_frame = ctk.CTkFrame(self.list_scroll, fg_color=COLORS['bg_light'], height=40)
            item_frame.pack(fill='x', pady=2)
            item_frame.pack_propagate(False)

            ctk.CTkLabel(item_frame, text=name, font=ctk.CTkFont(size=13), anchor='w').pack(side='left', padx=10, pady=5)

            item_frame.bind('<Button-1>', lambda e, a=ability: self._select_ability(a))
            for child in item_frame.winfo_children():
                child.bind('<Button-1>', lambda e, a=ability: self._select_ability(a))

            self.list_items.append(item_frame)

    def _filter_list(self):
        self._populate_list()

    def _select_ability(self, ability: TresResource):
        self.selected_ability = ability
        self.editor_title.configure(text=f"Editing: {ability.properties.get('ability_name', 'Unknown')}")

        self.fields['ability_name'].delete(0, 'end')
        self.fields['ability_name'].insert(0, ability.properties.get('ability_name', ''))

        self.fields['ability_id'].delete(0, 'end')
        self.fields['ability_id'].insert(0, ability.properties.get('ability_id', ''))

        self.fields['description'].delete(0, 'end')
        self.fields['description'].insert(0, ability.properties.get('description', ''))

        ability_type = ability.properties.get('ability_type', 0)
        self.fields['ability_type'].set(f"{ability_type} ({'Active' if ability_type == 0 else 'Passive'})")

        self.fields['damage_multiplier'].delete(0, 'end')
        self.fields['damage_multiplier'].insert(0, str(ability.properties.get('damage_multiplier', 1.0)))

        self.fields['defense_multiplier'].delete(0, 'end')
        self.fields['defense_multiplier'].insert(0, str(ability.properties.get('defense_multiplier', 1.0)))

        self.fields['heal_amount'].delete(0, 'end')
        self.fields['heal_amount'].insert(0, str(ability.properties.get('heal_amount', 0)))

        self.fields['bonus_damage'].delete(0, 'end')
        self.fields['bonus_damage'].insert(0, str(ability.properties.get('bonus_damage', 0)))

        self.fields['cooldown'].delete(0, 'end')
        self.fields['cooldown'].insert(0, str(ability.properties.get('cooldown', 0)))

        self.fields['ignores_element'].var.set(ability.properties.get('ignores_element', False))
        self.fields['guaranteed_survive'].var.set(ability.properties.get('guaranteed_survive', False))
        self.fields['counter_attack'].var.set(ability.properties.get('counter_attack', False))
        self.fields['piercing'].var.set(ability.properties.get('piercing', False))

    def _create_new(self):
        new_ability = TresResource()
        new_ability.resource_type = "Resource"
        new_ability.script_class = "AbilityData"
        new_ability.uid = self.app.parser.generate_uid("ability")

        new_ability.ext_resources = {
            '1_script': {'type': 'Script', 'uid': '', 'path': 'res://scripts/data/ability_data.gd'}
        }

        new_ability.properties = {
            'script': {'type': 'ExtResource', 'id': '1_script'},
            'ability_name': 'New Ability',
            'ability_id': f'new_ability_{len(self.app.abilities) + 1:03d}',
            'description': 'A new ability.',
            'ability_type': 0,
            'damage_multiplier': 1.0,
            'defense_multiplier': 1.0,
            'heal_amount': 0,
            'bonus_damage': 0,
            'ignores_element': False,
            'guaranteed_survive': False,
            'counter_attack': False,
            'piercing': False,
            'cooldown': 0,
            'icon_color': {'type': 'Color', 'values': [1.0, 1.0, 1.0, 1.0]}
        }

        filename = f"{new_ability.properties['ability_id']}.tres"
        filepath = os.path.join(self.app.game_root, 'resources', 'abilities', filename)
        new_ability.file_path = filepath

        self.app.parser.write_file(new_ability, filepath)
        self.app.abilities.append(new_ability)
        self._populate_list()
        self._select_ability(new_ability)

        messagebox.showinfo("Success", f"Created new ability: {filename}")

    def _save_current(self):
        if not hasattr(self, 'selected_ability') or not self.selected_ability:
            messagebox.showwarning("Warning", "No ability selected")
            return

        ability = self.selected_ability
        ability.properties['ability_name'] = self.fields['ability_name'].get()
        ability.properties['ability_id'] = self.fields['ability_id'].get()
        ability.properties['description'] = self.fields['description'].get()

        type_str = self.fields['ability_type'].get()
        ability.properties['ability_type'] = int(type_str.split()[0])

        ability.properties['damage_multiplier'] = float(self.fields['damage_multiplier'].get())
        ability.properties['defense_multiplier'] = float(self.fields['defense_multiplier'].get())
        ability.properties['heal_amount'] = int(self.fields['heal_amount'].get())
        ability.properties['bonus_damage'] = int(self.fields['bonus_damage'].get())
        ability.properties['cooldown'] = int(self.fields['cooldown'].get())

        ability.properties['ignores_element'] = self.fields['ignores_element'].var.get()
        ability.properties['guaranteed_survive'] = self.fields['guaranteed_survive'].var.get()
        ability.properties['counter_attack'] = self.fields['counter_attack'].var.get()
        ability.properties['piercing'] = self.fields['piercing'].var.get()

        self.app.parser.write_file(ability, ability.file_path)
        self._populate_list()

        messagebox.showinfo("Success", f"Saved ability: {ability.properties['ability_name']}")

    def _delete_current(self):
        if not hasattr(self, 'selected_ability') or not self.selected_ability:
            messagebox.showwarning("Warning", "No ability selected")
            return

        ability = self.selected_ability
        name = ability.properties.get('ability_name', 'Unknown')

        if messagebox.askyesno("Confirm Delete", f"Delete '{name}'?"):
            try:
                os.remove(ability.file_path)
                self.app.abilities.remove(ability)
                self.selected_ability = None
                self._populate_list()
                self.editor_title.configure(text="Select an ability to edit")
                messagebox.showinfo("Success", f"Deleted: {name}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to delete: {e}")


class GearPanel(BasePanel):
    """Panel for editing gear"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        self.list_frame = ctk.CTkFrame(self, width=300, fg_color=COLORS['bg_medium'])
        self.list_frame.pack(side='left', fill='y', padx=(0, 10))
        self.list_frame.pack_propagate(False)

        self.editor_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.editor_frame.pack(side='right', fill='both', expand=True)

        header_frame = ctk.CTkFrame(self.list_frame, fg_color='transparent')
        header_frame.pack(fill='x', padx=10, pady=10)

        ctk.CTkLabel(header_frame, text="Gear", font=ctk.CTkFont(size=16, weight="bold")).pack(side='left')
        ctk.CTkButton(header_frame, text="+ New", width=60, command=self._create_new, fg_color=COLORS['success']).pack(side='right')

        self.search_var = ctk.StringVar()
        self.search_var.trace('w', lambda *args: self._filter_list())
        ctk.CTkEntry(self.list_frame, placeholder_text="Search...", textvariable=self.search_var).pack(fill='x', padx=10, pady=(0, 10))

        self.list_scroll = ctk.CTkScrollableFrame(self.list_frame, fg_color='transparent')
        self.list_scroll.pack(fill='both', expand=True, padx=5)

        self.list_items = []
        self._create_editor()

    def _create_editor(self):
        self.editor_scroll = ctk.CTkScrollableFrame(self.editor_frame, fg_color='transparent')
        self.editor_scroll.pack(fill='both', expand=True, padx=20, pady=20)

        self.editor_title = ctk.CTkLabel(self.editor_scroll, text="Select gear to edit", font=ctk.CTkFont(size=18, weight="bold"))
        self.editor_title.pack(anchor='w', pady=(0, 20))

        self.fields = {}

        self._add_section("Basic Info")
        self.fields['gear_name'] = self._add_field("Name", "entry")
        self.fields['gear_id'] = self._add_field("ID", "entry")
        self.fields['gear_type'] = self._add_field("Type", "combo", ["0 (Weapon)", "1 (Armor)", "2 (Accessory)"])
        self.fields['rarity'] = self._add_field("Rarity", "combo", ["0 (Common)", "1 (Rare)", "2 (Epic)", "3 (Legendary)"])

        self._add_section("Stats")
        self.fields['stat_type'] = self._add_field("Stat Type", "combo", ["0 (HP)", "1 (Attack)", "2 (Defense)", "3 (Speed)"])
        self.fields['is_percentage'] = self._add_field("Is Percentage", "checkbox")
        self.fields['base_value'] = self._add_field("Base Value", "entry")

        btn_frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        btn_frame.pack(fill='x', pady=20)

        ctk.CTkButton(btn_frame, text="Save", command=self._save_current, fg_color=COLORS['success']).pack(side='left', padx=(0, 10))
        ctk.CTkButton(btn_frame, text="Delete", command=self._delete_current, fg_color=COLORS['danger']).pack(side='left')

    def _add_section(self, title: str):
        ctk.CTkLabel(self.editor_scroll, text=title, font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w', pady=(15, 5))

    def _add_field(self, label: str, field_type: str, options: List[str] = None):
        frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        frame.pack(fill='x', pady=5)

        ctk.CTkLabel(frame, text=label, width=120, anchor='w').pack(side='left')

        if field_type == "entry":
            widget = ctk.CTkEntry(frame, width=200)
        elif field_type == "combo":
            widget = ctk.CTkComboBox(frame, values=options or [], width=200)
        elif field_type == "checkbox":
            var = ctk.BooleanVar()
            widget = ctk.CTkCheckBox(frame, text="", variable=var)
            widget.var = var
        else:
            widget = ctk.CTkEntry(frame, width=200)

        widget.pack(side='left', padx=(10, 0))
        return widget

    def refresh(self):
        self.app.gear = self.app.parser.get_all_gear()
        self._populate_list()

    def _populate_list(self):
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        search = self.search_var.get().lower()
        rarity_colors = ['#9ca3af', '#3b82f6', '#a855f7', '#fbbf24']

        for gear in self.app.gear:
            name = gear.properties.get('gear_name', 'Unknown')
            if search and search not in name.lower():
                continue

            rarity = gear.properties.get('rarity', 0)

            item_frame = ctk.CTkFrame(self.list_scroll, fg_color=COLORS['bg_light'], height=40)
            item_frame.pack(fill='x', pady=2)
            item_frame.pack_propagate(False)

            color_bar = ctk.CTkFrame(item_frame, width=4, fg_color=rarity_colors[rarity])
            color_bar.pack(side='left', fill='y')

            ctk.CTkLabel(item_frame, text=name, font=ctk.CTkFont(size=13), anchor='w').pack(side='left', padx=10, pady=5)

            item_frame.bind('<Button-1>', lambda e, g=gear: self._select_gear(g))
            for child in item_frame.winfo_children():
                child.bind('<Button-1>', lambda e, g=gear: self._select_gear(g))

            self.list_items.append(item_frame)

    def _filter_list(self):
        self._populate_list()

    def _select_gear(self, gear: TresResource):
        self.selected_gear = gear
        self.editor_title.configure(text=f"Editing: {gear.properties.get('gear_name', 'Unknown')}")

        self.fields['gear_name'].delete(0, 'end')
        self.fields['gear_name'].insert(0, gear.properties.get('gear_name', ''))

        self.fields['gear_id'].delete(0, 'end')
        self.fields['gear_id'].insert(0, gear.properties.get('gear_id', ''))

        gear_type = gear.properties.get('gear_type', 0)
        type_names = ['Weapon', 'Armor', 'Accessory']
        self.fields['gear_type'].set(f"{gear_type} ({type_names[gear_type]})")

        rarity = gear.properties.get('rarity', 0)
        rarity_names = ['Common', 'Rare', 'Epic', 'Legendary']
        self.fields['rarity'].set(f"{rarity} ({rarity_names[rarity]})")

        stat_type = gear.properties.get('stat_type', 0)
        stat_names = ['HP', 'Attack', 'Defense', 'Speed']
        self.fields['stat_type'].set(f"{stat_type} ({stat_names[stat_type]})")

        self.fields['is_percentage'].var.set(gear.properties.get('is_percentage', False))

        self.fields['base_value'].delete(0, 'end')
        self.fields['base_value'].insert(0, str(gear.properties.get('base_value', 10.0)))

    def _create_new(self):
        new_gear = TresResource()
        new_gear.resource_type = "Resource"
        new_gear.script_class = "GearData"
        new_gear.uid = self.app.parser.generate_uid("gear")

        new_gear.ext_resources = {
            '1_script': {'type': 'Script', 'uid': '', 'path': 'res://scripts/data/gear_data.gd'}
        }

        new_gear.properties = {
            'script': {'type': 'ExtResource', 'id': '1_script'},
            'gear_id': f'new_gear_{len(self.app.gear) + 1:03d}',
            'gear_name': 'New Gear',
            'gear_type': 0,
            'rarity': 0,
            'stat_type': 1,
            'is_percentage': False,
            'base_value': 10.0
        }

        filename = f"{new_gear.properties['gear_id']}.tres"
        filepath = os.path.join(self.app.game_root, 'resources', 'gear', filename)
        new_gear.file_path = filepath

        self.app.parser.write_file(new_gear, filepath)
        self.app.gear.append(new_gear)
        self._populate_list()
        self._select_gear(new_gear)

        messagebox.showinfo("Success", f"Created new gear: {filename}")

    def _save_current(self):
        if not hasattr(self, 'selected_gear') or not self.selected_gear:
            messagebox.showwarning("Warning", "No gear selected")
            return

        gear = self.selected_gear
        gear.properties['gear_name'] = self.fields['gear_name'].get()
        gear.properties['gear_id'] = self.fields['gear_id'].get()
        gear.properties['gear_type'] = int(self.fields['gear_type'].get().split()[0])
        gear.properties['rarity'] = int(self.fields['rarity'].get().split()[0])
        gear.properties['stat_type'] = int(self.fields['stat_type'].get().split()[0])
        gear.properties['is_percentage'] = self.fields['is_percentage'].var.get()
        gear.properties['base_value'] = float(self.fields['base_value'].get())

        self.app.parser.write_file(gear, gear.file_path)
        self._populate_list()

        messagebox.showinfo("Success", f"Saved gear: {gear.properties['gear_name']}")

    def _delete_current(self):
        if not hasattr(self, 'selected_gear') or not self.selected_gear:
            messagebox.showwarning("Warning", "No gear selected")
            return

        gear = self.selected_gear
        name = gear.properties.get('gear_name', 'Unknown')

        if messagebox.askyesno("Confirm Delete", f"Delete '{name}'?"):
            try:
                os.remove(gear.file_path)
                self.app.gear.remove(gear)
                self.selected_gear = None
                self._populate_list()
                self.editor_title.configure(text="Select gear to edit")
                messagebox.showinfo("Success", f"Deleted: {name}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to delete: {e}")


class StagesPanel(BasePanel):
    """Panel for editing stages"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        self.list_frame = ctk.CTkFrame(self, width=300, fg_color=COLORS['bg_medium'])
        self.list_frame.pack(side='left', fill='y', padx=(0, 10))
        self.list_frame.pack_propagate(False)

        self.editor_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.editor_frame.pack(side='right', fill='both', expand=True)

        header_frame = ctk.CTkFrame(self.list_frame, fg_color='transparent')
        header_frame.pack(fill='x', padx=10, pady=10)

        ctk.CTkLabel(header_frame, text="Stages", font=ctk.CTkFont(size=16, weight="bold")).pack(side='left')
        ctk.CTkButton(header_frame, text="+ New", width=60, command=self._create_new, fg_color=COLORS['success']).pack(side='right')

        self.list_scroll = ctk.CTkScrollableFrame(self.list_frame, fg_color='transparent')
        self.list_scroll.pack(fill='both', expand=True, padx=5)

        self.list_items = []
        self._create_editor()

    def _create_editor(self):
        self.editor_scroll = ctk.CTkScrollableFrame(self.editor_frame, fg_color='transparent')
        self.editor_scroll.pack(fill='both', expand=True, padx=20, pady=20)

        self.editor_title = ctk.CTkLabel(self.editor_scroll, text="Select a stage to edit", font=ctk.CTkFont(size=18, weight="bold"))
        self.editor_title.pack(anchor='w', pady=(0, 20))

        self.fields = {}

        self._add_section("Basic Info")
        self.fields['stage_id'] = self._add_field("Stage ID", "entry")
        self.fields['stage_name'] = self._add_field("Name", "entry")
        self.fields['chapter'] = self._add_field("Chapter", "entry")
        self.fields['stage_number'] = self._add_field("Stage Number", "entry")
        self.fields['difficulty'] = self._add_field("Difficulty (1-5)", "entry")
        self.fields['enemy_level'] = self._add_field("Enemy Level", "entry")

        self._add_section("Rewards")
        self.fields['gem_reward'] = self._add_field("Gem Reward", "entry")
        self.fields['gold_reward'] = self._add_field("Gold Reward", "entry")
        self.fields['material_reward'] = self._add_field("Material Reward", "entry")
        self.fields['xp_reward'] = self._add_field("XP Reward", "entry")

        btn_frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        btn_frame.pack(fill='x', pady=20)

        ctk.CTkButton(btn_frame, text="Save", command=self._save_current, fg_color=COLORS['success']).pack(side='left', padx=(0, 10))
        ctk.CTkButton(btn_frame, text="Delete", command=self._delete_current, fg_color=COLORS['danger']).pack(side='left')

    def _add_section(self, title: str):
        ctk.CTkLabel(self.editor_scroll, text=title, font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w', pady=(15, 5))

    def _add_field(self, label: str, field_type: str, options: List[str] = None):
        frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        frame.pack(fill='x', pady=5)

        ctk.CTkLabel(frame, text=label, width=120, anchor='w').pack(side='left')

        if field_type == "entry":
            widget = ctk.CTkEntry(frame, width=200)
        elif field_type == "combo":
            widget = ctk.CTkComboBox(frame, values=options or [], width=200)
        else:
            widget = ctk.CTkEntry(frame, width=200)

        widget.pack(side='left', padx=(10, 0))
        return widget

    def refresh(self):
        self.app.stages = self.app.parser.get_all_stages()
        self._populate_list()

    def _populate_list(self):
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        # Sort stages by chapter and number
        sorted_stages = sorted(self.app.stages, key=lambda s: (s.properties.get('chapter', 1), s.properties.get('stage_number', 1)))

        for stage in sorted_stages:
            stage_id = stage.properties.get('stage_id', '?-?')
            name = stage.properties.get('stage_name', 'Unknown')

            item_frame = ctk.CTkFrame(self.list_scroll, fg_color=COLORS['bg_light'], height=40)
            item_frame.pack(fill='x', pady=2)
            item_frame.pack_propagate(False)

            ctk.CTkLabel(item_frame, text=f"{stage_id}: {name}", font=ctk.CTkFont(size=13), anchor='w').pack(side='left', padx=10, pady=5)

            item_frame.bind('<Button-1>', lambda e, s=stage: self._select_stage(s))
            for child in item_frame.winfo_children():
                child.bind('<Button-1>', lambda e, s=stage: self._select_stage(s))

            self.list_items.append(item_frame)

    def _select_stage(self, stage: TresResource):
        self.selected_stage = stage
        self.editor_title.configure(text=f"Editing: {stage.properties.get('stage_id', '?')}")

        self.fields['stage_id'].delete(0, 'end')
        self.fields['stage_id'].insert(0, stage.properties.get('stage_id', ''))

        self.fields['stage_name'].delete(0, 'end')
        self.fields['stage_name'].insert(0, stage.properties.get('stage_name', ''))

        self.fields['chapter'].delete(0, 'end')
        self.fields['chapter'].insert(0, str(stage.properties.get('chapter', 1)))

        self.fields['stage_number'].delete(0, 'end')
        self.fields['stage_number'].insert(0, str(stage.properties.get('stage_number', 1)))

        self.fields['difficulty'].delete(0, 'end')
        self.fields['difficulty'].insert(0, str(stage.properties.get('difficulty', 1)))

        self.fields['enemy_level'].delete(0, 'end')
        self.fields['enemy_level'].insert(0, str(stage.properties.get('enemy_level', 1)))

        self.fields['gem_reward'].delete(0, 'end')
        self.fields['gem_reward'].insert(0, str(stage.properties.get('gem_reward', 50)))

        self.fields['gold_reward'].delete(0, 'end')
        self.fields['gold_reward'].insert(0, str(stage.properties.get('gold_reward', 100)))

        self.fields['material_reward'].delete(0, 'end')
        self.fields['material_reward'].insert(0, str(stage.properties.get('material_reward', 5)))

        self.fields['xp_reward'].delete(0, 'end')
        self.fields['xp_reward'].insert(0, str(stage.properties.get('xp_reward', 30)))

    def _create_new(self):
        # Find next stage number
        max_stage = 0
        for stage in self.app.stages:
            if stage.properties.get('chapter') == 1:
                max_stage = max(max_stage, stage.properties.get('stage_number', 0))

        new_stage = TresResource()
        new_stage.resource_type = "Resource"
        new_stage.script_class = "StageData"
        new_stage.uid = self.app.parser.generate_uid("stage")

        new_stage.ext_resources = {
            '1_script': {'type': 'Script', 'uid': '', 'path': 'res://scripts/data/stage_data.gd'}
        }

        stage_num = max_stage + 1
        new_stage.properties = {
            'script': {'type': 'ExtResource', 'id': '1_script'},
            'stage_id': f'1-{stage_num}',
            'stage_name': f'New Stage {stage_num}',
            'chapter': 1,
            'stage_number': stage_num,
            'story_intro': 'A new challenge awaits...',
            'story_outro': 'Victory!',
            'enemy_units': {'type': 'Array', 'element_type': 'Resource', 'items': []},
            'enemy_level': 1,
            'difficulty': 1,
            'gem_reward': 50,
            'gold_reward': 100,
            'material_reward': 5,
            'xp_reward': 30,
            'first_clear_unit': None
        }

        # Ensure chapter folder exists
        chapter_path = os.path.join(self.app.game_root, 'resources', 'stages', 'chapter_1')
        os.makedirs(chapter_path, exist_ok=True)

        filename = f"stage_1_{stage_num}.tres"
        filepath = os.path.join(chapter_path, filename)
        new_stage.file_path = filepath

        self.app.parser.write_file(new_stage, filepath)
        self.app.stages.append(new_stage)
        self._populate_list()
        self._select_stage(new_stage)

        messagebox.showinfo("Success", f"Created new stage: {filename}")

    def _save_current(self):
        if not hasattr(self, 'selected_stage') or not self.selected_stage:
            messagebox.showwarning("Warning", "No stage selected")
            return

        stage = self.selected_stage
        stage.properties['stage_id'] = self.fields['stage_id'].get()
        stage.properties['stage_name'] = self.fields['stage_name'].get()
        stage.properties['chapter'] = int(self.fields['chapter'].get())
        stage.properties['stage_number'] = int(self.fields['stage_number'].get())
        stage.properties['difficulty'] = int(self.fields['difficulty'].get())
        stage.properties['enemy_level'] = int(self.fields['enemy_level'].get())
        stage.properties['gem_reward'] = int(self.fields['gem_reward'].get())
        stage.properties['gold_reward'] = int(self.fields['gold_reward'].get())
        stage.properties['material_reward'] = int(self.fields['material_reward'].get())
        stage.properties['xp_reward'] = int(self.fields['xp_reward'].get())

        self.app.parser.write_file(stage, stage.file_path)
        self._populate_list()

        messagebox.showinfo("Success", f"Saved stage: {stage.properties['stage_id']}")

    def _delete_current(self):
        if not hasattr(self, 'selected_stage') or not self.selected_stage:
            messagebox.showwarning("Warning", "No stage selected")
            return

        stage = self.selected_stage
        stage_id = stage.properties.get('stage_id', 'Unknown')

        if messagebox.askyesno("Confirm Delete", f"Delete stage '{stage_id}'?"):
            try:
                os.remove(stage.file_path)
                self.app.stages.remove(stage)
                self.selected_stage = None
                self._populate_list()
                self.editor_title.configure(text="Select a stage to edit")
                messagebox.showinfo("Success", f"Deleted: {stage_id}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to delete: {e}")


class DungeonsPanel(BasePanel):
    """Panel for editing dungeons"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        self.list_frame = ctk.CTkFrame(self, width=300, fg_color=COLORS['bg_medium'])
        self.list_frame.pack(side='left', fill='y', padx=(0, 10))
        self.list_frame.pack_propagate(False)

        self.editor_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.editor_frame.pack(side='right', fill='both', expand=True)

        header_frame = ctk.CTkFrame(self.list_frame, fg_color='transparent')
        header_frame.pack(fill='x', padx=10, pady=10)

        ctk.CTkLabel(header_frame, text="Dungeons", font=ctk.CTkFont(size=16, weight="bold")).pack(side='left')
        ctk.CTkButton(header_frame, text="+ New", width=60, command=self._create_new, fg_color=COLORS['success']).pack(side='right')

        self.list_scroll = ctk.CTkScrollableFrame(self.list_frame, fg_color='transparent')
        self.list_scroll.pack(fill='both', expand=True, padx=5)

        self.list_items = []
        self._create_editor()

    def _create_editor(self):
        self.editor_scroll = ctk.CTkScrollableFrame(self.editor_frame, fg_color='transparent')
        self.editor_scroll.pack(fill='both', expand=True, padx=20, pady=20)

        self.editor_title = ctk.CTkLabel(self.editor_scroll, text="Select a dungeon to edit", font=ctk.CTkFont(size=18, weight="bold"))
        self.editor_title.pack(anchor='w', pady=(0, 20))

        self.fields = {}

        self._add_section("Basic Info")
        self.fields['dungeon_id'] = self._add_field("ID", "entry")
        self.fields['dungeon_name'] = self._add_field("Name", "entry")
        self.fields['description'] = self._add_field("Description", "entry")
        self.fields['drops_stat_type'] = self._add_field("Drops Stat", "combo", ["0 (HP)", "1 (Attack)", "2 (Defense)", "3 (Speed)"])

        btn_frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        btn_frame.pack(fill='x', pady=20)

        ctk.CTkButton(btn_frame, text="Save", command=self._save_current, fg_color=COLORS['success']).pack(side='left', padx=(0, 10))
        ctk.CTkButton(btn_frame, text="Delete", command=self._delete_current, fg_color=COLORS['danger']).pack(side='left')

    def _add_section(self, title: str):
        ctk.CTkLabel(self.editor_scroll, text=title, font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w', pady=(15, 5))

    def _add_field(self, label: str, field_type: str, options: List[str] = None):
        frame = ctk.CTkFrame(self.editor_scroll, fg_color='transparent')
        frame.pack(fill='x', pady=5)

        ctk.CTkLabel(frame, text=label, width=120, anchor='w').pack(side='left')

        if field_type == "entry":
            widget = ctk.CTkEntry(frame, width=300)
        elif field_type == "combo":
            widget = ctk.CTkComboBox(frame, values=options or [], width=200)
        else:
            widget = ctk.CTkEntry(frame, width=300)

        widget.pack(side='left', padx=(10, 0))
        return widget

    def refresh(self):
        self.app.dungeons = self.app.parser.get_all_dungeons()
        self._populate_list()

    def _populate_list(self):
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        stat_colors = ['#4ade80', '#f87171', '#60a5fa', '#facc15']

        for dungeon in self.app.dungeons:
            name = dungeon.properties.get('dungeon_name', 'Unknown')
            stat_type = dungeon.properties.get('drops_stat_type', 0)

            item_frame = ctk.CTkFrame(self.list_scroll, fg_color=COLORS['bg_light'], height=40)
            item_frame.pack(fill='x', pady=2)
            item_frame.pack_propagate(False)

            color_bar = ctk.CTkFrame(item_frame, width=4, fg_color=stat_colors[stat_type])
            color_bar.pack(side='left', fill='y')

            ctk.CTkLabel(item_frame, text=name, font=ctk.CTkFont(size=13), anchor='w').pack(side='left', padx=10, pady=5)

            item_frame.bind('<Button-1>', lambda e, d=dungeon: self._select_dungeon(d))
            for child in item_frame.winfo_children():
                child.bind('<Button-1>', lambda e, d=dungeon: self._select_dungeon(d))

            self.list_items.append(item_frame)

    def _select_dungeon(self, dungeon: TresResource):
        self.selected_dungeon = dungeon
        self.editor_title.configure(text=f"Editing: {dungeon.properties.get('dungeon_name', 'Unknown')}")

        self.fields['dungeon_id'].delete(0, 'end')
        self.fields['dungeon_id'].insert(0, dungeon.properties.get('dungeon_id', ''))

        self.fields['dungeon_name'].delete(0, 'end')
        self.fields['dungeon_name'].insert(0, dungeon.properties.get('dungeon_name', ''))

        self.fields['description'].delete(0, 'end')
        self.fields['description'].insert(0, dungeon.properties.get('description', ''))

        stat_type = dungeon.properties.get('drops_stat_type', 0)
        stat_names = ['HP', 'Attack', 'Defense', 'Speed']
        self.fields['drops_stat_type'].set(f"{stat_type} ({stat_names[stat_type]})")

    def _create_new(self):
        new_dungeon = TresResource()
        new_dungeon.resource_type = "Resource"
        new_dungeon.script_class = "DungeonData"
        new_dungeon.uid = self.app.parser.generate_uid("dungeon")

        new_dungeon.ext_resources = {
            '1_script': {'type': 'Script', 'uid': '', 'path': 'res://scripts/data/dungeon_data.gd'}
        }

        new_dungeon.properties = {
            'script': {'type': 'ExtResource', 'id': '1_script'},
            'dungeon_id': f'new_dungeon_{len(self.app.dungeons) + 1}',
            'dungeon_name': 'New Dungeon',
            'description': 'A new dungeon to explore.',
            'drops_stat_type': 1,
            'enemy_units': {'type': 'Array', 'element_type': 'Resource', 'items': []},
            'tier_enemy_levels': [3, 6, 10],
            'tier_names': ['Easy', 'Normal', 'Hard']
        }

        filename = f"{new_dungeon.properties['dungeon_id']}.tres"
        filepath = os.path.join(self.app.game_root, 'resources', 'dungeons', filename)
        new_dungeon.file_path = filepath

        self.app.parser.write_file(new_dungeon, filepath)
        self.app.dungeons.append(new_dungeon)
        self._populate_list()
        self._select_dungeon(new_dungeon)

        messagebox.showinfo("Success", f"Created new dungeon: {filename}")

    def _save_current(self):
        if not hasattr(self, 'selected_dungeon') or not self.selected_dungeon:
            messagebox.showwarning("Warning", "No dungeon selected")
            return

        dungeon = self.selected_dungeon
        dungeon.properties['dungeon_id'] = self.fields['dungeon_id'].get()
        dungeon.properties['dungeon_name'] = self.fields['dungeon_name'].get()
        dungeon.properties['description'] = self.fields['description'].get()
        dungeon.properties['drops_stat_type'] = int(self.fields['drops_stat_type'].get().split()[0])

        self.app.parser.write_file(dungeon, dungeon.file_path)
        self._populate_list()

        messagebox.showinfo("Success", f"Saved dungeon: {dungeon.properties['dungeon_name']}")

    def _delete_current(self):
        if not hasattr(self, 'selected_dungeon') or not self.selected_dungeon:
            messagebox.showwarning("Warning", "No dungeon selected")
            return

        dungeon = self.selected_dungeon
        name = dungeon.properties.get('dungeon_name', 'Unknown')

        if messagebox.askyesno("Confirm Delete", f"Delete '{name}'?"):
            try:
                os.remove(dungeon.file_path)
                self.app.dungeons.remove(dungeon)
                self.selected_dungeon = None
                self._populate_list()
                self.editor_title.configure(text="Select a dungeon to edit")
                messagebox.showinfo("Success", f"Deleted: {name}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to delete: {e}")


class AssetsPanel(BasePanel):
    """Panel for managing game assets"""

    def __init__(self, parent, app: ContentEditor):
        super().__init__(parent, app)
        self._create_ui()

    def _create_ui(self):
        # Left side - asset browser
        self.browser_frame = ctk.CTkFrame(self, width=350, fg_color=COLORS['bg_medium'])
        self.browser_frame.pack(side='left', fill='y', padx=(0, 10))
        self.browser_frame.pack_propagate(False)

        ctk.CTkLabel(self.browser_frame, text="Asset Browser", font=ctk.CTkFont(size=16, weight="bold")).pack(pady=10)

        # Asset type selector
        self.asset_type = ctk.CTkComboBox(
            self.browser_frame,
            values=["Unit Sprites", "Board Assets", "UI Images"],
            command=self._on_asset_type_change
        )
        self.asset_type.set("Unit Sprites")
        self.asset_type.pack(fill='x', padx=10, pady=10)

        # Asset list
        self.asset_list = ctk.CTkScrollableFrame(self.browser_frame, fg_color='transparent')
        self.asset_list.pack(fill='both', expand=True, padx=5)

        # Right side - preview and import
        self.preview_frame = ctk.CTkFrame(self, fg_color=COLORS['bg_medium'])
        self.preview_frame.pack(side='right', fill='both', expand=True)

        ctk.CTkLabel(self.preview_frame, text="Import Assets", font=ctk.CTkFont(size=16, weight="bold")).pack(pady=10)

        # Import section for unit sprites
        self.import_frame = ctk.CTkFrame(self.preview_frame, fg_color='transparent')
        self.import_frame.pack(fill='x', padx=20, pady=10)

        ctk.CTkLabel(self.import_frame, text="Import Unit Sprite", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w')

        # Unit selector
        unit_frame = ctk.CTkFrame(self.import_frame, fg_color='transparent')
        unit_frame.pack(fill='x', pady=5)
        ctk.CTkLabel(unit_frame, text="Unit:", width=80, anchor='w').pack(side='left')
        self.unit_selector = ctk.CTkComboBox(unit_frame, values=[], width=200)
        self.unit_selector.pack(side='left', padx=10)

        # Animation type
        anim_frame = ctk.CTkFrame(self.import_frame, fg_color='transparent')
        anim_frame.pack(fill='x', pady=5)
        ctk.CTkLabel(anim_frame, text="Animation:", width=80, anchor='w').pack(side='left')
        self.anim_selector = ctk.CTkComboBox(anim_frame, values=["idle", "attack", "hurt"], width=200)
        self.anim_selector.set("idle")
        self.anim_selector.pack(side='left', padx=10)

        # Import button
        ctk.CTkButton(
            self.import_frame,
            text="Select Image File...",
            command=self._import_sprite,
            fg_color=COLORS['primary']
        ).pack(pady=10)

        # Board asset import
        board_frame = ctk.CTkFrame(self.preview_frame, fg_color='transparent')
        board_frame.pack(fill='x', padx=20, pady=20)

        ctk.CTkLabel(board_frame, text="Import Board Asset", font=ctk.CTkFont(size=14, weight="bold"), text_color=COLORS['primary']).pack(anchor='w')

        self.board_type = ctk.CTkComboBox(board_frame, values=["background", "overlay"], width=200)
        self.board_type.set("background")
        self.board_type.pack(pady=5)

        ctk.CTkButton(
            board_frame,
            text="Select Board Image...",
            command=self._import_board_asset,
            fg_color=COLORS['primary']
        ).pack(pady=5)

        # Preview area
        self.preview_label = ctk.CTkLabel(
            self.preview_frame,
            text="Preview will appear here",
            width=300,
            height=300,
            fg_color=COLORS['bg_light']
        )
        self.preview_label.pack(pady=20)

        self.list_items = []

    def refresh(self):
        self._update_unit_list()
        self._refresh_asset_list()

    def _update_unit_list(self):
        unit_ids = [u.properties.get('unit_id', 'unknown') for u in self.app.units]
        self.unit_selector.configure(values=unit_ids)
        if unit_ids:
            self.unit_selector.set(unit_ids[0])

    def _on_asset_type_change(self, value):
        self._refresh_asset_list()

    def _refresh_asset_list(self):
        for item in self.list_items:
            item.destroy()
        self.list_items.clear()

        asset_type = self.asset_type.get()

        if asset_type == "Unit Sprites":
            sprites_path = os.path.join(self.app.game_root, 'assets', 'units', 'ai_sprites')
            if os.path.exists(sprites_path):
                for unit_folder in os.listdir(sprites_path):
                    unit_path = os.path.join(sprites_path, unit_folder)
                    if os.path.isdir(unit_path):
                        item = ctk.CTkFrame(self.asset_list, fg_color=COLORS['bg_light'], height=35)
                        item.pack(fill='x', pady=2)
                        item.pack_propagate(False)

                        files = os.listdir(unit_path)
                        ctk.CTkLabel(item, text=f"{unit_folder} ({len(files)} files)", anchor='w').pack(side='left', padx=10, pady=5)
                        self.list_items.append(item)

        elif asset_type == "Board Assets":
            board_path = os.path.join(self.app.game_root, 'assets', 'board')
            if os.path.exists(board_path):
                for filename in os.listdir(board_path):
                    if filename.endswith(('.png', '.jpg')):
                        item = ctk.CTkFrame(self.asset_list, fg_color=COLORS['bg_light'], height=35)
                        item.pack(fill='x', pady=2)
                        item.pack_propagate(False)

                        ctk.CTkLabel(item, text=filename, anchor='w').pack(side='left', padx=10, pady=5)
                        self.list_items.append(item)

    def _import_sprite(self):
        unit_id = self.unit_selector.get()
        anim_type = self.anim_selector.get()

        if not unit_id:
            messagebox.showwarning("Warning", "Please select a unit")
            return

        filepath = filedialog.askopenfilename(
            title="Select Sprite Image",
            filetypes=[("Image files", "*.png *.jpg *.jpeg"), ("All files", "*.*")]
        )

        if filepath:
            # Create destination folder
            dest_folder = os.path.join(self.app.game_root, 'assets', 'units', 'ai_sprites', unit_id)
            os.makedirs(dest_folder, exist_ok=True)

            # Copy file
            dest_path = os.path.join(dest_folder, f"{anim_type}.png")
            shutil.copy2(filepath, dest_path)

            self._refresh_asset_list()
            messagebox.showinfo("Success", f"Imported sprite: {unit_id}/{anim_type}.png")

    def _import_board_asset(self):
        board_type = self.board_type.get()

        filepath = filedialog.askopenfilename(
            title="Select Board Image",
            filetypes=[("Image files", "*.png *.jpg *.jpeg"), ("All files", "*.*")]
        )

        if filepath:
            dest_folder = os.path.join(self.app.game_root, 'assets', 'board')
            os.makedirs(dest_folder, exist_ok=True)

            filename = os.path.basename(filepath)
            dest_path = os.path.join(dest_folder, filename)
            shutil.copy2(filepath, dest_path)

            self._refresh_asset_list()
            messagebox.showinfo("Success", f"Imported board asset: {filename}")


if __name__ == "__main__":
    app = ContentEditor()
    app.mainloop()
