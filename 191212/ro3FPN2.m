clear; close all; clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));
%addpath(genpath('/home/hugo/Dropbox/Experiments/matpower7.0'));
%addpath(genpath('D:\Dropbox\Experiments\matpower5.0'));
%addpath(genpath('C:\Users\hlin2\Dropbox\Experiments\matpower5.0'));


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
GEN_DEBUG = [GEN_BUS, PG, QG];


rng(23, 'simdTwister');

caseindex = 3;
%keys = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop-1', 'case2737sop-3'};
keys = {'case24', 'case30', 'case_RTS_GMLC', 'case118', 'case2737sop-1', 'case2737sop-3'};

bias = 1e-6;

sample = 100;

% build a benchmark
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

debug_suc = zeros(length(keys), sample);

if caseindex < 5
    mpccase0 = mUnBrch(loadcase(keys{caseindex}));
    %mpccase0 = loadcase(keys{caseindex});
end
if caseindex  == 5
    mpccase0 = extract_zone(loadcase(case2737sop), 1);
end
if caseindex == 6
    mpccase0 = extract_zone(loadcase(case2737sop), 3);
end

fake_p = [0.01 : 0.01 : 0.2];
compromise_p = [0.1 : 0.1 : 1];

spoof_error = zeros(length(fake_p), length(compromise_p), sample);
suc_rec = zeros(length(fake_p), length(compromise_p), sample);
et_rec = zeros(length(fake_p), length(compromise_p), sample);
ref_error = zeros(length(fake_p), length(compromise_p), sample);
fdi_error = zeros(length(fake_p), length(compromise_p), sample);

for loop1 = 1 : length(fake_p) % number of nbusinject
    
    mpccase0.branch(:, BR_B) = 0;
    nbus = length( mpccase0.bus(:, 1) );
    nline = length( mpccase0.branch(:,1) );
    ngen = length(mpccase0.gen(:,1));
 
    nbusinject = ceil(nbus * fake_p(loop1));
    for loop2 = 1 : length(compromise_p)
    
        suc_count = 0;
        loop3 = 1;
        while 1

            mpccase = mpccase0;
           
            pl_change = loadpdf(randi(length(loadpdf)));
            nModGen = randi(ngen);  % number of randomized generator
            modGenI = randperm(ngen, nModGen);
            %mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * (1 + 0.1* power(-1, ss));
            mpccase.gen(modGenI, PG) = mpccase.gen(modGenI, PG) * pl_change;
            nModLoad = randi(nbus);
            modLoadI = randperm(nbus, nModLoad);
            mpccase.bus(modLoadI, PD) = mpccase.bus(modLoadI, PD) * pl_change;

            fprintf('%s %f %f %d\n', keys{caseindex}, nbusinject, compromise_p(loop2), loop3);
            [newcase, success, new_error, et, sel_bus] = spoof(mpccase, nbusinject);

            suc_rec(loop1, loop2, loop3) = success;
            et_rec(loop1, loop2, loop3) = et;
            spoof_error(loop1, loop2, loop3) = new_error;

            if success == 1
                suc_count = suc_count + 1;
                %[e0, e1] = doFDI(mpccase, newcase);
                %fprintf('%s %f %f\n', keys{loop0}, e0, e1);
                %all_e(loop0,:) = [e0, e1];
                %all_e(loop0, loop1) = (e1 + bias) / (e0 + bias);
            
                [error0, error1] = doFDI(mpccase, newcase, compromise_p(loop2));
                ref_error(loop1, loop2, suc_count) = error0;
                fdi_error(loop1, loop2, suc_count) = error1;
            end

            loop3 = loop3 + 1;

            if suc_count > sample | loop3 > sample * 1.1
                break;
            end

        end
    end
end

save(sprintf('./%s-ro3FPN.mat', keys{caseindex}));

