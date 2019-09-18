%% choose the system you want to work with
setup2;

% for rank/zero conditions, try to match the precision of cvx_precision low
% http://cvxr.com/cvx/doc/solver.html#solver-precision
eps = 2.22e-16;
tol = eps.^(3/8);
close all;

settings = AltImplSettings;
%% sandbox
% modes: ImplicitOpt, ExplicitOpt, Analytic, ApproxDrop, ApproxLeaky
settings.mode_      = AltImplMode.Analytic;
%settings.clDiffPen_ = 1e4;
%settings.relaxPct_  = 0.6;

Tc          = round(slsParams.tFIR_/2);
slsOuts_alt = find_alt_impl(sys, slsParams, slsOuts, Tc, settings);

s_a{1}  = slsOuts_alt;

met     = AltImplMetrics(tol, Tc);
met     = calc_mtx_metrics(met, sys, slsParams, slsOuts, s_a);
met     = calc_cl_metrics(met, sys, simParams, slsParams, slsOuts, s_a);
met

visualize_matrices(slsOuts, slsOuts_alt, Tc, 'all');

% check solver/feasibility statuses
disp(['Statuses:', print_statuses(sys, slsParams, slsOuts, s_a, tol)]);

%% find new impl over different Tcs
settings.mode_      = AltImplMode.ApproxLeaky;
settings.clDiffPen_ = 1e3;

Tcs    = 2:slsParams.tFIR_;
numTcs = length(Tcs);
slsOuts_alts = cell(numTcs, 1);
for idx=1:numTcs
    Tc = Tcs(idx);
    slsOuts_alts{idx} = find_alt_impl(sys, slsParams, slsOuts, Tc, settings);
end

scanH1 = slsOuts_alts;
%% find new impl over different approximations (ApproxDrop) 
Tc = round(slsParams.tFIR_/2);

settings       = AltImplSettings;
settings.mode_ = AltImplMode.ApproxDrop;
relaxPcts      = 0.05:0.05:1; 
numRelaxPcts   = length(relaxPcts);

slsOuts_alts   = cell(numRelaxPcts, 1);
for idx=1:numRelaxPcts
    settings.relaxPct_ = relaxPcts(idx);
    slsOuts_alts{idx}  = find_alt_impl(sys, slsParams, slsOuts, Tc, settings);
end

%% find new impl over different approximations (ApproxLeaky)
Tc = round(slsParams.tFIR_/4);

settings       = AltImplSettings;
settings.mode_ = AltImplMode.ApproxLeaky;
clDiffPens     = 1:6; % powers
numClDiffs     = length(clDiffPens);

slsOuts_alts   = cell(numClDiffs, 1);
for idx=1:numClDiffs
    settings.clDiffPen_ = 10^(clDiffPens(idx));
    slsOuts_alts{idx}  = find_alt_impl(sys, slsParams, slsOuts, Tc, settings);
end

%% check feasibility / solver statuses
disp(['Statuses:', print_statuses(sys, slsParams, slsOuts, slsOuts_alts, tol)]); 

%% plot stuff
% we might not want to plot all of slsOuts_alts, so this is the sandbox to
% adjust which slsOuts_alts to plot

sweepParamName = 'Tc';
%sweepParamName = 'relaxPct';
%sweepParamName = 'clDiffPen';

if strcmp(sweepParamName, 'Tc')
    xSeries = Tcs;
    xSize   = numTcs;
elseif strcmp(sweepParamName, 'relaxPct')
    xSeries = relaxPcts;
    xSize   = numRelaxPcts;
else
    xSeries = clDiffPens;
    xSize   = numClDiffs;    
end

% can specify which x to plot
xWanted = xSeries;
myIdx   = [];

for i=1:xSize
    x = xSeries(i);
    if find(abs(xWanted-x)<eps) % ismember doesn't work well with floats
        myIdx = [myIdx, i];
    end
end

xPlot            = xSeries(myIdx);
slsOuts_altsPlot = slsOuts_alts(myIdx);

if strcmp(sweepParamName, 'Tc')
    met = AltImplMetrics(tol, xPlot);
else
    met = AltImplMetrics(tol, Tc, sweepParamName, xPlot);
end

% calculate matrix-specific metrics
met = calc_mtx_metrics(met, sys, slsParams, slsOuts, slsOuts_altsPlot);

% calculate closed-loop metrics and plot select heat maps
met = calc_cl_metrics(met, sys, simParams, slsParams, slsOuts, slsOuts_altsPlot);

% plot metrics and save to file
savepath = 'C:\Users\Lisa\Desktop\caltech\research\implspace\tmp\';
plot_metrics(met, savepath);

% print again
disp(['Statuses:', print_statuses(sys, slsParams, slsOuts, slsOuts_alts, tol)]);  