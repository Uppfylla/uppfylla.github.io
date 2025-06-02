from lib import lib
a = 1
b = 2
for i in range(10):
    print(f"Calling add ({a*i}+{b*i}) from python {lib.zig_add(a*i,b*i)}")
