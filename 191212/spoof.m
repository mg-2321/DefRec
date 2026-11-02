function [newcase, success, new_error, et, sel_bus] = spoof(mpccase, nbusinject)

%addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
%casefile = 'case24';
%casefile = 'case30';
%casefile = 'case39';
%casefile = 'caseRTS96i';
%casefile = case2746wop;

%casename = 'case2737sop';
%zone_num = 1;


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

se_n = 20;
sample = 1;

%{
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
%}

%mpccase = mUnBrch(loadcase(casefile));

%bigcase0 = mUnBrch(casename);
%mpccase = extract_zone_simple(loadcase(casename), zone_num);
%mpccase = extract_zone(loadcase(casename), zone_num);


candidate = mpccase.gen(:, GEN_BUS);
%{
candidate = spoof_pre(mpccase);
nodedegree1= zeros(1, length(candidate));
bus_b = zeros(1, length(candidate)); % find the shunt capacitance in each bus

for loop1 = 1 : length(candidate)
    local1 = mpccase.branch(:, F_BUS) == mpccase.bus( candidate(loop1), BUS_I );
    local2 = mpccase.branch(:, T_BUS) == mpccase.bus( candidate(loop1), BUS_I);
    nodedegree(loop1) = length(find(local1)) + length(find(local2));

    bus_b(loop1) = sum( mpccase.branch(local1, BR_B) ) + sum( mpccase.branch(local2, BR_B) );
end
%}



%all_diff = []; %
%all_diff = {};
%all_latency = zeros(1, sample);
%all_error = zeros(1, sample);
%suc_count = 0;
%all_cases = {};
nc_cases = {};
ns_cases = {};
%sel_bus = [];

et = 0;
new_error = -1;
sel_bus = [];


