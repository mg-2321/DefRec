clear; close all; clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'case39';
%casefile = 'caseRTS96i';
%casefile = case2746wop;
%casefile = case2737sop;
casefile = 'case_RTS_GMLC';

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;


mpccase = mUnBrch(loadcase(casefile));
%mpccase = extract_zone(loadcase(casefile), 1);
%mpccase = extract_zone_simple(loadcase(casefile), 1);

nbus = length( mpccase.bus(:, 1) );
nline = length( mpccase.branch(:,1) );
ngen = length(mpccase.gen(:,1));
ndev = nline + nbus;

%base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
base_result = runpf(mpccase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC'));
V0  = base_result.bus(:, VM) .* exp(sqrt(-1) * pi/180 * base_result.bus(:, VA));



idx.idx_zPF = transpose([1: nline]);
idx.idx_zPT = [];
idx.idx_zPG = transpose([1: nbus]);   % injection
%idx.idx_zPG = [];   % injection
idx.idx_zVa = [];
idx.idx_zQF = [];
idx.idx_zQT = [];
idx.idx_zQG = [];
%idx.idx_zQG = [];
%idx.idx_zVm = transpose([1:nbus]);
idx.idx_zVm = [];

gbus = base_result.gen(:, GEN_BUS);
pf_z = base_result.branch(:, PF);
all_p = 0 - base_result.bus(:, PD);
[lia, locb] = ismember(gbus, mpccase.bus(:, BUS_I));
all_p(locb) = base_result.gen(:, PG) + all_p(locb);


measure.PF = pf_z / base_result.baseMVA ;
measure.PT = [];
measure.PG = all_p / base_result.baseMVA;  % bus power injection
%measure.PG = [];  % bus power injection
measure.Va = [];
measure.QF = [];
measure.QT = [];
measure.QG = [];
%measure.QG = [];
measure.Vm = [];

sigma.sigma_PF = 0.01;
sigma.sigma_PT = [];
sigma.sigma_PG = 0.01;
sigma.sigma_Va = [];
sigma.sigma_QF = [];
sigma.sigma_QT = [];
sigma.sigma_QG = [];
sigma.sigma_Vm = [];

type_initialguess = 3; % flat start
[baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum0] = run_dcse(mpccase, measure, idx, sigma, type_initialguess, V0);

[H, I] = getH(mpccase);

ref = find(mpccase.bus(:, BUS_TYPE) == REF);
c = rand(nbus , 1)/4;
%c = zeros(nbus , 1);
c(ref) = 0;

% tested on the newcase, should be zero
gbus =  base_result.gen(:, GEN_BUS);
all_p = 0 - base_result.bus(:, PD);
[lia, locb] = ismember(gbus, mpccase.bus(:, BUS_I));
all_p(locb) = base_result.gen(:, PG) + all_p(locb);

idx.idx_zPF = transpose(1:nline);
idx.idx_zPG = transpose(1:nbus);

H = H([idx.idx_zPF; (nline + idx.idx_zPT) ; (nline + nline + idx.idx_zPG)], :);
a = H * c;

measure.PF = base_result.branch(:, PF) / base_result.baseMVA + a(1 : nline);
%measure.PF = base_result.branch(:, PF) / base_result.baseMVA;
measure.PG = all_p / base_result.baseMVA + a((nline + 1) : (nline + nbus));
%measure.PG = all_p / base_result.baseMVA;

type_initialguess = 3; % flat start
[baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum] = run_dcse(mpccase, measure, idx, sigma, type_initialguess, V0);

freedom = length(z) - 2*(nbus-1)
baddata_t = chi2inv((1-0.9), freedom);
e = error_sqrsum / baddata_t;


