function zone_case = extract_zone(casefile, zone_num)

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%mpccase = case5;
%casefile = case24_ieee_rts;
%casefile = case30;
%casefile = case39;
%bigcase = mUnBrch(case2383wp);
bigcase = mUnBrch2(casefile);
%bigcase = mUnBrch(case2737sop);
%bigcase = mUnBrch(case2746wop);
%bigcase = caseRTS96i;
%% consider area one by one to study different scale
% area 2: 278 buses;
% area 3: 871 buses;
% area 4: 547 buses;
%converged_area = [2,3,4];
%converged_area = [2];
converged_area = zone_num;
%% extract casefile for each area one by one
base_result = runpf(bigcase, mpoption('VERBOSE', 0, 'OUT_ALL', 0, 'PF_ALG', 1, 'PF_MAX_IT', 50, 'PF_TOL', 1e-6));

% find all tie-lines; maintain the original orders
tie_lines = [];
tie_line_index = [];
i = 1;
all_brch = bigcase.branch(:, [F_BUS, T_BUS]);
for loop1 = 1 : length(all_brch(:,1))
    f_bus = all_brch(loop1, 1);
    t_bus = all_brch(loop1, 2);
    if bigcase.bus(f_bus, ZONE) ~= bigcase.bus(t_bus, ZONE)
        tie_lines(i, :) = [f_bus, t_bus, bigcase.bus(f_bus, ZONE), bigcase.bus(t_bus, ZONE)];
        tie_line_index(i) = loop1;
        i = i + 1;
    end
end

%area_num = unique(bigcase.bus(:, BUS_AREA));
area_num = unique(bigcase.bus(:, ZONE));
all_area_cases = {};
casefile.baseMVA = bigcase.baseMVA;
casefile.version = '2';
for loop1 = 1:length(area_num)
    %% construct bus
    cur_area = area_num(loop1);
    cur_busi = bigcase.bus(:, ZONE) == cur_area;  % note that logical array
    casefile.bus = bigcase.bus(cur_busi, :);
    new_to_old1 = casefile.bus(:, BUS_I)  ; % indexed by new bus index which is in order
    old_to_new1 = zeros(length(bigcase.bus(:,1)),1);
    for loop2 = 1 : length(new_to_old1)
        old_to_new1(new_to_old1(loop2)) = loop2;
    end
    casefile.bus(:, BUS_I) = old_to_new1(casefile.bus(:, BUS_I));
    % find all generators
    genbus = find(casefile.bus(:, BUS_TYPE) ~= PQ);
    % decide reference buses
    refbus = find(casefile.bus(:, BUS_TYPE) == REF);
    if isempty(refbus) == 1
        casefile.bus(genbus(1), BUS_TYPE) = REF; 
    end    
    %% construct generators
    casefile.gen = bigcase.gen(ismember(bigcase.gen(:, GEN_BUS), new_to_old1), :);
    casefile.gen(:, GEN_BUS) = old_to_new1(casefile.gen(:, GEN_BUS));
    %% construct generator cost
    casefile.gencost = bigcase.gencost(ismember(bigcase.gen(:, GEN_BUS), new_to_old1), :);
    %% construct branches
    brch_index = find( ismember(bigcase.branch(:, F_BUS), new_to_old1 ) & ismember(bigcase.branch(:, T_BUS), new_to_old1));
    casefile.branch = bigcase.branch(brch_index, :);
    casefile.branch(:, F_BUS) = old_to_new1(casefile.branch(:, F_BUS)); 
    casefile.branch(:, T_BUS) = old_to_new1(casefile.branch(:, T_BUS)); 
    % use tie line power flow to update load demands of each substation
    out_line_index = tie_line_index((tie_lines(:, 3) == cur_area)); % index of power flow deliver power to other areas    
    for loop2 = 1 : length(out_line_index)
        cur_i = out_line_index(loop2);
        f_bus = bigcase.branch(cur_i, F_BUS);
        t_bus = bigcase.branch(cur_i, T_BUS);
        f_bus_new = old_to_new1(f_bus);
        casefile.bus(f_bus_new, PD) = casefile.bus(f_bus_new, PD) + base_result.branch(cur_i, PF);
        casefile.bus(f_bus_new, QD) = casefile.bus(f_bus_new, QD) + base_result.branch(cur_i, QF);
    end
    in_line_index = tie_line_index((tie_lines(:, 4) == cur_area)); % index of power flow deliver power to other areas    
    for loop2 = 1 : length(in_line_index)
        cur_i = in_line_index(loop2);
        f_bus = bigcase.branch(cur_i, F_BUS);
        t_bus = bigcase.branch(cur_i, T_BUS);
        t_bus_new = old_to_new1(t_bus);
        casefile.bus(t_bus_new, PD) = casefile.bus(t_bus_new, PD) - base_result.branch(cur_i, PT);
        casefile.bus(t_bus_new, QD) = casefile.bus(t_bus_new, QD) - base_result.branch(cur_i, QT);
    end
    % choose a largest islands in the casefile
    [groups, isolated] = find_islands(casefile);
    if length(groups) == 0
        area_num(loop1) == [];
        continue;
    else 
        mpc_array = extract_islands(casefile, groups);
        % find mpc_array with the largest size
        for loop2 = 1 : length(mpc_array)
            cur_mpc = mpc_array{loop2};
            temp_busn(loop2) = length(cur_mpc.bus(:, 1));
        end
        [M, I] = max(temp_busn);
        cur_mpc = mpc_array{I};
        %[oldref, oldpv, oldpq] = bustypes(casedata.bus, casedata.gen);
        cRef = find(cur_mpc.bus(:, BUS_TYPE) == REF);
        cPv  = find(cur_mpc.bus(:, BUS_TYPE) == PV);
        cPq  = find(cur_mpc.bus(:, BUS_TYPE) == PQ);
        if length(cPv) == 0
            continue;
        end
        if length(cRef) == 0
            cRef = cPv(1);
            %tempI = find(curMpc.bus(:, BUS_I) == cPv(1) );
            cur_mpc.bus(cRef, BUS_TYPE) = REF;
            cPv = cPv(2:length(cPv))
        end
        new_to_old2 = cur_mpc.bus(:, BUS_I);
        old_to_new2 = zeros(length(casefile.bus(:,1)),1);
        for loop2 = 1 : length(new_to_old2)
            old_to_new2(new_to_old2(loop2)) = loop2;
        end
        cur_mpc.bus(:, BUS_I) = old_to_new2(cur_mpc.bus(:, BUS_I));
        cur_mpc.gen(:, GEN_BUS) = old_to_new2(cur_mpc.gen(:, GEN_BUS));
        cur_mpc.branch(:, F_BUS) = old_to_new2(cur_mpc.branch(:, F_BUS));
        cur_mpc.branch(:, T_BUS) = old_to_new2(cur_mpc.branch(:, T_BUS));
    end
    all_area_cases{loop1} = cur_mpc;
end

zone_case = all_area_cases{area_num == zone_num};

end
