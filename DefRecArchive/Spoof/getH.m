function [H, deviceI] = getH(mpccase)

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%% deviceI in this order  [PF, PT, P] for DC
% in simplified version we can make it [PF, P]
deviceI = [mpccase.branch(:, F_BUS); mpccase.branch(:, T_BUS); mpccase.bus(:, BUS_I)];
nline = length(mpccase.branch(:,1));
nbus = length(mpccase.bus(:,1));

%Yline = 1 ./ (mpccase.branch(:, BR_R) + sqrt(-1) * mpccase.branch(:, BR_X));
b = 1.0 ./ mpccase.branch(:, BR_X);
branches = mpccase.branch(:, [F_BUS, T_BUS]);
H = sparse(zeros(2 * nline + nbus, nbus));
for loop1 = 1 : length(deviceI)
    if loop1 <= nline
        H(loop1, branches(loop1, 1)) = b(loop1);
        H(loop1, branches(loop1, 2)) = -b(loop1);
    elseif (loop1 > nline ) & (loop1 <= 2*nline)
        H(loop1, branches(loop1-nline, 2)) = b(loop1-nline);
        H(loop1, branches(loop1-nline, 1)) = -b(loop1 - nline);
    elseif loop1 > 2*nline
        curBus = mpccase.bus(loop1 - 2*nline, BUS_I);
        %fneigh = find(mpccase.branch(:, F_BUS) == curBus);
        %H(loop1, :) = H(loop1, :) + sum(H(fneigh, :), 1);
        %tneigh = find(mpccase.branch(:, T_BUS) == curBus);
        %H(loop1, :) = H(loop1, :) + sum(H(tneigh+nline, :), 1);
        neigh = find(deviceI(1:2*nline) == curBus);
        H(loop1, :) = H(loop1, :) + sum(H(neigh, :), 1);
    end
end

end
