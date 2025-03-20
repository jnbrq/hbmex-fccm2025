from xml.etree import ElementTree
from typing import *
import dataclasses

from .NodeCreator import NodeCreator, dc_to_elem, dc_skipped, dc_name


@dataclasses.dataclass
class _Path_move(NodeCreator):
    x: float
    y: float

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "move", self)


@dataclasses.dataclass
class _Path_line(NodeCreator):
    x: float
    y: float

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "line", self)


@dataclasses.dataclass
class _Path_quad(NodeCreator):
    x1: float
    y1: float
    x2: float
    y2: float

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "quad", self)


@dataclasses.dataclass
class _Path_curve(NodeCreator):
    x1: float
    y1: float
    x2: float
    y2: float
    x3: float
    y3: float

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "curve", self)


@dataclasses.dataclass
class _Path_close(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "close", self)


@dataclasses.dataclass
class Point:
    x: float
    y: float


@dataclasses.dataclass
class Size:
    w: float
    h: float


class Path(NodeCreator):
    def __init__(self) -> None:
        self._commands: List[NodeCreator] = []

    def move(self, pt: Point) -> None:
        self._commands.append(_Path_move(pt.x, pt.y))

    def lineTo(self, pt: Point) -> None:
        self._commands.append(_Path_line(pt.x, pt.y))

    def line(self, pt1: Point, pt2: Point) -> None:
        self.move(pt1)
        self.lineTo(pt2)

    def quadTo(self, pt: Point, control: Point) -> None:
        self._commands.append(_Path_quad(control.x, control.y, pt.x, pt.y))

    def quad(self, pt1: Point, pt2: Point, control: Point) -> None:
        self.move(pt1)
        self.quadTo(pt2, control)

    def curveTo(self, pt: Point, control1: Point, control2: Point) -> None:
        self._commands.append(_Path_curve(
            control1.x, control1.y, control2.x, control2.y, pt.x, pt.y))

    def curve(self, pt1: Point, pt2: Point, control1: Point, control2: Point) -> None:
        self.move(pt1)
        self.curveTo(pt2, control1, control2)

    def close(self) -> None:
        self._commands.append(_Path_close())

    @property
    def commands(self):
        return self._commands

    def create_node(self, parent: ElementTree.Element) -> None:
        path = ElementTree.SubElement(parent, "path")
        for command in self.commands:
            command.create_node(path)


class _RectHelpers:
    @classmethod
    def corners(cls, pt1: Point, pt2: Point, arcsize: float = 0.0):
        return cls(pt1.x, pt1.y, pt2.x - pt1.x, pt2.y - pt1.y, arcsize)

    @classmethod
    def left(cls, pt: Point, sz: Size, arcsize: float = 0.0):
        return cls(pt.x, pt.y, sz.w, sz.h, arcsize)

    @classmethod
    def center(cls, pt: Point, sz: Size, arcsize: float = 0.0):
        return cls(pt.x - sz.w / 2, pt.y - sz.h / 2, sz.w, sz.h, arcsize)

    @classmethod
    def left_radius(cls, pt: Point, radius: float, arcsize: float = 0.0):
        return cls(pt.x, pt.y, radius * 2, radius * 2, arcsize)

    @classmethod
    def center_radius(cls, pt: Point, radius: float, arcsize: float = 0.0):
        return cls(pt.x - radius, pt.y - radius, radius * 2, radius * 2, arcsize)


@dataclasses.dataclass
class Rect(NodeCreator, _RectHelpers):
    x: float
    y: float
    w: float
    h: float
    arcsize: float = dc_skipped()

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "rect", self)


@dataclasses.dataclass
class RoundRect(NodeCreator, _RectHelpers):
    x: float
    y: float
    w: float
    h: float
    arcsize: float = 0.0

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "roundrect", self)


@dataclasses.dataclass
class Ellipse(NodeCreator, _RectHelpers):
    x: float
    y: float
    w: float
    h: float
    arcsize: float = dc_skipped()

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "ellipse", self)


@dataclasses.dataclass
class Label(NodeCreator):
    text: str = dc_name("str")
    x: float = 0
    y: float = 0
    align: Union[Literal["left"], Literal["right"],
                 Literal["center"]] = "center"
    valign: Union[Literal["top"], Literal["middle"],
                  Literal["bottom"]] = "middle"
    vertical: int = 0
    rotation: float = 0

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "text", self)


@dataclasses.dataclass
class FontSize(NodeCreator):
    size: float

    def create_node(self, parent: ElementTree.ElementTree) -> None:
        dc_to_elem(parent, "fontsize", self)


@dataclasses.dataclass
class FontStyle(NodeCreator):
    style: int

    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "fontstyle", self)


@dataclasses.dataclass
class Save(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "save", self)


@dataclasses.dataclass
class Restore(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "restore", self)


@dataclasses.dataclass
class Fill(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "fill", self)


@dataclasses.dataclass
class Stroke(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "stroke", self)


@dataclasses.dataclass
class FillStroke(NodeCreator):
    def create_node(self, parent: ElementTree.Element) -> None:
        dc_to_elem(parent, "fillstroke", self)


class Shape:
    def __init__(
        self,
        name: str,
        size: Size,
        aspect: Union[Literal["fixed"], Literal["variable"]] = "fixed",
        title: Optional[str] = None
    ) -> None:
        self.dc_name = name
        self._size = size
        self._aspect = aspect
        self._title = title

        self._foreground: List[NodeCreator] = []
        self._background: List[NodeCreator] = []
        self._connections: List[Point] = []

    @property
    def name(self):
        return self.dc_name

    @property
    def size(self):
        return self._size

    @property
    def aspect(self):
        return self._aspect

    @property
    def title(self):
        if self._title is not None:
            return self._title
        else:
            return self.name

    @property
    def foreground(self):
        return self._foreground

    @property
    def background(self):
        return self._background

    @property
    def connections(self):
        return self._connections

    def from_xml(self, xml: str) -> "Shape":
        print(f"Attempt to decode the XML:\n{xml}")
        raise NotImplementedError("decoding XML is not yet supported!")

    def to_xml(self) -> str:
        root = ElementTree.Element("shape", {
            "name": self.name,
            "w": str(self.size.w),
            "h": str(self.size.h),
            "aspect": self.aspect,
            "strokewidth": "inherit"
        })

        connections = ElementTree.SubElement(root, "connections")
        for pt in self.connections:
            ElementTree.SubElement(connections, "constraint", {
                "x": str(pt.x / self.size.w),
                "y": str(pt.y / self.size.h),
                "perimeter": "0"
            })

        background = ElementTree.SubElement(root, "background")
        for x in self.background:
            x.create_node(background)

        foreground = ElementTree.SubElement(root, "foreground")
        for x in self.foreground:
            x.create_node(foreground)

        ElementTree.indent(root, space="    ")
        return ElementTree.tostring(root).decode()

    @staticmethod
    def decode(b: bytes) -> "Shape":
        from .Util import js_decode_uri_component, pako_inflate_raw, js_atob
        return Shape.from_xml(js_decode_uri_component(pako_inflate_raw(js_atob(b))))

    def encode(self) -> bytes:
        from .Util import js_encode_uri_component, pako_deflate_raw, js_btoa

        xml = self.to_xml()
        return js_btoa(pako_deflate_raw(js_encode_uri_component(xml.encode())))


__all__ = [
    "Point",
    "Size",
    "Path",
    "Rect",
    "RoundRect",
    "Ellipse",
    "Label",
    "FontSize",
    "FontStyle",
    "Save",
    "Restore",
    "Fill",
    "Stroke",
    "FillStroke",
    "Shape"
]
