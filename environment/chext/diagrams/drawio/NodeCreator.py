from xml.etree import ElementTree
import abc
import dataclasses
from typing import Any, Dict


class NodeCreator(abc.ABC):
    @abc.abstractmethod
    def create_node(self, parent: ElementTree.Element) -> None:
        ...


def dc_to_elem(parent: ElementTree.Element, tag: str, dc: Any) -> ElementTree.Element:
    assert (dataclasses.is_dataclass(dc))

    attrib = {}

    for field in dataclasses.fields(dc):
        name: str = field.name

        # TODO: Make sure that this is correct (i.e., checking if dict-like)
        if (type(field.metadata).__name__ == "mappingproxy"):
            metadata: Dict = field.metadata

            if (metadata.get("skip", False)):
                continue

            name = metadata.get("name", field.name)

        attrib[name] = str(getattr(dc, field.name))

    return ElementTree.SubElement(parent, tag, attrib)


def dc_skipped():
    return dataclasses.field(default=None, metadata={"skip": True})


def dc_name(name: str):
    return dataclasses.field(default=None, metadata={"name": name})


__all__ = [
    "NodeCreator", "dc_name", "dc_skipped", "dc_to_elem"
]
