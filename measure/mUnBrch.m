function rCase = makeUniqueBranch(casefile)

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;


% combine multiple branch into a single one

rCase = loadcase(casefile);
oldCase = loadcase(casefile);
%nline = length(tempcase.branch(:, 1));
temp = find(oldCase.branch(:, BR_STATUS) == 1);
oldCase.branch = oldCase.branch(temp, :);
brch = oldCase.branch(:, [F_BUS, T_BUS]);
[C,ia,ic] = unique(brch,'rows');
rCase.branch = oldCase.branch(ia, :);
% update the branch rxb
nline = length(rCase.branch(:, 1));
for loop1 = 1 : nline
    tempI = rCase.branch(loop1, [F_BUS, T_BUS]);
    tempIndex = find(ismember(brch, tempI, 'rows'));  
    if length(tempIndex) > 1
        rCase.branch(loop1, BR_R) = rCase.branch(loop1, BR_R) / length(tempIndex);
        rCase.branch(loop1, BR_X) = rCase.branch(loop1, BR_X) / length(tempIndex);
        rCase.branch(loop1, BR_B) = rCase.branch(loop1, BR_B) * length(tempIndex);
        rCase.branch(loop1, RATE_A) = rCase.branch(loop1, RATE_A) * length(tempIndex);
    end
    
end

% combine multiple generators into a single on
%gen_i = oldCase.gen(:, GEN_BUS);
%temp = find(oldCase.gen(:, GEN_STATUS) == 1);
%oldCase.gen = oldCase.gen(temp, :);
gen_i = oldCase.gen(:, GEN_BUS);
[C, ia, ic] = unique(gen_i);
rCase.gen = oldCase.gen(ia, :);
rCase.gencost = oldCase.gencost(ia,:);
for loop1 = 1: length(rCase.gen(:,1))
    tempI = rCase.gen(loop1, GEN_BUS);
    tempBool = ismember(gen_i, tempI);
    if length(tempBool) > 1
        rCase.gen(loop1, PG) = sum(oldCase.gen(tempBool, PG));
        rCase.gen(loop1, PMAX) = sum(oldCase.gen(tempBool, PMAX));
        rCase.gen(loop1, QG) = sum(oldCase.gen(tempBool, QG));
        rCase.gen(loop1, QMAX) = sum(oldCase.gen(tempBool, QMAX));
    end
end

%rCase = tempcase;

end
