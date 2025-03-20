# `hdlinfo`

A set of libraries that provide a uniform way to describe interfaces of hardware modules.
`hdlinfo` provides a JSON-based description format (with file extension `.hdlinfo.json`) that includes:

- Ports (clock, reset, data, and interrupt) and their attributes (sensitivity, etc.)
- Interfaces and their configurations
- Additional attributes of the module (like arguments and configuration)

Code generators can read and process `.hdlinfo.json` files with ease using the libraries provided in this repository.

`hdlinfo` libraries provide ways to extend JSON serialization/deserialization to user-provided types.
For example,the Python library provides the `json.TypedObject` type annotation and the user can register custom dataclasses types using `@json.register_dataclass` annotation.
This allows users to embed any kind of information that might be necessary to use in code generation.



An example `.hdlinfo.json` file looks like the following:

```json
{
  "name":"myModule",
  "ports":[
    {
      "name":"clock",
      "direction":"input",
      "kind":"clock",
      "sensitivity":"clockRising",
      "isBus":false,
      "busRange":[
        0,
        0
      ],
      "frequencyMHz":100.0,
      "associatedClock":"clock",
      "associatedReset":"reset",
      "args":{
        
      }
    },
    {
      "name":"reset",
      "direction":"input",
      "kind":"reset",
      "sensitivity":"resetActiveHigh",
      "isBus":false,
      "busRange":[
        0,
        0
      ],
      "frequencyMHz":100.0,
      "associatedClock":"clock",
      "associatedReset":"reset",
      "args":{
        
      }
    },
    {
      "name":"irq",
      "direction":"output",
      "kind":"interrupt",
      "sensitivity":"interruptRising",
      "isBus":false,
      "busRange":[
        0,
        0
      ],
      "frequencyMHz":100.0,
      "associatedClock":"clock",
      "associatedReset":"reset",
      "args":{
        
      }
    }
  ],
  "interfaces":[
    {
      "name":"s_axil_management",
      "role":"slave",
      "kind":"axi4",
      "associatedClock":"clock",
      "associatedReset":"reset",
      "args":{
        "config":{
          "typeName":"chext.amba.axi4.Config",
          "obj":{
            "wId":0,
            "wAddr":20,
            "wData":32,
            "read":true,
            "write":true,
            "lite":true,
            "wUserAR":0,
            "wUserR":0,
            "wUserAW":0,
            "wUserW":0,
            "wUserB":0
          }
        }
      }
    },
    {
      "name":"m_axi",
      "role":"master",
      "kind":"axi4",
      "associatedClock":"clock",
      "associatedReset":"reset",
      "args":{
        "config":{
          "typeName":"chext.amba.axi4.Config",
          "obj":{
            "wId":4,
            "wAddr":32,
            "wData":256,
            "read":true,
            "write":true,
            "lite":false,
            "wUserAR":0,
            "wUserR":0,
            "wUserAW":0,
            "wUserW":0,
            "wUserB":0
          }
        }
      }
    }
  ],
  "args":{
    "config":{
      "typeName":"MyModuleConfig",
      "obj":{
        "internalBufferSize":1024
      }
    }
  }
}
```
