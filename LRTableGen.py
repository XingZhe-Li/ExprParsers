from functools import cache

'''
S -> E $
E -> E + T
E -> E - T
E -> T
T -> T * F
T -> T / F
T -> F
F -> P ^ F
F -> P
P -> (E)
P -> Int
'''

Rules = {
    "S": (
        (0,"E","$")
    ),
    "E":(
        (1,"E","+","T"),
        (1,"E","-","T"),
        (0,"T",)
    ),
    "T":(
        (1,"T","*","F"),
        (1,"T","/","F"),
        (0,"F",)
    ),
    "F":(
        (1,"P","^","F"),
        (0,"P",)
    ),
    "P":(
        (0,"(","E",")"),
        (0,"Int",)
    )
}

@cache
def make_closure_sym(sym):
    if sym not in Rules:
        return tuple()
    res = set()
    for (priority,*rhs) in Rules[sym]:
        res.add((sym,(priority,*rhs),0))
        if rhs and rhs[0] != sym:
            res |= set(make_closure_sym(rhs[0]))
    return tuple(res)

@cache
def make_closure(items):
    closure = set(items)
    for _,(_,*rhs),idx in items:
        if idx >= len(rhs):
            continue
        closure |= set(make_closure_sym(rhs[idx]))
    return tuple(sorted(closure))

States = {}
Reduce = {}
StartClosure = None

# a item = ("S",("E","$"),0)
def solve(items,markStart=False):
    global StartClosure
    closure = make_closure(items)

    if markStart:
        StartClosure = closure

    if closure in States:
        return closure

    moveables = set()
    for _,(_,*rhs),idx in closure:
        if idx >= len(rhs):
            continue
        moveables.add(rhs[idx])
    
    States[closure] = {}

    for mov_sym in moveables:
        next_items = []
        
        reduced = False
        for lhs,(priority,*rhs),idx in closure:
            if idx >= len(rhs):
                continue
            if rhs[idx] == mov_sym:
                if idx == len(rhs)-1:
                    if closure not in Reduce:
                        Reduce[closure] = {}
                    Reduce[closure][mov_sym] = (len(rhs),lhs)
                    reduced = True
                else:
                    next_items.append((lhs,(priority,*rhs),idx+1))
        if not reduced: # if you want to debug reduce / shift conflict , please set this branch to always True
            next_closure = solve(tuple(next_items))
        else:
            next_closure = ()
        States[closure][mov_sym] = next_closure

    return closure

solve((("S",(0,"E","$"),0),),markStart=True)

'''
# you may test conflict revolving with codes below
# after decommenting "# if you want to debug reduce / shift conflict , please set this branch to always True"
# codes below should give an different output

print(States)
print('======')

firstKey = list(Reduce.keys())[0]
for k in Reduce[firstKey]:
    print(k,Reduce[firstKey][k],States[list(Reduce.keys())[0]][k])
'''

def mark(states,reduce):
    # converts tuple-based states to number based states
    closure_id     = 0
    closure_mapper = {}

    new_states     = {}
    for closure in states:
        if closure not in closure_mapper:
            closure_mapper[closure] = closure_id
            closure_id += 1
        new_relations = {}
        for mov_sym,next_closure in states[closure].items():
            if next_closure not in closure_mapper:
                closure_mapper[next_closure] = closure_id
                closure_id += 1
            new_relations[mov_sym] = closure_mapper[next_closure]
        new_states[closure_mapper[closure]] = new_relations

    new_reduce = {}
    for closure in reduce:
        if closure not in closure_mapper:
            closure_mapper[closure] = closure_id
            closure_id += 1
        new_reduce[closure_mapper[closure]] = reduce[closure]

    return new_states,new_reduce,closure_mapper

MarkedStates,MarkedReduce,Closure_Mapper = mark(States,Reduce)
MarkedStart = Closure_Mapper[StartClosure]

# print(MarkedStates)
# print('==========')
# print(MarkedReduce)
# print(MarkedStart)

print("ACTION TABLE:")
for state,v in sorted(MarkedStates.items()):
    print("  ",state)
    for mov_sym,next_state in v.items():
        print("    ",mov_sym,"=>",next_state)

print("GOTO TABLE:")
for state,v in sorted(MarkedReduce.items()):
    print("  ",state)
    for mov_sym,reduce_to_sym in v.items():
        print("    ",mov_sym,"=>",reduce_to_sym)