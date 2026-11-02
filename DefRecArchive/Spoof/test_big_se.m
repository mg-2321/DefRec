clear;
close all;
clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'w9';
%casefile = 'caseRTS96i';
%casefile = case2746wop;
casefile = 'case118';

casename = 'case2737sop';

zone_num = 1;

se_n = 20;

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

BUS_DEBUG = [BUS_I, BUS_TYPE, PD, QD];
BRCH_DEBUG = [F_BUS, T_BUS, PF, QF, PT, QT];

mpccase = mUnBrch(loadcase(casefile));
%mpccase = extract_zone_simple(loadcase(casename), zone_num);
%mpccase = extract_zone(loadcase(casename), zone_num);

nbus = length( mpccase.bus(:, 1) );
nline = length( mpccase.branch(:,1) );
ngen = length(mpccase.gen(:,1));
ndev = nline + nbus;

nbus1 = nbus;
nline1 = nline;
ngen1 = ngen;

newr = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

newcase = mpccase;

gbus = newcase.gen(:, GEN_BUS);
    %pf_z = [base_result.branch(:, PF) ; newr.branch(injectBranchIndex, PF)];
    pf_z = newr.branch(:, PF);
    %qf_z = [base_result.branch(:, QF) ; newr.branch(injectBranchIndex, QF)];
    qf_z = newr.branch(:, QF);
    all_p = 0 - newr.bus(:, PD);
    all_q = 0 - newr.bus(:, QD);
    all_p(gbus) = newr.gen(:, PG) + all_p(gbus);
    all_q(gbus) = newr.gen(:, QG) + all_q(gbus);

    idx.idx_zPF = transpose([1: nline1]);
    idx.idx_zPT = [];
    idx.idx_zPG = transpose([1: nbus1]);   % injection
    %idx.idx_zPG = [];   % injection
    idx.idx_zVa = [];
    idx.idx_zQF = transpose([1: nline1]);
    idx.idx_zQT = [];
    idx.idx_zQG = transpose([1: nbus1]);
    %idx.idx_zQG = [];
    %idx.idx_zVm = transpose([1:nbus]);
    idx.idx_zVm = [];

    measure.PF = pf_z / newcase.baseMVA ;
    measure.PT = [];
    measure.PG = all_p / newcase.baseMVA;  % bus power injection
    %measure.PG = [];  % bus power injection
    measure.Va = [];
    measure.QF = qf_z / newcase.baseMVA;
    measure.QT = [];
    measure.QG = all_q / newcase.baseMVA;
    %measure.QG = [];
    measure.Vm = [];

    sigma.sigma_PF = 0.01;
    sigma.sigma_PT = [];
    sigma.sigma_PG = 0.01;
    sigma.sigma_Va = [];
    sigma.sigma_QF = 0.01;
    sigma.sigma_QT = [];
    sigma.sigma_QG = 0.01;
    sigma.sigma_Vm = [];
    sigma_vector = [
        sigma.sigma_PF*ones(size(idx.idx_zPF, 1), 1)
        sigma.sigma_PT*ones(size(idx.idx_zPT, 1), 1)
        sigma.sigma_PG*ones(size(idx.idx_zPG, 1), 1)
        sigma.sigma_Va*ones(size(idx.idx_zVa, 1), 1)
        sigma.sigma_QF*ones(size(idx.idx_zQF, 1), 1)
        sigma.sigma_QT*ones(size(idx.idx_zQT, 1), 1)
        sigma.sigma_QG*ones(size(idx.idx_zQG, 1), 1)
        sigma.sigma_Vm*ones(size(idx.idx_zVm, 1), 1)
        ]; % NOTE: zero-value
    sigma_square = sigma_vector.^2;
    R_inv = diag(1./sigma_square);


    %{
    [success, measure, idx, sigma] = checkDataIntegrity(measure, idx, sigma, nbus);
    if ~success
        error('State Estimation input data are not complete or sufficient!');
    end
    %}

    fprintf('***************begin state estimation***********************\n')

    %% run state estimation
    %type_initialguess = 1; % given v0
    type_initialguess = 2; % flat start
    %[baseMVA0, bus0, gen0, branch0, success0, iterNum0, et0, z0, z_est0, error_sqrsum0] = run_se(newcase, measure, idx, sigma, type_initialguess);
    max_it = floor(100 / se_n);;
    tol = 0.1;
    [baseMVA, bus, gen, branch, success, iterNum, et, z, z_est, error_sqrsum] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
    freedom = length(z) - 2*(nbus1 - 1)
    baddata_t = chi2inv((1-0.9), freedom);

