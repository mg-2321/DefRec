clear;
clc;


addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

BUS_P = [BUS_I, PD, QD, VM, VA];
BRCH_P = [F_BUS, T_BUS, PF, PT, QF, QT];
GEN_P = [GEN_BUS, PG, QG];

casedesc = {'1999Winter', '2003Winter' '2004Summer'};
cases = {'case2383wp', 'case2746wp', 'case2736sp'};

allNodeDeg = zeros(length(cases), 2383);

for loop0 = 1 : length(cases)
    %casename = 'caseRTS96i';

    casename = cases{loop0};

    currentcase = mUnBrch(casename);
    % states from whole power grids
    nbus = length(currentcase.bus(:, 1));
    nline = length(currentcase.branch(:, 1));
    ngen = length(currentcase.gen(:, 1));


    base_result = runpf(currentcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

    gbus =  base_result.gen(:, GEN_BUS);
    cur_p = 0 - base_result.bus(:, PD);
    cur_p(gbus) = base_result.gen(:, PG) + cur_p(gbus);
    cur_q = 0 - base_result.bus(:, QD);
    cur_q(gbus) = base_result.gen(:, QG) + cur_q(gbus);


    nodedegree = zeros(1, nbus);

    for loop1 = 1 : nbus
        local1 = base_result.branch(:, F_BUS) == base_result.bus(loop1, BUS_I);
        local2 = base_result.branch(:, T_BUS) == base_result.bus(loop1, BUS_I);
        nodedegree(loop1) = length(find(local1)) + length(find(local2));
    end

    allNodeDeg(loop0,:) = nodedegree(1:2383);
    %fprintf('%s\n', casedesc{loop0});
    %nodedegree(1:20)
    %transpose(cur_p(1:20))
    %transpose(cur_q(1:20))
    %fprintf('************\n');
end

% stored in csv file
filename = './degree.txt';
file_id = fopen(filename, 'w');

fprintf(file_id, 'Bus_I ');

for loop0 = 1 : length(cases)
%for loop0 = 1 : 1
    fprintf(file_id, '%s ', casedesc{loop0});
    %for loop1 = 1 : length(allNodeDeg(loop0,:))
    %    fprintf(file_id, '%d ', allNodeDeg(loop0, loop1));
    %end
    %fprintf(file_id, '\n');
end

fprintf(file_id, '\n');

temp = [1:1:length(allNodeDeg(1,:))];
temp = [temp; allNodeDeg];

fprintf(file_id, '%d %d %d %d\n', temp);

fclose(file_id);

