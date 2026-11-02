spoof_small_se.m:
    adding buses from the node with the smallest index first

###spoof_small_se.m:
###    adding buses from the node with the smallest index, only success of runpf is allowed

190501 changes on spoof_small_se.m
    making all BR_B 0
    only select gen as target address

190908
    adding se_accuracy.m: evaluate the accruacy of se if less redundant data is used
    (moved it in Dropbox/Experiments/190424_Spoof/DecoyData/) adding virtual_pv.m: compare the voltage phasor angle of virtual nodes to angle of real nodes (i.e., following physical state variation of virtual nodes) 
