import chext_test

chext_test.ElasticProtocol(
    "ReadStreamTask",
    "<Protocols.hpp>",
    "ReadStreamTaskSignals",
    [
        ("bits_address", "bits.address"),
        ("bits_length", "bits.length"),
        ("ready", "ready"),
        ("valid", "valid")
    ]
)

chext_test.ElasticProtocol(
    "WriteStreamTask",
    "<Protocols.hpp>",
    "WriteStreamTaskSignals",
    [
        ("bits_address", "bits.address"),
        ("bits_length", "bits.length"),
        ("ready", "ready"),
        ("valid", "valid")
    ]
)
