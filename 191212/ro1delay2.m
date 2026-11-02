clear; close all; clc;

%cur_case = 'case24';
SAVEFIG = 0;

keys = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop-1', 'case2737sop-3'};
values = { 24 + 34, 30 + 41, 73 + 108, 118 + 179, 406 + 467, 1153 + 1307};
hyper_p = containers.Map(keys, values);

packet_lat = 1;  % second
r = 0.05;

%ratio_compromise = [0.1, 0.2, 0.3, 0.4, 0.5];
ratio_compromise = [0.1:0.01: 0.5];


%all_delays = [100, 200, 300, 400, 500];
all_delays = [100, 1000, 10000, 100000];

y = []; 
for loop0 = 1 : length(all_delays)
    %delay_target = 100; % in years;
    delay_target = all_delays(loop0);

    delay_target_seconds = delay_target * 365 * 24 * 60 * 60;

    % find nf that satisfy the delay_target

    for loop1 = 1 : length(keys)
            
        cur_case = keys{loop1};     
        
        nreal = hyper_p(cur_case);

        for loop2 = 1 : length(ratio_compromise)
            ncompromise = floor(nreal * ratio_compromise(loop2));

            for loop3 = 1 : nreal
                np = floor( (nreal - ncompromise )* (1-r));
                nf = loop3;
                prob_guess = 1 /( nchoosek(nreal, np) * nchoosek(np + nf, nf) );
                %fprintf(fileID, '%e, ', g1(loop0, loop1));
                %delay(loop0, loop1) = nreal(loop0) / g2(loop0, loop1) / 60 / 60 / 24 / 400;
                cur_delay = 1 / prob_guess * packet_lat * ncompromise;
                if cur_delay >= delay_target_seconds
                    fprintf('# of accessible virtual: %f, %f\n', nf, nf/nreal);
                    y(loop0, loop1, loop2) = nf / nreal;
                    break;
                end
            end
        end
    end


end

%% draw the figure
%{
figure;

set(gcf,'units','normalized', 'position',[0.05, 0.05, 0.5, 0.6]);
ax1 = axes('units', 'normalized','Position',[0.18 0.15 0.8 0.75]);

marksize = 20;

x = [1 : length(keys)];
gap = 0.075;

p1 = plot(x - gap * 3, y(1,:), '-rx', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
hold on;
p2 = plot(x - gap, y(2,:), '--go', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
p3 = plot(x + gap, y(3,:), ':b*', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
p4 = plot(x + gap * 3, y(4,:), '-.cs', 'LineWidth', 2, 'MarkerSize', marksize, 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'c');
%p5 = plot(afake2, delay(5,:), '-md', 'LineWidth', 1, 'MarkerSize', marksize, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'm');
%p6 = plot(afake2, delay(6,:), '--k^', 'LineWidth', 1, 'MarkerSize', marksize, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
%set(gca, 'YScale', 'log');
%ylim([]);
xlim([0.5, 6.5]);
ylim([0, 0.2]);

xticknames = {'Case 1', 'Case 2', 'Case 3', 'Case 4', 'Case 5', 'Case 6', ''};
xt = get(gca, 'XTick');
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 25);
set(gca,'xticklabel', xticknames, 'FontName', 'Times New Roman', 'FontSize', 25);

yt = get(gca, 'YTick');
yticknames = {'0'};
for loop0 = 2 : length(yt)
    yticknames{loop0} = sprintf('%d%%', floor(yt(loop0) * 100));
end
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 25);
set(gca,'yticklabel', yticknames, 'FontName', 'Times New Roman', 'FontSize', 28);

ylh = ylabel(sprintf('Average Time to Identify\nReal Devices (Years)\n'), 'FontName', 'Times New Roman', 'FontSize', 35);
set(ylh, 'Units', 'Normalized', 'Position', [-0.045, 0.5, 0]);

lgd = legend([p1 p2, p3, p4], '100 years', '1000 years', '10000 years', '100000 years');
lgd.FontSize = 30;


figuredir = '/home/hugo/Dropbox/\!Research/\!\!SDNPreemptive/20190904_DefRec/Figures';
figurename = sprintf('%s%s', figuredir, 'FigDelayPassive');
if (SAVEFIG == 1)
    print(figurename, '-depsc','-r400');
end
%}
