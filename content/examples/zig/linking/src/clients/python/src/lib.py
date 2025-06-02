from ctypes import CDLL
from pathlib import Path
def _load_lib():
    """ Loads the library, assumes the host machine platform. """
    path = Path(__file__).parent.parent.parent / "lib" / "x86_64-linux-gnu.2.27/libadd.so"
    return CDLL(str(path))

lib = _load_lib()
