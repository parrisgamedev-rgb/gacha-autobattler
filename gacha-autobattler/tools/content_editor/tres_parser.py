"""
Godot .tres Resource File Parser
Reads and writes Godot resource files for the content editor
"""

import re
import os
from typing import Any, Dict, List, Optional
from dataclasses import dataclass, field


@dataclass
class TresResource:
    """Represents a parsed .tres resource file"""
    resource_type: str = ""
    script_class: str = ""
    uid: str = ""
    ext_resources: Dict[str, Dict[str, str]] = field(default_factory=dict)
    properties: Dict[str, Any] = field(default_factory=dict)
    file_path: str = ""


class TresParser:
    """Parser for Godot .tres resource files"""

    def __init__(self, game_root: str):
        self.game_root = game_root
        self.resources_path = os.path.join(game_root, "resources")
        self.assets_path = os.path.join(game_root, "assets")

    def parse_file(self, filepath: str) -> TresResource:
        """Parse a .tres file and return a TresResource object"""
        resource = TresResource(file_path=filepath)

        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # Parse header [gd_resource ...]
        header_match = re.search(r'\[gd_resource type="([^"]*)"(?:\s+script_class="([^"]*)")?.*?uid="([^"]*)"', content)
        if header_match:
            resource.resource_type = header_match.group(1)
            resource.script_class = header_match.group(2) or ""
            resource.uid = header_match.group(3)

        # Parse external resources [ext_resource ...]
        ext_pattern = r'\[ext_resource type="([^"]*)"(?:\s+uid="([^"]*)")?\s+path="([^"]*)"\s+id="([^"]*)"\]'
        for match in re.finditer(ext_pattern, content):
            res_type, uid, path, res_id = match.groups()
            resource.ext_resources[res_id] = {
                'type': res_type,
                'uid': uid or '',
                'path': path
            }

        # Parse [resource] section
        resource_section = re.search(r'\[resource\](.*?)$', content, re.DOTALL)
        if resource_section:
            props_text = resource_section.group(1)
            resource.properties = self._parse_properties(props_text)

        return resource

    def _parse_properties(self, text: str) -> Dict[str, Any]:
        """Parse property assignments from the [resource] section"""
        props = {}
        lines = text.strip().split('\n')

        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            # Match property = value
            match = re.match(r'(\w+)\s*=\s*(.+)$', line)
            if match:
                key = match.group(1)
                value_str = match.group(2)
                props[key] = self._parse_value(value_str)

        return props

    def _parse_value(self, value_str: str) -> Any:
        """Parse a Godot value string into Python type"""
        value_str = value_str.strip()

        # String
        if value_str.startswith('"') and value_str.endswith('"'):
            return value_str[1:-1]

        # Boolean
        if value_str == 'true':
            return True
        if value_str == 'false':
            return False

        # Null
        if value_str == 'null':
            return None

        # Integer
        if re.match(r'^-?\d+$', value_str):
            return int(value_str)

        # Float
        if re.match(r'^-?\d+\.\d+$', value_str):
            return float(value_str)

        # Color
        color_match = re.match(r'Color\(([^)]+)\)', value_str)
        if color_match:
            parts = [float(x.strip()) for x in color_match.group(1).split(',')]
            return {'type': 'Color', 'values': parts}

        # Vector2
        vec2_match = re.match(r'Vector2\(([^)]+)\)', value_str)
        if vec2_match:
            parts = [float(x.strip()) for x in vec2_match.group(1).split(',')]
            return {'type': 'Vector2', 'values': parts}

        # ExtResource reference
        ext_match = re.match(r'ExtResource\("([^"]+)"\)', value_str)
        if ext_match:
            return {'type': 'ExtResource', 'id': ext_match.group(1)}

        # Array
        array_match = re.match(r'Array\[(\w+)\]\(\[(.*)\]\)', value_str, re.DOTALL)
        if array_match:
            array_type = array_match.group(1)
            items_str = array_match.group(2).strip()
            if not items_str:
                return {'type': 'Array', 'element_type': array_type, 'items': []}
            items = self._parse_array_items(items_str)
            return {'type': 'Array', 'element_type': array_type, 'items': items}

        # Simple array without type
        if value_str.startswith('[') and value_str.endswith(']'):
            items_str = value_str[1:-1].strip()
            if not items_str:
                return []
            return self._parse_array_items(items_str)

        return value_str

    def _parse_array_items(self, items_str: str) -> List[Any]:
        """Parse array items, handling nested structures"""
        items = []
        current = ""
        depth = 0

        for char in items_str:
            if char in '([':
                depth += 1
                current += char
            elif char in ')]':
                depth -= 1
                current += char
            elif char == ',' and depth == 0:
                if current.strip():
                    items.append(self._parse_value(current.strip()))
                current = ""
            else:
                current += char

        if current.strip():
            items.append(self._parse_value(current.strip()))

        return items

    def write_file(self, resource: TresResource, filepath: str):
        """Write a TresResource to a .tres file"""
        lines = []

        # Count load_steps (1 for script + number of ext_resources)
        load_steps = 1 + len(resource.ext_resources)

        # Header
        header = f'[gd_resource type="{resource.resource_type}"'
        if resource.script_class:
            header += f' script_class="{resource.script_class}"'
        header += f' load_steps={load_steps} format=3 uid="{resource.uid}"]'
        lines.append(header)
        lines.append('')

        # External resources
        for res_id, res_info in resource.ext_resources.items():
            ext_line = f'[ext_resource type="{res_info["type"]}"'
            if res_info.get('uid'):
                ext_line += f' uid="{res_info["uid"]}"'
            ext_line += f' path="{res_info["path"]}" id="{res_id}"]'
            lines.append(ext_line)

        if resource.ext_resources:
            lines.append('')

        # Resource section
        lines.append('[resource]')

        # Always put script first if it exists
        if 'script' not in resource.properties:
            lines.append('script = ExtResource("1_script")')

        for key, value in resource.properties.items():
            value_str = self._serialize_value(value)
            lines.append(f'{key} = {value_str}')

        lines.append('')

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

    def _serialize_value(self, value: Any) -> str:
        """Convert a Python value to Godot format string"""
        if value is None:
            return 'null'

        if isinstance(value, bool):
            return 'true' if value else 'false'

        if isinstance(value, int):
            return str(value)

        if isinstance(value, float):
            return str(value)

        if isinstance(value, str):
            return f'"{value}"'

        if isinstance(value, dict):
            if value.get('type') == 'Color':
                vals = ', '.join(str(v) for v in value['values'])
                return f'Color({vals})'

            if value.get('type') == 'Vector2':
                vals = ', '.join(str(v) for v in value['values'])
                return f'Vector2({vals})'

            if value.get('type') == 'ExtResource':
                return f'ExtResource("{value["id"]}")'

            if value.get('type') == 'Array':
                element_type = value.get('element_type', 'Resource')
                items = value.get('items', [])
                items_str = ', '.join(self._serialize_value(item) for item in items)
                return f'Array[{element_type}]([{items_str}])'

        if isinstance(value, list):
            items_str = ', '.join(self._serialize_value(item) for item in value)
            return f'[{items_str}]'

        return str(value)

    def get_all_units(self) -> List[TresResource]:
        """Load all unit resources"""
        units_path = os.path.join(self.resources_path, "units")
        return self._load_all_in_folder(units_path)

    def get_all_abilities(self) -> List[TresResource]:
        """Load all ability resources"""
        abilities_path = os.path.join(self.resources_path, "abilities")
        return self._load_all_in_folder(abilities_path)

    def get_all_gear(self) -> List[TresResource]:
        """Load all gear resources"""
        gear_path = os.path.join(self.resources_path, "gear")
        return self._load_all_in_folder(gear_path)

    def get_all_stages(self) -> List[TresResource]:
        """Load all stage resources from all chapters"""
        stages = []
        stages_path = os.path.join(self.resources_path, "stages")
        if os.path.exists(stages_path):
            for chapter_folder in os.listdir(stages_path):
                chapter_path = os.path.join(stages_path, chapter_folder)
                if os.path.isdir(chapter_path):
                    stages.extend(self._load_all_in_folder(chapter_path))
        return stages

    def get_all_dungeons(self) -> List[TresResource]:
        """Load all dungeon resources"""
        dungeons_path = os.path.join(self.resources_path, "dungeons")
        return self._load_all_in_folder(dungeons_path)

    def _load_all_in_folder(self, folder_path: str) -> List[TresResource]:
        """Load all .tres files in a folder"""
        resources = []
        if os.path.exists(folder_path):
            for filename in os.listdir(folder_path):
                if filename.endswith('.tres'):
                    filepath = os.path.join(folder_path, filename)
                    try:
                        resources.append(self.parse_file(filepath))
                    except Exception as e:
                        print(f"Error loading {filepath}: {e}")
        return resources

    def generate_uid(self, prefix: str = "uid") -> str:
        """Generate a unique ID for new resources"""
        import uuid
        short_id = uuid.uuid4().hex[:12]
        return f"uid://{prefix}_{short_id}"
