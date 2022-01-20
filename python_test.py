start = 0
a = 3
b = 5

for i in range(100):
    start = (((2 * start)%256 + start)%256 + b)%256
    print(start)