# NOTE only in `json.py`, we use snake case. for all the other files, we use the
# # camelCase for consistency with the scala library.

from dataclasses import dataclass
from typing import Dict, Callable, TypeVar, Type, List, Optional, Union, Tuple
import warnings
import dataclasses
import dataclasses_json
import json
import abc

__all__ = [
    "Registry",
    "TypedObject",
    "to_dict",
    "to_json",
    "from_dict",
    "from_json",
    "register_dataclass_adv",
    "register_dataclass",
    "dataclass"
]

T = TypeVar('T')
TT = TypeVar('TT')


_type2str: Dict[type, str] = {}
_str2type: Dict[str, type] = {
    "scala.Int": int,
    "scala.Long": int,
    "scala.math.BigInt": int,
    "scala.Double": float,
    "scala.Float": float,
    "java.lang.String": str,
    "int": int,
    "str": str,
    "dict": dict,
    "list": list,
    "tuple": tuple
}


class Registry:
    @staticmethod
    def register_type2str(t: type, s: str) -> None:
        if t in _type2str:
            raise KeyError(f"type '{t.__qualname__}' is already registred!")

        _type2str[t] = s

    @staticmethod
    def register_str2type(s: str, t: type) -> None:
        if s in _str2type:
            raise KeyError(f"string '{s}' is already registred!")

        _str2type[s] = t

    @staticmethod
    def register(t: type, s: str = None) -> None:
        if s is None:
            s = t.__qualname__

        Registry.register_type2str(t, s)
        Registry.register_str2type(s, t)


def register_dataclass_adv(
        s: Optional[str] = None,
        aliases: Optional[List[str]] = None
) -> Callable[[Type[T]], Type[T]]:
    def wrap(cls: Type[TT]) -> Type[TT]:
        # NOTE warning: relies on a private API
        cls.__init__ = dataclasses_json.utils._handle_undefined_parameters_safe(
            cls, kvs=(), usage="init"
        )
        Registry.register(
            cls,
            s if s is not None else cls.__qualname__
        )
        if aliases is not None:
            for alias in aliases:
                Registry.register_str2type(alias, cls)
        return cls
    return wrap


def register_dataclass(cls: Type[T]) -> Type[T]:
    # NOTE warning: relies on a private API
    cls.__init__ = dataclasses_json.utils._handle_undefined_parameters_safe(
        cls, kvs=(), usage="init"
    )
    Registry.register(cls)
    return cls


def to_dict(o: object) -> dict:
    # NOTE warning: relies on a private API
    return dataclasses_json.core._asdict(o)


def to_json(
    o: object,
    *,
    skipkeys: bool = False,
    ensure_ascii: bool = True,
    check_circular: bool = True,
    allow_nan: bool = True,
    indent: Optional[Union[int, str]] = "    ",
    separators: Optional[Tuple[str, str]] = None,
    default: Optional[Callable] = None,
    sort_keys: bool = False,
    **kw
) -> str:
    # NOTE warning: relies on a private API
    return json.dumps(
        to_dict(o),
        cls=dataclasses_json.core._ExtendedEncoder,
        skipkeys=skipkeys,
        ensure_ascii=ensure_ascii,
        check_circular=check_circular,
        allow_nan=allow_nan,
        indent=indent,
        separators=separators,
        default=default,
        sort_keys=sort_keys,
        **kw
    )


def from_dict(t: Type[T], d: dict, infer_missing: bool = False) -> T:
    # NOTE warning: relies on a private API
    return dataclasses_json.core._decode_type(t, d, infer_missing)


def from_json(
    t: Type[T],
    s: str,
    *,
    parse_float=None,
    parse_int=None,
    parse_constant=None,
    infer_missing=False,
    **kw
) -> T:
    # NOTE warning: relies on a private API
    kvs = json.loads(s,
                     parse_float=parse_float,
                     parse_int=parse_int,
                     parse_constant=parse_constant,
                     **kw)
    return from_dict(t, kvs, infer_missing=infer_missing)


class TypedObject(abc.ABC):
    empty = None


class _TypedObjectUtils:
    @staticmethod
    def encoder(typedObject: TypedObject):
        if typedObject is None:
            return "null"
        else:
            t = type(typedObject)

            if not any([
                dataclasses.is_dataclass(typedObject),
                isinstance(typedObject, int),
                isinstance(typedObject, float),
                isinstance(typedObject, str),
            ]):
                # TODO I do not want to spend time on encoding
                # the type for List, Optional, ..., and
                # figuring out how to assign a type annotation to
                # a runtime object.
                raise RuntimeError(
                    "a field with type 'TypedObject' type can be "
                    "assigned only to a dataclass, int, float, or str!"
                )

            return {
                "typeName": _type2str.get(t, t.__qualname__),
                "obj": to_dict(typedObject)
            }

    @staticmethod
    def decoder(input):
        if isinstance(input, str):
            if input == "null":
                return None
            else:
                raise ValueError(
                    f"input '{input}' is not a valid TypedObject!")
        elif isinstance(input, dict):
            expectedkeys = ("typeName", "obj")
            if len(input) != len(expectedkeys):
                raise ValueError(
                    f"input must have {len(expectedkeys)} keys, not {len(input)}!")
            else:
                for expectedkey in expectedkeys:
                    if expectedkey not in input:
                        raise ValueError(
                            f"input must have '{expectedkey}' as a key!")

                typename: str = input["typeName"]
                if typename not in _str2type:
                    warnings.warn(
                        f"type '{typename}' is not registered, attempting as 'dict'!"
                    )
                    return dataclasses_json.core._decode_type(dict, input["obj"], True)
                else:
                    t: type = _str2type[typename]
                    return from_dict(t, input["obj"], True)


dataclasses_json.cfg.global_config.encoders[TypedObject] = _TypedObjectUtils.encoder
dataclasses_json.cfg.global_config.decoders[TypedObject] = _TypedObjectUtils.decoder
