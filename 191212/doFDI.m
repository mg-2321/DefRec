function [error00, error0, error1] = doFDI(mpccase, newcase, compromise_p)

%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'case39';
%casefile = 'caseRTS96i';
%casefile = 'case118';
%casefile = case2746wop;
%casefile = 'case2737sop-1';
%casefile = 'case2737sop-3';

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%rng(23, 'simdTwister');

%nbusinject = 8; % actually 2 * nbusinject is injected

%filename = sprintf('./result/190423/%s-%d-se.mat', casefile, nbusinject);
%re = load(filename);
%[m, n] = size(re.all_cases);
%se_n = 20;
%sample = length(re.all_cases);
sample = 1;

for loop0 = 1 : sample
   
    %mpccase = re.all_cases{loop0,1};
    nbus = length( mpccase.bus(:, 1) );
    nline = length( mpccase.branch(:,1) );
    ngen = length(mpccase.gen(:,1));
    ndev = nline + nbus;

    %base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

        
    %newcase = re.all_cases{loop0, 2};
    nbus1 = length( newcase.bus(:, 1) );
    nline1 = length( newcase.branch(:,1) );
    ngen1 = length(newcase.gen(:,1));
    ndev1 = nline1 + nbus1;

    idx.idx_zPF = [];
    idx.idx_zPT = [];
    idx.idx_zPG = [];
    idx.idx_zVa = [];
    idx.idx_zQF = [];
    idx.idx_zQT = [];
    idx.idx_zQG = [];
    idx.idx_zVm = [];

    measure.PF = [];
    measure.PT = [];
    measure.PG = [];
    measure.Va = [];
    measure.QF = [];
    measure.QT = [];
    measure.QG = [];
    measure.Vm = [];

    sigma.sigma_PF = [];
    sigma.sigma_PT = [];
    sigma.sigma_PG = [];
    sigma.sigma_Va = [];
    sigma.sigma_QF = [];
    sigma.sigma_QT = [];
    sigma.sigma_QG = [];
    sigma.sigma_Vm = [];
    
    idx.idx_zPF = transpose(1 : nline);
    idx.idx_zPG = transpose(1 : nbus);

    sigma.sigma_PF = 0.01;
    sigma.sigma_PG = 0.01;

    dcr0 = runpf(mpccase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC')); 
    gbus0 =  dcr0.gen(:, GEN_BUS);
    all_p0 = 0 - dcr0.bus(:, PD);
    [lia, locb] = ismember(gbus0, dcr0.bus(:, BUS_I));
    all_p0(locb) = dcr0.gen(:, PG) + all_p0(locb);

    measure.PF = dcr0.branch(:, PF) / dcr0.baseMVA;
    measure.PT = [];
    measure.PG = all_p0 / dcr0.baseMVA;

    type_initialguess = 2; % flat start
    [baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum00] = run_dcse(mpccase, measure, idx, sigma, type_initialguess);
    freedom = length(z) - 2*(nbus-1)
    baddata_t00 = chi2inv((1-0.9), freedom);
    error00 = error_sqrsum00 / baddata_t00;

    %% evaluate dc fdi
    dcr = runpf(newcase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC')); 
    [curH, devI] = getH(newcase);

    ref = find(newcase.bus(:, BUS_TYPE) == REF);
    n_c0 = floor(nbus1 * compromise_p);
    c0_index = randperm(nbus1, nbus1 - n_c0);
    c = rand(nbus1 , 1)/4;
    c(c0_index) = 0;
    c(ref) = 0; 

    % tested on the newcase, should be zero
    gbus1 =  dcr.gen(:, GEN_BUS);
    all_p1 = 0 - dcr.bus(:, PD);
    [lia, locb] = ismember(gbus1, dcr.bus(:, BUS_I));
    all_p1(locb) = dcr.gen(:, PG) + all_p1(locb);
    %all_p1(gbus1) = dcr.gen(:, PG) + all_p1(gbus1); 


    idx.idx_zPF = transpose(1 : nline1);
    idx.idx_zPG = transpose(1 : nbus1);

    sigma.sigma_PF = 0.01;
    sigma.sigma_PG = 0.01;

    curH = curH([idx.idx_zPF; (nline1 + idx.idx_zPT) ; (nline1 + nline1 + idx.idx_zPG)], :);
    nline1
    nbus1
    size(curH)
    size(c)
    a = curH * c;

    measure.PF = dcr.branch(:, PF) / dcr.baseMVA + a(1 : nline1);
    measure.PT = [];
    %measure.PF = dcr.branch(:, PF) / dcr.baseMVA;
    measure.PG = all_p1 / dcr.baseMVA + a((nline1 + 1) : (nline1 + nbus1));
    %measure.PG = all_p1 / dcr.baseMVA;

    type_initialguess = 2; % flat start
    [baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum0] = run_dcse(newcase, measure, idx, sigma, type_initialguess);
    freedom = length(z) - 2*(nbus1-1)
    baddata_t0 = chi2inv((1-0.9), freedom);
    error0 = error_sqrsum0 / baddata_t0;

    %all_error0(loop0) = error_sqrsum0;

    %% directly try the modified measurements in mpccase
    dcr0 = runpf(mpccase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC'));
    gbus0 =  dcr0.gen(:, GEN_BUS);
    all_p0 = 0 - dcr0.bus(:, PD);
    [lia, locb] = ismember(gbus0, dcr0.bus(:, BUS_I));
    all_p0(locb) = dcr0.gen(:, PG) + all_p0(locb);
    %all_p0(gbus0) = dcr0.gen(:, PG) + all_p0(gbus0);

    idx.idx_zPF = transpose(1 : nline);
    idx.idx_zPG = transpose(1 : nbus);

    measure.PF = dcr0.branch(:, PF) / dcr0.baseMVA + a(1 : nline);
    measure.PG = all_p0 / dcr0.baseMVA + a((nline1 + 1) : (nline1 + nbus));

    type_initialguess = 2; % flat start
    [baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum] = run_dcse(mpccase, measure, idx, sigma, type_initialguess);
    all_error(loop0) = error_sqrsum;
    freedom = length(z) - 2*(nbus-1)
    baddata_t1 = chi2inv((1-0.9), freedom);

    error1 = error_sqrsum / baddata_t1;

end

%save(sprintf('./%s-%d-fdi.mat', casefile, nbusinject))

end

