from .Shape import *
from typing import *
import json
from xml.etree import ElementTree


def shape_to_dict(shape: Shape) -> Dict[str, Any]:
    d = {
        "w": shape.size.w,
        "h": shape.size.h,
        "aspect": shape.aspect,
        "title": shape.title
    }

    mxGraphModel = ElementTree.Element("mxGraphModel")
    root = ElementTree.SubElement(mxGraphModel, "root")
    mxCell0 = ElementTree.SubElement(
        root, "mxCell", {"id": "0"}
    )
    mxCell1 = ElementTree.SubElement(
        root, "mxCell", {"id": "1", "parent": "0"}
    )
    object = ElementTree.SubElement(
        root, "object", {"showType": "1", "id": "2"}
    )
    mxCell2 = ElementTree.SubElement(
        object,
        "mxCell",
        {
            "parent": "1",
            "vertex": "1",

            # .decode to convert UTF-8 bytes --> str
            "style": f"shape=stencil({shape.encode().decode()});whiteSpace=wrap;html=1;container=0;"
        }
    )
    mxGeometry = ElementTree.SubElement(
        mxCell2,
        "mxGeometry",
        {
            "width": str(shape.size.w),
            "height": str(shape.size.h),
            "as": "geometry"
        }
    )

    d["xml"] = ElementTree.tostring(mxGraphModel).decode()

    return d


class ShapeLibrary:
    def __init__(self) -> None:
        self._shapes: List[Shape] = []

    @property
    def shapes(self) -> List[Shape]:
        return self._shapes

    def from_str():
        raise NotImplementedError("Decoding shape libraries is not supported.")

    def to_str(self) -> str:
        json_str = json.dumps(list(map(shape_to_dict, self.shapes)))
        mxlibrary = ElementTree.Element("mxlibrary")
        mxlibrary.text = json_str
        return ElementTree.tostring(mxlibrary).decode()
