function [candidate] = pre_analysis(mpccase)


%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'case39';
%casefile = 'caseRTS96i';
%casefile = case2746wop;
%mpccase = mUnBrch(loadcase(casefile));

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));


MSGID = ['MATLAB:singularMatrix';];
warning('off', MSGID);

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

nbus = length( mpccase.bus(:, 1) );
nline = length( mpccase.branch(:,1) );
ngen = length(mpccase.gen(:,1));
ndev = nline + nbus;
    
base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
default_bus = base_result.bus(1, :);
default_branch = base_result.branch(1, :);
default_gen = base_result.gen(1, :);
default_gencost = base_result.gencost(1, :);

nodedegree = zeros(1, nbus);
bus_b = zeros(1, nbus); % find the shunt capacitance in each bus

for loop1 = 1 : nbus
    local1 = base_result.branch(:, F_BUS) == base_result.bus(loop1, BUS_I);
    local2 = base_result.branch(:, T_BUS) == base_result.bus(loop1, BUS_I);
    nodedegree(loop1) = length(find(local1)) + length(find(local2));

    bus_b(loop1) = sum( base_result.branch(local1, BR_B) ) + sum( base_result.branch(local2, BR_B) );
end


newcase.version = '2';
newcase.baseMVA = base_result.baseMVA;
newcase.branch = base_result.branch;
newcase.gen = base_result.gen;
newcase.gencost = base_result.gencost;
newcase.bus = base_result.bus;

nbus1 = nbus;
nline1 = nline;
ngen1 = ngen;

rate_a = base_result.branch(:, RATE_A) ;
%rate_a = [rate_a; rate_a; rate_a; rate_a];


allPF = base_result.branch(:, PF);
allQF = base_result.branch(:, QF);
allR = base_result.branch(:, BR_R);
allX = base_result.branch(:, BR_X);
%fakeP = min(abs(allPF));
%fakeQ = min(abs(allQF));
%fakeR = min(abs(allR));
fakeP = 0;
fakeQ = 0;
fakeR = 0;
fakeX = min(abs(allX));
if fakeX < 0.01
    fakeX = 0.01;
end
%fakeX
%pause;

injectBusIndex = [];
injectGenIndex = [];
injectBranchIndex = [];
all_diff = [];
suc_bus = [];

for loop1 = 1 : nbus
    target = loop1;

    %newcase.bus = [newcase.bus; default_bus];
    nbus1 = nbus1 + 1;
    injectBusIndex(length(injectBusIndex) + 1) = nbus1;
    newcase.bus(nbus1, : ) = default_bus;
    newcase.bus(nbus1, BUS_I) = nbus1;
    newcase.bus(nbus1, BUS_TYPE) = PQ;
    newcase.bus(nbus1, PD) = fakeP;
    newcase.bus(nbus1, QD) = fakeQ;

    nline1 = nline1 + 1;
    injectBranchIndex(length(injectBranchIndex) + 1) = nline1;
    newcase.branch(nline1, :) = default_branch;
    newcase.branch(nline1, F_BUS) = target;
    newcase.branch(nline1, T_BUS) = newcase.bus(nbus1, BUS_I);
    %newcase.branch(nline1, BR_R) = 0;
    newcase.branch(nline1, BR_R) = fakeR;
    newcase.branch(nline1, BR_X) = fakeX;
    newcase.branch(nline1, BR_B) = 0;

    % update VM, VA in BUS and VG in GEN based on base_result
    newcase.bus(1:nbus, [VM, VA]) = base_result.bus(:, [VM, VA]);
    newcase.bus(nbus1, [VM, VA]) = base_result.bus( newcase.branch(nline1, F_BUS), [VM, VA]);
    newcase.gen(:, VG) = abs(base_result.bus(mpccase.gen(:, GEN_BUS), VM) .* exp(sqrt(-1) * pi/180 * base_result.bus(mpccase.gen(:, GEN_BUS), VA)));

    newr = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
    if newr.success == 1

        suc_bus = [suc_bus; loop1];

        index1 = (abs(base_result.branch(:, PF) ./ base_result.branch(:, RATE_A)) > 0);
        index2 = (abs(base_result.branch(:, PT) ./ base_result.branch(:, RATE_A)) > 0);
        index3 = (abs(base_result.branch(:, QF) ./ base_result.branch(:, RATE_A)) > 0);
        index4 = (abs(base_result.branch(:, QT) ./ base_result.branch(:, RATE_A)) > 0);

        pf_diff = [abs(newr.branch(index1, PF)) ./ abs(base_result.branch(index1, PF)); ...
                    %abs(newr2.branch(index2, PT)) ./ abs(base_result.branch(index2, PT)); ...
                    abs(newr.branch(index3, QF)) ./ abs(base_result.branch(index3, QF))]; 
                    %abs(newr2.branch(index4, QT)) ./ abs(base_result.branch(index1, QT))];
        all_diff = [all_diff; transpose(pf_diff)];
    end

end

[B, I] = sort(sum(all_diff, 2));

candidate = suc_bus(I);

end
