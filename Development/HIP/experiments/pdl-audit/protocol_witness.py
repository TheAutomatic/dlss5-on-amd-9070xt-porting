#!/usr/bin/env python3
"""Finite counterexample for the exact uint32 target + unsigned '<' predicate.
This is a protocol witness, not a claim that a short game session hit wraparound.
"""
import json
MASK=(1<<32)-1
cases=[]
for waves in (4,8,16):
    old=(1<<32)-waves
    target=(old+waves)&MASK
    counter=old  # the old generation finished; none of the new producers have stored yet
    wait=counter<target
    assert not wait
    cases.append(dict(waves=waves,old_counter=counter,new_target=target,
                      new_producers_completed=0,consumer_waits=wait))
print(json.dumps(cases,indent=2))
