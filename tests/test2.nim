import urand

var ur: Urand


ur.open()

let k: array[8, uint8] = ur.urand(8)
echo k
let y = ur.urand(k[0])
echo y

ur.close()