for loop0 = 1 : sample
    %loop0 
    %mpccase = mUnBrch(loadcase(casefile));
    %mpccase = extract_zone(loadcase(casename), zone_num);  % for area 3
    %mpccase = extract_zone_simple(loadcase(casename), zone_num); % for area 1

    nbus = length( mpccase.bus(:, 1) );
    nline = length( mpccase.branch(:,1) );
    ngen = length(mpccase.gen(:,1));
    ndev = nline + nbus;

    %mpccase.branch(:, BR_B) = 0;

    % randomize generation, load demands
    %
    %ss = randi(2)-1;   % whether increase or decrease
    %{
    pl_change = loadpdf(randi(length(loadpdf)));
    nModGen = randi(ngen);  % number of randomized generator
    modGenI = randperm(ngen, nModGen);
    %mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * (1 + 0.1* power(-1, ss));
    mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * pl_change;
    nModLoad = randi(nbus);
    modLoadI = randperm(nbus, nModLoad);
    mpccase.bus(modLoadI, PD) = mpccase.bus(modLoadI, PD) * pl_change;
    %}

    base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
    %fprintf('pause here\n');
    %pause; 

    default_bus = mpccase.bus(1, :);
    default_branch = mpccase.branch(1, :);
    default_gen = mpccase.gen(1, :);
    default_gencost = mpccase.gencost(1, :);


    newcase.version = '2';
    newcase.baseMVA = mpccase.baseMVA;
    newcase.branch = mpccase.branch;
    newcase.gen = mpccase.gen;
    newcase.gencost = mpccase.gencost;
    newcase.bus = mpccase.bus;

    if base_result.success == 1
        ;
    else
        success = -1;
        continue;
    end

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

    injectBusIndex = [];
    injectGenIndex = [];
    injectBranchIndex = [];

    cur_selbus = zeros(1, nbusinject);

    if length(candidate) > nbusinject
        tempc = randperm(length(candidate), nbusinject);
    else
        %tempc = [1: length(candidate)];
        tempc = randperm(length(candidate), length(candidate));
    end

    tic;
    for loop1 = 1 : nbusinject

        %[B, I] = sort(nodedegree);
        %target = candidate(I(loop1));

        target = candidate(tempc( mod( loop1-1, length(candidate) ) + 1 ));
        cur_selbus(loop1) = target;

        %[B, I] = sort(bus_b);
        %target = candidate(I(loop1));
        %target = candidate( randi(length(candidate)) );

        % add neighbour to the target
        % calculate power flows from this power
        %local1 = base_result.branch(:, F_BUS) == target;

        %if sum(local1) == 0
        %    local1 = base_result.branch(:, T_BUS) == target;
        %end
     
        % adding a generator
        %{
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
        %}

        % adding a load 
        newcase.bus = [newcase.bus; default_bus];
        nbus1 = nbus1 + 1;
        injectBusIndex(length(injectBusIndex) + 1) = nbus1;
        %newcase.bus(nbus1, BUS_I) = nbus1;
        newcase.bus(nbus1, BUS_I) = newcase.bus(nbus1 - 1, BUS_I) + 1;
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

    % update VM, VA in BUS and VG in GEN based on base_result
    [lia, locb] = ismember(mpccase.gen(:, GEN_BUS), base_result.bus(:, BUS_I));
    newcase.gen(:, VG) = abs(base_result.bus(locb, VM) .* exp(sqrt(-1) * pi/180 * base_result.bus(locb, VA)));
    %newcase.gen(:, VG) = abs(base_result.bus(mpccase.gen(:, GEN_BUS), VM) .* exp(sqrt(-1) * pi/180 * base_result.bus(mpccase.gen(:, GEN_BUS), VA)));

    newr = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
    %newr.success
    %pause;

    if (newr.success == 0)
        %nc_cases{ length(nc_cases) + 1 , 1} = mpccase;
        %nc_cases{ length(nc_cases) , 2} = newcase;
        success = -2;
        continue;
    %else
    %    loop0 = loop0 + 1;
    end

    %if loop0 > sample
    %    break;
    %end



    gbus = newcase.gen(:, GEN_BUS);
    %pf_z = [base_result.branch(:, PF) ; newr.branch(injectBranchIndex, PF)];
    pf_z = newr.branch(:, PF);
    %qf_z = [base_result.branch(:, QF) ; newr.branch(injectBranchIndex, QF)];
    qf_z = newr.branch(:, QF);
    all_p = 0 - newr.bus(:, PD);
    all_q = 0 - newr.bus(:, QD);
    %fprintf('DEBUG %d %d %d\n', length(all_p), length(gbus), length(newr.gen(:, PG)));
    [lia, locb] = ismember(gbus, newr.bus(:, BUS_I));
    %all_p(gbus) = newr.gen(:, PG) + all_p(gbus);
    all_p(locb) = newr.gen(:, PG) + all_p(locb);
    %all_q(gbus) = newr.gen(:, QG) + all_q(gbus);
    all_q(locb) = newr.gen(:, QG) + all_q(locb);

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

    for loop2 = 1 : (se_n - 1)
        if error_sqrsum <= baddata_t
            break;
        end
        measure.PF(injectBranchIndex) = z_est(injectBranchIndex);
        measure.PG(injectBusIndex) = z_est(nline1 + injectBusIndex);
        measure.QF(injectBranchIndex) = z_est(nline1 + nbus1 + injectBranchIndex);
        measure.QG(injectBusIndex) = z_est(nline1 + nbus1 + nline1 + injectBusIndex);
        [baseMVA, bus, gen, branch, success, iterNum, et, z, z_est, error_sqrsum] = run_se(newcase, measure, idx, sigma, tol, max_it, type_initialguess);
        freedom = length(z) - 2*(nbus1 - 1)
        baddata_t = chi2inv((1-0.9), freedom);
    end

    newr2 = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

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

    pf_diff = [abs(newr2.branch(index1, PF)) ./ abs(base_result.branch(index1, PF)); ...
                %abs(newr2.branch(index2, PT)) ./ abs(base_result.branch(index2, PT)); ...
                abs(newr2.branch(index3, QF)) ./ abs(base_result.branch(index3, QF))]; 
                %abs(newr2.branch(index4, QT)) ./ abs(base_result.branch(index1, QT))];

    %all_error(loop0) = error_sqrsum;
    new_error = error_sqrsum / baddata_t;
    et = toc;
    sel_bus = cur_selbus;

    if error_sqrsum <= baddata_t
        %suc_count = suc_count + 1;
        success = 1;
        %new_error = error_sqrsum / baddata_t;
        %sel_bus(suc_count) = target;

       
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
       
        %all_cases{suc_count, 1} = mpccase;
        %all_cases{suc_count, 2} = newcase;
 
        %all_diff = [all_diff; transpose(pf_diff)];
        %all_diff{suc_count} = pf_diff;

    else
        %pause;
        %ns_cases{ length(ns_cases) + 1 , 1} = mpccase;
        %ns_cases{ length(ns_cases) , 2} = newcase;
        success = 0;
        
    end

    
end


end
