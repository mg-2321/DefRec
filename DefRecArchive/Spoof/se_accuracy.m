clear;
close all;
clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

rng(1, 'simdTwister');

%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'w9';
%casefile = 'caseRTS96i';
casefile = 'case118';
%casefile = case2746wop;
%casefile = 'case118';

casename = 'case2737sop';
zone_num = 1;

filename = strcat(casefile, '-accuracy', '.mat');
%filename = strcat(casename, '-', num2str(zone_num), '-accuracy', '.mat');

%sample = 250;
sample = 500;

%all_cases = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop', 'case2737sop'};

%se_n = 20;

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

datafile = 'July2016.txt';
% obtain load pdf
rawdata = [];
i = 1;
fid = fopen(datafile);
tline = fgetl(fid);
while ischar(tline)
    rawdata(i) = str2num(tline);
    i = i + 1;
    %disp(tline)
    tline = fgetl(fid);
end
fclose(fid);

loadpdf = ones(1, length(rawdata));
peak = max(rawdata);

for loop1 = 1 : length(rawdata)
    loadpdf(loop1) = rawdata(loop1) / peak;
end


latency = zeros(1, sample);
%latency2 = zeros(1, sample);
error_sqr = zeros(2, sample);
rz = [];
rz1 = [];

for loop0 = 1 : sample

    loop0

    tic;
    mpccase = mUnBrch(loadcase(casefile));
    %mpccase = extract_zone_simple(loadcase(casename), zone_num);
    %mpccase = extract_zone(loadcase(casename), zone_num);

    nbus = length( mpccase.bus(:, 1) );
    nline = length( mpccase.branch(:,1) );
    ngen = length(mpccase.gen(:,1));
    ndev = nline + nbus;


    pl_change = loadpdf(randi(length(loadpdf)));
    nModGen = randi(ngen);  % number of randomized generator
    modGenI = randperm(ngen, nModGen);
    %mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * (1 + 0.1* power(-1, ss));
    mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * pl_change;
    nModLoad = randi(nbus);
    modLoadI = randperm(nbus, nModLoad);
    mpccase.bus(modLoadI, PD) = mpccase.bus(modLoadI, PD) * pl_change;

    noisePF = normrnd(0, 0.01, [nline, 1]);
    noisePT = normrnd(0, 0.01, [nline, 1]);
    noisePG = normrnd(0, 0.01, [nbus, 1]);
    noiseQF = normrnd(0, 0.01, [nline, 1]);
    noiseQT = normrnd(0, 0.01, [nline, 1]);
    noiseQG = normrnd(0, 0.01, [nbus, 1]);


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

    idx.idx_zPF = transpose([1: nline]);
    idx.idx_zPT = [];
    idx.idx_zPG = transpose([1: nbus]);   % injection
    %idx.idx_zPG = [];   % injection
    idx.idx_zVa = [];
    idx.idx_zQF = transpose([1: nline]);
    idx.idx_zQT = [];
    idx.idx_zQG = transpose([1: nbus]);
    %idx.idx_zQG = [];
    %idx.idx_zVm = transpose([1:nbus]);
    idx.idx_zVm = [];

    measure.PF = pf_z / newcase.baseMVA + noisePF;
    measure.PT = [];
    measure.PG = all_p / newcase.baseMVA + noisePG;  % bus power injection
    %measure.PG = [];  % bus power injection
    measure.Va = [];
    measure.QF = qf_z / newcase.baseMVA + noiseQF;
    measure.QT = [];
    measure.QG = all_q / newcase.baseMVA + noiseQG;
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
    %max_it = floor(100 / se_n);
    max_it = 100;
    tol = 0.1;
    [baseMVA, bus, gen, branch, success, iterNum, et, z, z_est, error_sqrsum] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
    freedom = length(z) - 2*(nbus - 1)
    baddata_t = chi2inv((1-0.9), freedom);

    error_sqr(1, loop0) = error_sqrsum;

    rz = [rz; [transpose(z(1:nline)), transpose( z( (nline + nbus + 1) : (nline + nbus + nline)))]];
    
    latency(loop0) = toc;

    pt_z = newr.branch(:, PT);
    %qf_z = [base_result.branch(:, QF) ; newr.branch(injectBranchIndex, QF)];
    qt_z = newr.branch(:, QT);

    idx.idx_zPT = transpose([1: nline]);
    %idx.idx_zQT = transpose([1: nline]);
    
    measure.PT = pt_z ./ newcase.baseMVA + noisePT;
    %measure.QT = qt_z ./ newcase.baseMVA + noiseQT;

    sigma.sigma_PT = 0.01;
    %sigma.sigma_QT = 0.01;

    [baseMVA1, bus1, gen1, branch1, success1, iterNum1, et1, z1, z_est1, error_sqrsum1] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
    freedom1 = length(z1) - 2*(nbus - 1)
    baddata_t1 = chi2inv((1-0.9), freedom1);
    
    rz1 = [rz1; [transpose(z1(1:nline)), transpose( z1( (2*nline + nbus + 1) : (2*nline + nbus + nline)))]];
    
    error_sqr(2, loop0) = error_sqrsum1;

end

save(filename);

