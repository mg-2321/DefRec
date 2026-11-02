clear;
close all;
clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));



%mpccase = case5;
%casefile = 'case9';
%casefile = case24_ieee_rts;
casefile = 'case24';
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

rng(23, 'simdTwister');

nbusinject = 8; % actually 2 * nbusinject is injected

filename = sprintf('./result/190423/%s-%d-se.mat', casefile, nbusinject);
re = load(filename);
%[m, n] = size(re.all_cases);
%se_n = 20;
%sample = length(re.all_cases);
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

all_diff = [];
all_error0 = [];
all_error = [];
all_time = [];
%}


for loop0 = 1 : sample
    
    mpccase = re.all_cases{loop0,1};
    nbus = length( mpccase.bus(:, 1) );
    nline = length( mpccase.branch(:,1) );
    ngen = length(mpccase.gen(:,1));
    ndev = nline + nbus;

    base_result = runpf(mpccase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

    assert(base_result.success == 1);

        
    newcase = re.all_cases{loop0, 2};
    nbus1 = length( newcase.bus(:, 1) );
    nline1 = length( newcase.branch(:,1) );
    ngen1 = length(newcase.gen(:,1));
    ndev1 = nline1 + nbus1;

    %dcr = runpf(newcase, mpoption('verbose', 0, 'out.all', 0, 'model', 'DC'));
    virtual_result = runpf(newcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));
    
    assert(virtual_result.success == 1);

    virtual_bus_i = [ (nbus+1) : 1 : nbus1 ];

    
end

%save(sprintf('./%s-%d-fdi.mat', casefile, nbusinject))

