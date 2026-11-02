clear; close all; clc;

addpath(genpath('/home/hugo/Dropbox/Experiments/matpower5.0'));
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

SAVEFIG = 0;

caseindex = 3;
%keys = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop-1', 'case2737sop-3'};
%keys = {'case24', 'case30', 'caseRTS96i', 'case118'};
keys = {'case24', 'case30', 'case_RTS_GMLC', 'case118', 'case2737sop-1'};
%keys = {'case24', 'case30', 'case_RTS_GMLC', 'case118'};

bias = 1e-6;

all_fp = {};
all_fp_error_mean = {};
all_fp_error_ci95 = {};
for loop0 = 1 : length(keys)
    workspace = load(sprintf('./%s-ro3FPN.mat', keys{loop0}));
    [fake_n, compromise_n, sample] = size(workspace.spoof_error);
    fp = zeros(1, fake_n);
    fp_error_mean = zeros(1, fake_n); 
    fp_error_ci95 = zeros(1, fake_n);


    for loop1 = 1 : fake_n
        temp_spoof_error = [];
        for loop2 = 1 : compromise_n
            valid_index = ( workspace.spoof_error(loop1, loop2, :) > 0 );
            %fprintf('DEBUG %d %d\n', sum(valid_index), sample);
            %assert(sum(valid_index) == sample);
            temp_spoof_error = [temp_spoof_error, reshape(workspace.spoof_error(loop1, loop2, valid_index), [1, sum(valid_index)])];
        end
        fp_index = ( temp_spoof_error > 1 );
        n_fp = sum(fp_index);
        fp(loop1) = n_fp / length(temp_spoof_error);
            
        temp_result = calConInterval(temp_spoof_error);
        fp_error_mean(loop1) = temp_result.meanA;
        fp_error_ci95(loop1) = temp_result.ci95A;
    end
    all_fp{loop0} = fp;
    all_fp_error_mean{loop0} = fp_error_mean;
    all_fp_error_ci95{loop0} = fp_error_ci95;
end

all_fn = {};
all_fn_error_mean = {};
all_fn_error_ci95 = {};
all_error_amp_mean = {};
all_error_amp_ci95 = {};

for loop0 = 1 : length(keys)
    workspace = load(sprintf('./%s-ro3FPN.mat', keys{loop0}));
    [fake_n, compromise_n, sample] = size(workspace.fdi_error);
    fn = zeros(fake_n, compromise_n);
    fn_error_mean = zeros(fake_n, compromise_n);
    fn_error_ci95 = zeros(fake_n, compromise_n);
    error_amp_mean = zeros(fake_n, compromise_n);
    error_amp_ci95 = zeros(fake_n, compromise_n);
    
    for loop1 = 1 : fake_n
        for loop2 = 1 : compromise_n
            fn_index = abs(workspace.fdi_error(loop1, loop2, :)) < 1;
            n_fn = sum(fn_index);
            fn(loop1, loop2) = n_fn / sample;
            
            temp_result = calConInterval(workspace.fdi_error(loop1, loop2, :));
            fn_error_mean(loop1, loop2) = temp_result.meanA;
            fn_error_ci95(loop1, loop2) = temp_result.ci95A;
            
            error_amp_cur = workspace.fdi_error(loop1, loop2, :) ./ workspace.ref_error(loop1, loop2, :);
            temp_result = calConInterval(error_amp_cur);
            error_amp_mean(loop1, loop2) = temp_result.meanA;
            error_amp_ci95(loop1, loop2) = temp_result.ci95A;
        end
    end
    
    all_fn{loop0} = fn;
    all_fn_error_mean{loop0} = fn_error_mean;
    all_fn_error_ci95{loop0} = fn_error_ci95;
    all_error_amp_mean{loop0} = error_amp_mean;
    all_error_amp_ci95{loop0} = error_amp_ci95;
end

%% test to draw fn
figure;
set(gcf,'units','normalized', 'position',[0.05, 0.05, 0.4, 0.6]);
ax1 = axes('units', 'normalized','Position',[0.23 0.2 0.72 0.7]);
hold on;

gap = 0.075;
marksize = 15;

fake_p = [0.01 : 0.01 : 0.2];
compromise_p = [0.1 : 0.1 : 1];

fn_threshold = 0.01;

for loop0 =  1 : length(all_fn)
    fn_rec = all_fn{loop0};
    [fake_n, compromise_n] = size(fn_rec);
    assert(fake_n == length(fake_p));
    assert(compromise_n == length(compromise_p));
    for loop1 = 1 : fake_n
        for loop2 = 1 : compromise_n
            if fn_rec(loop1, loop2) <= fn_threshold
                y(loop0, loop1) = compromise_p(loop2);
                x(loop0, loop1) = fake_p(loop1);
                break;
            end
        end
    end
end

p1 = plot(x(1,:), y(1,:), '-rx', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
hold on;
p2 = plot(x(2,:), y(2,:), '--go', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
p3 = plot(x(3, :), y(3,:), ':b*', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
p4 = plot(x(4, :), y(4,:), '-.cs', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'c');
%p5 = plot(x(5, :), y(5,:), '-md', 'LineWidth', 1, 'MarkerSize', marksize, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
ylim([0, 1.1]);
xlim([0, 0.23]);

yt = get(gca, 'YTick');
yticknames = {'0'};
for loop0 = 2 : length(yt)
    yticknames{loop0} = sprintf('%d%%', floor(yt(loop0) * 100));
end
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 25);
%set(gca,'yticklabel', yticknames, 'FontName', 'Times New Roman', 'FontSize', 30);
ax1.YTickLabel = yticknames;
ax1.YAxis.FontName = 'Times New Roman';
ax1.YAxis.FontSize = 25;
ax1.YAxis.Label.String = sprintf('Percentage of Compromised Data\n(in Active Attacks)');
ax1.YAxis.Label.FontName = 'Times New Roman';
ax1.YAxis.Label.FontSize = 28;

xt = get(gca, 'XTick');
xticknames = {'0'};
for loop0 = 2 : length(xt)
    xticknames{loop0} = sprintf('%d%%', floor(xt(loop0) * 100));
end
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 25);
%set(gca,'yticklabel', yticknames, 'FontName', 'Times New Roman', 'FontSize', 30);
ax1.XTickLabel = xticknames;
ax1.XAxis.FontName = 'Times New Roman';
ax1.XAxis.FontSize = 25;
ax1.XAxis.Label.String = sprintf('Percentage of Virtual Nodes\n(in Reconnaissance)');
ax1.XAxis.Label.FontName = 'Times New Roman';
ax1.XAxis.Label.FontSize = 28;

lgd_name = {'Case 1', 'Case 2', 'Case 3', 'Case 4', 'Case 5', 'Case 6'};
lgd = legend([p1 p2, p3, p4], lgd_name{1}, lgd_name{2}, lgd_name{3}, lgd_name{4});
lgd.FontSize = 25;

figuredir = 'C:\Users\hlin2\Dropbox\!Research\!!SDNPreemptive\20190904_DefRec\Figures\';
figurename = sprintf('%s%s', figuredir, 'FigDecoyFN');
if (SAVEFIG == 1)
    print(figurename, '-depsc','-r400');
end
