print(States)
print('======')

firstKey = list(Reduce.keys())[0]
for k in Reduce[firstKey]:
    print(k,Reduce[firstKey][k],States[list(Reduce.keys())[0]][k])
