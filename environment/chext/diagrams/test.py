import base64
import zlib

from urllib.parse import quote, unquote
import base64

def js_encode_uri_component(data):
    return quote(data, safe='~()*!.\'')


def js_decode_uri_component(data):
    return unquote(data)


def js_string_to_byte(data):
    return bytes(data, 'iso-8859-1')


def js_bytes_to_string(data):
    return data.decode('iso-8859-1')


def js_btoa(data):
    return base64.b64encode(data)

def js_atob(data):
    return base64.b64decode(data)

def pako_deflate(data):
    compress  = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, 15, 
        memLevel=8, strategy=zlib.Z_DEFAULT_STRATEGY)
    compressed_data = compress.compress(js_string_to_byte(js_encode_uri_component(data)))
    compressed_data += compress.flush()
    return compressed_data

def pako_deflate_raw(data):
    compress = zlib.compressobj(
        zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, -15, memLevel=8,
        strategy=zlib.Z_DEFAULT_STRATEGY)
    compressed_data = compress.compress(js_string_to_byte(data))
    compressed_data += compress.flush()
    return compressed_data

def pako_inflate(data):
    decompress = zlib.decompressobj(15)
    decompressed_data = decompress.decompress(data)
    decompressed_data += decompress.flush()
    return decompressed_data

def pako_inflate_raw(data):
    decompress = zlib.decompressobj(-15)
    decompressed_data = decompress.decompress(data)
    decompressed_data += decompress.flush()
    return decompressed_data

text = "rZTfDoIgFMafhtuGkKvbZvUajfSYLAUHVPb2occ2y2j98Y7zffA77DsMwhNbiBoIo0pUQPiaMJZBdWp2zK+8fEGNUSwLLOd9KWwNqUMtlw1kKFtn9BEuMnP9fqkKMNK1Lt8QuiItjxKepFopT5Ba2Qdn4HuYkMqfpQ3Colnf/Yo1nbEYhdo3qcCB6Q1UCdv+wV5MxqYj9oTo+AkdTZfJGL78LhSeeCU0aZ7sRXo8GH1S2csr5bIs8UGF0AGAP6oNvCHXon2fI+NuV/oMgxQeMoje5ngnlFIFCfwHwhNi/j/iI0Jaavsq/MEIAlF+Mr3RkDoVv6VOuAE="
y = js_decode_uri_component(pako_inflate_raw(js_atob(text.encode())))

print(y)

z = js_btoa(pako_deflate_raw(js_encode_uri_component(y.encode())))
print(z)

w = js_decode_uri_component(pako_inflate_raw(js_atob(z)))
print(w)
