# Urand

Cryptographic-quality random bytes from your operating system
Extracted and adapted from [urandom.nim from nim-random by Oleh Prypin](https://github.com/oprypin/nim-random/blob/master/src/random/urandom.nim "random/urandom.nim")

**WARNING: untested on Windows**, but it should work there

### API:
```nim
type Urand* = object
  when defined(windows):
    cryptProv: HCRYPTPROV = 0
  else:
    ufile: File
# Contains the ``/dev/urandom`` file handle or, if on windows, some kind of marker, it seems

proc open*(r: var Urand)
# Opens /dev/urandom, or, on Windows, does some kind of initalization.
# Raises OSError on failure.

proc close*(r: var Urand)
# Closes /dev/urandom when not on Windows

proc urand*(r: var Urand, size: Natural): seq[uint8]
proc urand*(r: var Urand, size: static[Natural]): array[size, uint8]
# Returns a random array[size, uint8] or seq of random uint8 generated using the operating system's cryptographic source.
# Raises OSError on failure.
```

### Example:
```nim
#test1.nim
import urand

var ur: Urand


ur.open()

echo ur.urand(16)

ur.close()
```

### License: MIT (see LICENSE.txt)