clear; clc; close all;


dirname = '/home/hugo/experiment/PowerSDN/Spoof/';
%cases = {'case24', 'case30', 'caseRTS96i'};
cases = {'case24', 'case30', 'caseRTS96i', 'case118', 'case2737sop-1','case2737sop-3'};
%xticknames = {'IEEE\n24bus', 'IEEE\n30bus', 'IEEE\nRTS96', 'Poland 2737bus\narea 1', 'Poland 2737bus\narea 2', 'Poland 2737bus\narea 3'};
xticknames = {'IEEE\n24bus', 'IEEE\n30bus', 'IEEE\nRTS96', '2737bus\narea 1', '2737bus\narea 2', '2737bus\narea 3'};
%xticknames = {'IEEE\\24bus', 'IEEE\\30bus', 'IEEE RTS96', 'Poland 2737bus area 1', 'Poland 2737bus area 2', 'Poland 2737bus area 3'};
%analysis = 'pf';
analysis = 'fdi';

fwid = 3.2;
fhei = 1.7;
dpi = 200;
screendpi = 96;

version = 'v6';

colors = {'r', 'k', 'b'};

all_pr = {};
for loop1 = 1 : length(cases)
    %resultfile = sprintf('%s%s-%s.mat', dirname, cases{loop1}, analysis);
    resultfile = sprintf('%s%s-%s%s.mat', dirname, cases{loop1}, analysis, version);
    curhandle = load(resultfile);
    cur
    pr = calConInterval(curhandle.all_result, 100);
    all_pr{loop1} = pr;
    tvalues(loop1) = mean(curhandle.all_edgetime) ./ mean(curhandle.all_bigtime);
end


figure;

left_color = [0 0 0];
right_color = [0 0 0];
set(gcf,'defaultAxesColorOrder',[left_color; right_color]);

%set(gcf,'units','normalized', 'OuterPosition', [0, 0, 1, 1], 'position', [0.1, 0.1, 0.85, 0.85]);
%set(gcf,'units','normalized', 'position',[0.05, 0.05, 0.9, 0.8]);
%set(gcf,'units','normalized', 'OuterPosition',[0.05, 0.05, 0.9, 0.9]);
%set(gcf, 'units', 'inches', 'Position', [10, 5, fwid, fhei]);
set(gcf, 'units', 'pixels', 'Position', [1000, 500, fwid * screendpi, fhei * screendpi]);

yvalues = zeros(1, length(all_pr));
evalues = zeros(1, length(all_pr));

for loop1 = 1 : length(all_pr)
    yvalues(loop1) = all_pr{loop1}.meanA;
    evalues(loop1) = all_pr{loop1}.ci95A;
end

%{
for loop1 = 1 : length(all_pr)
    h = bar(loop1, yvalues(loop1));
    hold on;
    set(h, 'FaceColor', colors{loop1}); 
end
%}
ax1 = axes('units', 'normalized','Position',[0.14 0.14 0.74 0.8]);
%xlocation = [10 20 30 45 60 75];
xlocation = [10 20 30 40 50 60];
assert(length(xlocation) == length(all_pr));
greycolor = [0.6 0.6 0.6];
yyaxis left
%bb = bar([1:length(all_pr)], yvalues, 'FaceColor', greycolor, 'EdgeColor', greycolor, 'BarWidth', 0.75);
bb = bar(ax1, xlocation, yvalues, 'FaceColor', greycolor, 'EdgeColor', greycolor, 'BarWidth', 0.75);
ylim([0.5, 1.05]);
%xlim([(1 - 0.5) (length(all_pr)+0.5)]);
xlim([(xlocation(1) - 5) (xlocation(6) + 5)]);
yyaxis right
%pp = plot([1:length(all_pr)], tvalues, ':k*', 'LineWidth', 4, 'MarkerSize', 20, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
pp = plot(ax1, xlocation, tvalues, ':k*', 'LineWidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r');
%set(pp, 'position', [1, 1, 0.85, 0.85]);
%ylim([0, max(tvalues) * 1.35]);
%%hold on;
%%errorbar(yvalues, evalues, '.');
%plot([1:10], [2:2:20], ':', 'Color', 'r', 'LineWidth', 4);

xt = get(gca, 'XTick');
%set(gca, 'FontName', 'Times New Roman', 'FontSize', 16);
set(gca,'xticklabel', []) %Remove tick labels
%set(gca,'xtick',[1 : length(all_pr)],'xticklabel', xticknames)
yt = get(gca, 'YTick');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 6);

%% using textbox to set ticks
xTicks = get(gca, 'xtick');
yTicks = get(gca,'ytick');
minX = min(xTicks);
minY = min(yTicks);

VerticalOffset = (yTicks(2)-yTicks(1))/2;
HorizontalOffset = 0.2;
for xx = 1:length(xTicks)
    %text(xTicks(xx) - HorizontalOffset, minY - VerticalOffset, ['$$\begin{array}{c}',num2str( xTicks(xx)),'\\',num2str( 2*xTicks(xx)),'\end{array}$$'], 'Interpreter', 'latex')
    text(xTicks(xx), minY - VerticalOffset, sprintf(xticknames{xx}), 'HorizontalAlignment', 'center', 'FontSize', 6);
    %text(xTicks(xx), minY - VerticalOffset, ['$$\begin{array}{c}',xticknames{xx},'\end{array}$$'], 'Interpreter', 'latex')

    %text(xTicks(xx), minY-0.01, sprintf('\nhello\n1\n2'));
end
%% using textbox to set ticks

%xlabel('Power System', 'FontName', 'Times New Roman', 'FontSize', 30);

%ax = gca;
%yyaxis left
%ax.FontSize = 30;
%yyaxis right
%ax.FontSize = 16;

yyaxis left
ylabel('Accuracy', 'FontName', 'Times New Roman', 'FontSize', 6.5);
a=[cellstr(num2str(get(gca,'ytick')'*100))]; 
% Create a vector of '%' signs
pct = char(ones(size(a,1),1)*'%'); 
% Append the '%' signs after the percentage values
new_yticks = [char(a),pct];
% 'Reflect the changes on the plot
set(gca,'yticklabel',new_yticks) 

yyaxis right
ylabel(sprintf('Normalized Execution Time'), 'FontName', 'Times New Roman', 'FontSize', 6.5);
a=[cellstr(num2str(get(gca,'ytick')'*100))]; 
% Create a vector of '%' signs
pct = char(ones(size(a,1),1)*'%'); 
% Append the '%' signs after the percentage values
new_yticks = [char(a),pct];
% 'Reflect the changes on the plot
set(gca,'yticklabel',new_yticks) 

figuredir = '/home/hugo/Dropbox/\!Research/Proposals/\!EdgeforResilience/NSF/Figures/';
figurename = sprintf('%s%s', figuredir, 'SEPrelim');
%figurename = 'SEPrelim';

%print(figurename, '-dsvg')
%print(figurename, '-dpng')
%fig = gcf;
%fig.PaperUnits = 'inches';
%fig.PaperPosition = [0 0 3.18 2.37];
%set(gcf, 'PaperUnits', 'inches');
%set(gcf, 'PaperPosition', [0 0 fwid fhei]);
%print(figurename, '-djpeg','-r200')
print(figurename, '-dpng','-r200')
%saveas(gcf, figurename, 'jpg')
