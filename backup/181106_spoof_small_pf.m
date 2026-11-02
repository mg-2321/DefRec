clear;
close all;
clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

%mpccase = case5;
%casefile = case24_ieee_rts;
%casefile = 'case24';
casefile = 'case30';
%casefile = 'case39';
%casefile = 'caseRTS96i';
%casefile = case2746wop;

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

rng(23, 'simdTwister');

mpccase = mUnBrch(loadcase(casefile));
nbus = length( mpccase.bus(:, 1) );
nline = length( mpccase.branch(:,1) );
ngen = length(mpccase.gen(:,1));
ndev = nline + nbus;

nbusinject = 1; % actually 2 * nbusinject is injected

base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

default_bus = base_result.bus(1, :);
default_branch = base_result.branch(1, :);
default_gen = base_result.gen(1, :);
default_gencost = base_result.gencost(1, :);

nodedegree = zeros(1, nbus);

for loop1 = 1 : nbus
    local1 = base_result.branch(:, F_BUS) == base_result.bus(loop1, BUS_I);
    local2 = base_result.branch(:, T_BUS) == base_result.bus(loop1, BUS_I);
    nodedegree(loop1) = length(find(local1)) + length(find(local2));
end

[M, target] = min(nodedegree);

% add neighbour to the target
% calculate power flows from this power
local1 = base_result.branch(:, F_BUS) == target;
fakeP = mean(abs(base_result.branch(local1, PF)));
fakeQ = mean(abs(base_result.branch(local1, QF)));
fakeR = mean(abs(base_result.branch(local1, BR_R)));
fakeX = mean(abs(base_result.branch(local1, BR_X)));

newcase.version = '2';
newcase.baseMVA = base_result.baseMVA;
newcase.branch = base_result.branch;
newcase.gen = base_result.gen;
newcase.gencost = base_result.gencost;
newcase.bus = base_result.bus;

nbus1 = nbus;
nline1 = nline;
ngen1 = ngen;


% adding a generator
newcase.bus = [newcase.bus; default_bus];
nbus1 = nbus1 + 1;
newcase.bus(nbus1, BUS_I) = nbus + 1;
newcase.bus(nbus1, BUS_TYPE) = PV;
newcase.bus(nbus1, PD) = 0;
newcase.bus(nbus1, QD) = 0;
ngen1 = ngen1 + 1;
newcase.gen(ngen1, :) = default_gen;
newcase.gen(ngen1, GEN_BUS) = newcase.bus(nbus1, BUS_I);
newcase.gen(ngen1, PG) = fakeP;
newcase.gen(ngen1, QG) = fakeQ;

newcase.gencost(ngen1, :) = default_gencost;

nline1 = nline1 + 1;
newcase.branch(nline1, :) = default_branch;
newcase.branch(nline1, F_BUS) = target;
newcase.branch(nline1, T_BUS) = newcase.bus(nbus1, BUS_I);
newcase.branch(nline1, BR_R) = fakeR;
newcase.branch(nline1, BR_X) = fakeX;
newcase.branch(nline1, BR_R) = 0;

% adding a load 
newcase.bus = [newcase.bus; default_bus];
nbus1 = nbus1 + 1;
newcase.bus(nbus1, BUS_I) = nbus1 + 1;
newcase.bus(nbus1, BUS_TYPE) = PQ;
newcase.bus(nbus1, PD) = fakeP;
newcase.bus(nbus1, QD) = fakeQ;

nline1 = nline1 + 1;
newcase.branch(nline1, :) = default_branch;
newcase.branch(nline1, F_BUS) = target;
newcase.branch(nline1, T_BUS) = newcase.bus(nbus1, BUS_I);
newcase.branch(nline1, BR_R) = fakeR;
newcase.branch(nline1, BR_X) = fakeX;
newcase.branch(nline1, BR_R) = 0;


newr = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));


