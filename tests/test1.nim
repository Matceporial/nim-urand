#test1.nim
import urand

var ur: Urand


ur.open()

echo ur.urand(16)

ur.close()