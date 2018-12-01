# urand
# Obtaining secure random numbers from the OS

# Extracted and adapted from urandom.nim from nim-random by Oleh Prypin
# https://github.com/oprypin/nim-random/blob/master/src/random/urandom.nim

# Copyright (C) 2014-2015 Oleh Prypin <blaxpirit@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

## **WARNING: untested on Windows**

when defined(windows):
  import winlean

  type ULONG_PTR = int
  type HCRYPTPROV = ULONG_PTR
  var PROV_RSA_FULL {.importc, header: "<windows.h>".}: DWORD
  var CRYPT_VERIFYCONTEXT {.importc, header: "<windows.h>".}: DWORD

  {.push, stdcall, dynlib: "Advapi32.dll".}

  when useWinUnicode:
    proc CryptAcquireContext(
      phProv: ptr HCRYPTPROV, pszContainer: WideCString,
      pszProvider: WideCString, dwProvType: DWORD, dwFlags: DWORD
    ): WinBool {.importc: "CryptAcquireContextW".}
  else:
    proc CryptAcquireContext(
      phProv: ptr HCRYPTPROV, pszContainer: cstring, pszProvider: cstring,
      dwProvType: DWORD, dwFlags: DWORD
    ): WinBool {.importc: "CryptAcquireContextA".}

  proc CryptGenRandom(
    hProv: HCRYPTPROV, dwLen: DWORD, pbBuffer: pointer
  ): WinBool {.importc: "CryptGenRandom".}

  {.pop.}



type Urand* = object
  ## Contains the ``/dev/urandom`` file handle or, if on windows, some kind of marker, it seems
  when defined(windows):
    cryptProv: HCRYPTPROV = 0
  else:
    ufile: File

proc open*(r: var Urand) =
  ## Opens ``/dev/urandom``, or, on Windows, does some kind of initalization.
  ## Raises ``OSError`` on failure.
  when defined(windows):
    if CryptAcquireContext(
      addr r.cryptProv, nil, nil, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT
    ) == 0:
      raise newException(OSError, "Call to CryptAcquireContext failed")
  else:
    if not r.ufile.open("/dev/urandom"):
      raise newException(OSError, "Can't open /dev/urandom")

proc close*(r: var Urand) =
  ## Closes ``/dev/urandom`` when not on Windows
  when defined(windows):
    discard
  else:
    r.ufile.close()


template urandImpl(res): untyped =
  when defined(windows):
    let success = CryptGenRandom(r.cryptProv, DWORD(size), addr res[0])
    if success == 0:
      raise newException(OSError, "Call to CryptGenRandom failed")

  else:
    var index = 0
    while index < size:
      let bytesRead = r.ufile.readBuffer(addr res[index], size-index)
      if bytesRead <= 0:
        raise newException(OSError, "Can't read enough bytes from /dev/urand")
      index += bytesRead


proc urand*(r: var Urand, size: static[Natural]): array[size, uint8] =
  ## Returns a random ``array[size, uint8]`` generated using the operating system's cryptographic source.
  ## Raises ``OSError`` on failure.
  urandImpl(result)

proc urand*(r: var Urand, size: Natural): seq[uint8] =
  ## Returns a ``seq`` of random ``uint8`` generated using the operating system's cryptographic source
  ## Raises ``OSError`` on failure.
  newSeq(result, size)
  urandImpl(result)
