clear;
close all;
clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

%mpccase = case5;
%casefile = 'case9';
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

nbusinject = 1; % actually 2 * nbusinject is injected
se_n = 20;
sample = 2000;
%sample = 1;

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

all_diff = [];
all_error0 = [];
all_error = [];
all_time = [];

for loop0 = 1 : sample
    mpccase = mUnBrch(loadcase(casefile));
    nbus = length( mpccase.bus(:, 1) );
    nline = length( mpccase.branch(:,1) );
    ngen = length(mpccase.gen(:,1));
    ndev = nline + nbus;

    % randomize generation, load demands
    %
    %ss = randi(2)-1;   % whether increase or decrease
    pl_change = loadpdf(randi(length(loadpdf)));
    nModGen = randi(ngen);  % number of randomized generator
    modGenI = randperm(ngen, nModGen);
    %mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * (1 + 0.1* power(-1, ss));
    mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * pl_change;
    nModLoad = randi(nbus);
    modLoadI = randperm(nbus, nModLoad);
    mpccase.bus(modLoadI, PD) = mpccase.bus(modLoadI, PD) * pl_change;


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
    fakeP = min(abs(allPF));
    fakeQ = min(abs(allQF));
    fakeR = min(abs(allR));
    fakeX = min(abs(allX));

    injectBusIndex = [];
    injectGenIndex = [];
    injectBranchIndex = [];


    tic;
    for loop1 = 1 : nbusinject

        [B, I] = sort(nodedegree);

        target = I(loop1);

        % add neighbour to the target
        % calculate power flows from this power
        %local1 = base_result.branch(:, F_BUS) == target;

        %if sum(local1) == 0
        %    local1 = base_result.branch(:, T_BUS) == target;
        %end
    
        % adding a generator
        newcase.bus = [newcase.bus; default_bus];
        nbus1 = nbus1 + 1;
        injectBusIndex(length(injectBusIndex) + 1) = nbus1;
        newcase.bus(nbus1, BUS_I) = nbus1;
        newcase.bus(nbus1, BUS_TYPE) = PV;
        newcase.bus(nbus1, PD) = 0;
        newcase.bus(nbus1, QD) = 0;
        ngen1 = ngen1 + 1;
        injectGenIndex(length(injectGenIndex) + 1) = ngen1;
        newcase.gen(ngen1, :) = default_gen;
        newcase.gen(ngen1, GEN_BUS) = newcase.bus(nbus1, BUS_I);
        newcase.gen(ngen1, PG) = fakeP;
        newcase.gen(ngen1, QG) = fakeQ;

        newcase.gencost(ngen1, :) = default_gencost;

        nline1 = nline1 + 1;
        injectBranchIndex(length(injectBranchIndex) + 1) = nline1;
        newcase.branch(nline1, :) = default_branch;
        newcase.branch(nline1, T_BUS) = target;
        newcase.branch(nline1, F_BUS) = newcase.bus(nbus1, BUS_I);
        newcase.branch(nline1, BR_R) = 0;
        %newcase.branch(nline1, BR_R) = fakeR;
        newcase.branch(nline1, BR_X) = fakeX;
        newcase.branch(nline1, BR_B) = 0;

        % adding a load 
        newcase.bus = [newcase.bus; default_bus];
        nbus1 = nbus1 + 1;
        injectBusIndex(length(injectBusIndex) + 1) = nbus1;
        newcase.bus(nbus1, BUS_I) = nbus1;
        newcase.bus(nbus1, BUS_TYPE) = PQ;
        newcase.bus(nbus1, PD) = fakeP;
        newcase.bus(nbus1, QD) = fakeQ;

        nline1 = nline1 + 1;
        injectBranchIndex(length(injectBranchIndex) + 1) = nline1;
        newcase.branch(nline1, :) = default_branch;
        newcase.branch(nline1, F_BUS) = target;
        newcase.branch(nline1, T_BUS) = newcase.bus(nbus1, BUS_I);
        newcase.branch(nline1, BR_R) = 0;
        %newcase.branch(nline1, BR_R) = fakeR;
        newcase.branch(nline1, BR_X) = fakeX;
        newcase.branch(nline1, BR_B) = 0;
    end

    newr = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

    gbus = newcase.gen(:, GEN_BUS);
    pf_z = [base_result.branch(:, PF) ; newr.branch(injectBranchIndex, PF)];
    qf_z = [base_result.branch(:, QF) ; newr.branch(injectBranchIndex, QF)];
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

    %[success, measure, idx, sigma]% = checkDataIntegrity(measure, idx, sigma, nbus);
    %if ~success
    %    error('State Estimation input data are not complete or sufficient!');
    %end
    

    fprintf('***************begin state estimation***********************\n')

    %% run state estimation
    %type_initialguess = 1; % given v0
    type_initialguess = 2; % flat start
    %[baseMVA0, bus0, gen0, branch0, success0, iterNum0, et0, z0, z_est0, error_sqrsum0] = run_se(newcase, measure, idx, sigma, type_initialguess);
    max_it = floor(100 / se_n);;
    tol = 0.1;
    [baseMVA, bus, gen, branch, success, iterNum, et, z, z_est, error_sqrsum] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
    freedom = length(z) - 2*(nbus-1)
    baddata_t = chi2inv((1-0.9), freedom);

    for loop2 = 1 : (se_n - 1)
        if error_sqrsum <= baddata_t
            break;
        end
        measure.PF(injectBranchIndex) = z_est(injectBranchIndex);
        measure.PG(injectBusIndex) = z_est(nline1 + injectBusIndex);
        measure.QF(injectBranchIndex) = z_est(nline1 + nbus1 + injectBranchIndex);
        measure.QG(injectBusIndex) = z_est(nline1 + nbus1 + nline1 + injectBusIndex);
        [baseMVA, bus, gen, branch, success, iterNum, et, z, z_est, error_sqrsum] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
        freedom = length(z) - 2*(nbus-1)
        baddata_t = chi2inv((1-0.9), freedom);
    end

    
    for loop2 = injectBusIndex
        if newcase.bus(loop2, BUS_TYPE) == PQ
            newcase.bus(loop2, PD) = (0 - z_est(nline1 + loop2)) * newcase.baseMVA;
            newcase.bus(loop2, QD) = (0 - z_est(nline1 + nbus1 + nline1 + loop2)) * newcase.baseMVA;
            %newcase.bus(loop2, PD)
            %pause;
            %newcase.bus(loop2, [PD, QD])
        end
    end
    
    for loop2 = injectGenIndex
        temp1 = newcase.gen(loop2, GEN_BUS);
        newcase.gen(loop2, PG) = z_est(nline1 + temp1) * newcase.baseMVA;
        newcase.gen(loop2, QG) = z_est(nline1 + nbus1 + nline1 + temp1) * newcase.baseMVA;
    end
    
    all_time(loop0) = toc;
    

    newr = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

    %all_brch = [base_result.branch(:, PF); base_result.branch(:, PT); base_result.branch(:, QF); base_result.branch(:, QT)];
    %local2 = temp_z ~= 0;
    %index1 = (abs(base_result.branch(:, PF) ./ base_result.branch(:, RATE_A)) >= 0.5);
    %index2 = (abs(base_result.branch(:, PT) ./ base_result.branch(:, RATE_A)) >= 0.5);
    %index3 = (abs(base_result.branch(:, QF) ./ base_result.branch(:, RATE_A)) >= 0.5);
    %index4 = (abs(base_result.branch(:, QT) ./ base_result.branch(:, RATE_A)) >= 0.5);

    index1 = (abs(base_result.branch(:, PF) ./ base_result.branch(:, RATE_A)) > 0);
    index2 = (abs(base_result.branch(:, PT) ./ base_result.branch(:, RATE_A)) > 0);
    index3 = (abs(base_result.branch(:, QF) ./ base_result.branch(:, RATE_A)) > 0);
    index4 = (abs(base_result.branch(:, QT) ./ base_result.branch(:, RATE_A)) > 0);

    pf_diff = [abs(newr.branch(index1, PF)) ./ abs(base_result.branch(index1, PF)); ...
                %abs(newr.branch(index2, PT)) ./ abs(base_result.branch(index2, PT)); ...
                abs(newr.branch(index3, QF)) ./ abs(base_result.branch(index3, QF))]; 
                %abs(newr.branch(index4, QT)) ./ abs(base_result.branch(index1, QT))];
    all_diff = [all_diff; transpose(pf_diff)];
    
    dcr = runpf(newcase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC'));
    
    %% evaluate dc fdi
    [curH, devI] = getH(newcase);

    ref = find(newcase.bus(:, BUS_TYPE) == REF);
    c = rand(nbus1 , 1)/4;
    c(ref) = 0; 

    % tested on the newcase, should be zero
    gbus1 =  dcr.gen(:, GEN_BUS);
    all_p1 = 0 - dcr.bus(:, PD);
    all_p1(gbus1) = dcr.gen(:, PG) + all_p1(gbus1);

    idx.idx_zQF = [];
    idx.idx_zQG = [];
    measure.QF = [];
    measure.QG = [];
    sigma.sigma_QF= [];
    sigma.sigma_QG = [];

    idx.idx_zPF = transpose(1 : nline1);
    idx.idx_zPG = transpose(1 : nbus1);

    curH = curH([idx.idx_zPF; (nline1 + idx.idx_zPT) ; (nline1 + nline1 + idx.idx_zPG)], :);
    a = curH * c;

    measure.PF = dcr.branch(:, PF) / dcr.baseMVA + a(1 : nline1);
    %measure.PF = dcr.branch(:, PF) / dcr.baseMVA;
    measure.PG = all_p1 / dcr.baseMVA + a((nline1 + 1) : (nline1 + nbus1));
    %measure.PG = all_p1 / dcr.baseMVA;

    type_initialguess = 2; % flat start
    [baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum0] = run_dcse(newcase, measure, idx, sigma, type_initialguess);
    freedom = length(z) - 2*(nbus1-1)
    baddata_t0 = chi2inv((1-0.9), freedom);

    all_error0(loop0) = error_sqrsum0;

    %% directly try the modified measurements in mpccase
    dcr0 = runpf(mpccase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC'));
    gbus0 =  dcr0.gen(:, GEN_BUS);
    all_p0 = 0 - dcr0.bus(:, PD);
    all_p0(gbus0) = dcr0.gen(:, PG) + all_p0(gbus0);

    idx.idx_zPF = transpose(1 : nline);
    idx.idx_zPG = transpose(1 : nbus);

    measure.PF = dcr0.branch(:, PF) / dcr0.baseMVA + a(1 : nline);
    measure.PG = all_p0 / dcr0.baseMVA + a((nline1 + 1) : (nline1 + nbus));

    [baseMVA, bus, gen, branch, et, z, z_est, error_sqrsum] = run_dcse(mpccase, measure, idx, sigma, type_initialguess);
    all_error(loop0) = error_sqrsum;
    freedom = length(z) - 2*(nbus-1)
    baddata_t1 = chi2inv((1-0.9), freedom);

end

save(sprintf('./%s-%d-fdi.mat', casefile, nbusinject))

