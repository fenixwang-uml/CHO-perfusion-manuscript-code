% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
%% DT_OptimizeCOGs.m
% Optimize bioreactor operating conditions to minimize Cost of Goods (COGs)
%
% OBJECTIVE (select via OBJ_MODE):
%   Mode 1 .  Minimize media_cost / TotalMAbHarvested  (cost per mg mAb)
%   Mode 2 .  Minimize media_cost / Final VCD        (cost per milcells/mL)
%
% DECISION VARIABLES:
%   x(1) = Perfusion Rate  [VVD]      bounds: [0, 2]
%   x(2) = Recycle Ratio   [0–1]      bounds: [0, 1]
%
% CONSTRAINTS (nonlinear, output-dependent .  enforced via penalty):
%   TotalMAbHarvested  >= MIN_TAH     (mg)
%   FinalTiter         >= MIN_TITER   (mg/mL)
%
% SOLVER: surrogateopt  (Global Optimization Toolbox)
%   Ideal for expensive black-box simulations. Falls back to ga if unavailable.
%
% USAGE:
%   Run this script after confirming that the Simulink model "DT_GeneralFSM"
%   and all supporting files (DT_manuscript_parameters.m, iCHO3K.mat, DT_generatedata.m)
%   are on the MATLAB path.
% -------------------------------------------------------------------------

%% ========= USER CONFIGURATION =========================================

OBJ_MODE   = 1;          % 1 = mab COGs | 2 = cell COGs

% --- Constraint thresholds (set to 0 to disable) -----------------------

MIN_TAH    = 8000;       % Minimum acceptable TotalMAbHarvested (mg)
MIN_VCD  = 40;        % Minimum acceptable VCD (million cells/mL)
Constrain = [MIN_TAH MIN_VCD];
% --- Media cost coefficient (cost per mL of fresh media used) ----------
MEDIA_COST_PER_ML = 0.15; % Normalised cost unit; adjust to your media price

% --- Penalty weight for constraint violation ---------------------------
% A large number relative to expected COGs. Tune if optimiser misbehaves.
PENALTY_WEIGHT = 1e6;

% --- Surrogate budget --------------------------------------------------
MAX_EVALS  = 80;         % Max Simulink calls (each call ~seconds–minutes)

% ========= PROCESS FIXED PARAMETERS ====================================
process = 'Spent Media Recycling';
totalday = 20;              % Total simulation days
perfusionratestart = 3;     % Day perfusion starts
recyclestart = 10;           % Day recycling starts
media_name = 'AMBIC11';     % Media sheet to load
endtime = totalday * 24;    % Total simulation hours

% Bioreactor Initial Values
V1.volume = 50000; V1.Vinit = 50000; % Feed1
V2.volume = 3000;  V2.Vinit = 1600;  % Bioreactor
V3.volume = 20000; V3.Vinit = 10000; % Glucose
V4.volume = 20000; V4.Vinit = 50000; % Feed2
V5.volume = 20000; V5.Vinit = 50000; % Feed3
V6.volume = 20000; V6.Vinit = 0;     % Bleed Bag
V7.volume = 20000; V7.Vinit = 0;     % Product Harvest Bag
V8.volume = 20000; V8.Vinit = 0;     % Spent Media Bag
% ========================================================================

%% 1. INITIALISE COBRA TOOLBOX & GENOME-SCALE MODEL (once)
if ~exist('initcbtb_done', 'var')
    initCobraToolbox(false);
    initcbtb_done = true;
end

phase = 1;

% For a sweep, we hardcode the model choices to avoid UI prompts pausing the code
GSmode = 0;
if GSmode == 1
    solverName = 'gurobi';
    solverType = 'LP';
    modelsolver = changeCobraSolver(solverName, solverType);

    % Load Model
    load('iCHO3K.mat')
    model_work = iCHO3K;

    % Set Objective
    objective.rxnname = 'biomass_cho_s';
    objective.rxnid = findRxnIDs(model_work, objective.rxnname);
    objective.rxnidprod = findRxnIDs(model_work, 'igg_formation');

    if objective.rxnid == 0
        error('Objective Rxn Not Found. Check your model.');
    else
        disp('Running Genome-Scale model integrated with Kinetic Model...');
        model_obj = changeObjective(model_work, model_work.rxns(objective.rxnid));
        model_obj_prod = changeObjective(model_work, model_work.rxns(objective.rxnidprod));
    end
    save('temp_model_obj.mat', '-struct', 'model_obj');
    save('temp_model_obj_prod.mat', '-struct', 'model_obj_prod');
else
    disp('Running Kinetic Only mode...');
end

%% 2. LOAD KINETIC PARAMETERS (once)
[K_ht, K_lt] = DT_manuscript_parameters();

%% 3. PRE-LOAD SIMULINK MODEL WITH FAST RESTART
mdl = "DT_GeneralFSM";
load_system(mdl);
set_param(mdl, 'FastRestart', 'on');
set_param(mdl, 'StopTime', num2str(endtime));

%% 4. DEFINE THE BLACK-BOX OBJECTIVE FUNCTION


%% 5. BOUNDS FOR DECISION VARIABLES
%   x(1) = Perfusion Rate  [0, 2]   VVD
%   x(2) = Recycle Ratio   [0, 1]
lb = [0,   0];
ub = [2.0, 1.0];

%% 6. RUN OPTIMISATION
fprintf('\n======================================================\n');
fprintf(' COGs Minimisation .  OBJ_MODE %d\n', OBJ_MODE);
fprintf(' MIN_TAH = %.1f mg   |   MIN_VCD = %.3f milcells/mL\n', MIN_TAH, MIN_VCD);
fprintf(' Budget  = %d Simulink evaluations\n', MAX_EVALS);
fprintf('======================================================\n\n');

% Wrap nested function into anonymous handle expected by solvers
obj_handle = @(x) DT_COGobj(x,OBJ_MODE,PENALTY_WEIGHT,Constrain);


    disp('Solver: surrogateopt (Global Optimization Toolbox)');

    options = optimoptions('surrogateopt', ...
        'Display', 'iter', ...
        'UseParallel', false, ...     % Turn this to false if you don't have the Parallel Computing Toolbox
        'MaxFunctionEvaluations', MAX_EVALS); % Limit evaluations so it doesn't run forever

    [x_opt, fval_opt, exitflag, output, trials] = ...
        surrogateopt(obj_handle, lb, ub, options);

%% 7. RECOVER FULL KPIs AT OPTIMAL POINT
fprintf('\n--- Re-running optimal point for full KPI extraction ---\n');
[opt_obj, opt_sim] = DT_COGobj(x_opt, OBJ_MODE, PENALTY_WEIGHT,Constrain);

% Unpack for readability
opt_perf     = x_opt(1);
opt_rec      = x_opt(2);
opt_media    = opt_sim.mediaused;
opt_TTA      = opt_sim.final_TTA;
opt_VCD      = opt_sim.final_VCD;
opt_COGs     = opt_obj.Fval; % Extract objective value from the structure

%% 8. TURN OFF FAST RESTART
set_param(mdl, 'FastRestart', 'off');

%% 9. PRINT RESULTS TABLE
fprintf('\n╔══════════════════════════════════════════════════╗\n');
fprintf(  '║             OPTIMISATION RESULTS                 ║\n');
fprintf(  '╠══════════════════════════════════════════════════╣\n');
fprintf(  '║  Optimal Perfusion Rate  : %8.1f VVD             ║\n', opt_perf);
fprintf(  '║  Optimal Recycle Ratio   : %8.1f                 ║\n', opt_rec);
fprintf(  '╠══════════════════════════════════════════════════╣\n');
fprintf(  '║  Fresh Media Consumed    : %2.2f mL              ║\n', opt_media);
fprintf(  '║  Total mAb Harvested     : %8.2f mg              ║\n', opt_TTA);
fprintf(  '║  Final VCD               : %8.2f milcells/mL     ║\n', opt_VCD);
fprintf(  '║  Objective (COGs proxy)  : %8.2f                 ║\n', opt_COGs);
fprintf(  '╠══════════════════════════════════════════════════╣\n');

% Constraint check
st_TAH='N/A';st_tit='N/A';
if OBJ_MODE==1, if  opt_TTA >= MIN_TAH,   st_TAH='PASS'; else, st_TAH='FAIL'; end, end 
if OBJ_MODE==2, if  opt_VCD >= MIN_VCD,   st_tit='PASS'; else, st_tit='FAIL'; end, end
fprintf(  '║  Constraint: TAH >= %.0f mg    [%s]            ║\n', MIN_TAH, st_TAH);
fprintf(  '║  Constraint: VCD >= %.3f milcells/mL [%s]      ║\n', MIN_VCD, st_tit);
fprintf(  '╚══════════════════════════════════════════════════╝\n\n');

%% 10. SAVE RESULTS
if ~exist('out', 'dir'), mkdir('out'); end

result_table = table(opt_perf, opt_rec, opt_media, opt_TTA, opt_VCD, opt_COGs, ...
    'VariableNames', {'OptPerfusion','OptRecycle','MediaUsed_mL', ...
                      'TotalMAbHarvested_mg','FinalVCD_milcells_mL','COGs_Objective'});
writetable(result_table, 'out/out_Optimisation_Result.csv');
fprintf('Results saved to out/out_Optimisation_Result.csv\n');

% If surrogateopt was used, save the full trials table
if ~isempty(trials)
    trials_table = array2table(trials.X, 'VariableNames', {'PerfusionRate','RecycleRatio'});
    trials_table.COGs_Objective = trials.Fval;
    % Surrogateopt also saves constraint violations in trials.Ineq
    writetable(trials_table, 'out/out_Optimisation_Trials.csv');
    fprintf('All trial points saved to out/out_Optimisation_Trials.csv\n');
end

%% 11. VISUALISE OPTIMUM ON PARAMETER SPACE
fprintf('\nGenerating COGs landscape plot (25 evaluations)...\n');

perf_vec = linspace(0, 2.0, 5);
rec_vec  = linspace(0, 1.0, 5);
[P_mesh, R_mesh] = meshgrid(perf_vec, rec_vec);
COGs_map = nan(size(P_mesh));

for pi = 1:numel(perf_vec)
    for ri = 1:numel(rec_vec)
        eval_struct = DT_COGobj([perf_vec(pi), rec_vec(ri)], OBJ_MODE, PENALTY_WEIGHT,Constrain);
        
        % For visualising the landscape, we'll manually add a soft penalty 
        % back in so infeasible regions are easily visible on the heatmap
        penalty = sum(max(0, eval_struct.Ineq)) * (PENALTY_WEIGHT / 1e4);
        COGs_map(ri, pi) = eval_struct.Fval + penalty;
    end
end

fig2 = figure('Name','COGs Landscape','Color','w','Position',[150,150,700,500]);
contourf(P_mesh, R_mesh, COGs_map, 20, 'LineStyle','none');
cb = colorbar; cb.Label.String = 'COGs Proxy (Penalized)';
colormap('parula');
hold on;
plot(opt_perf, opt_rec, 'rp', 'MarkerSize', 18, 'MarkerFaceColor','r', ...
     'DisplayName','Optimum');
legend('Location','best');
xlabel('Perfusion Rate (VVD)');
ylabel('Recycle Ratio');
title(sprintf('COGs Landscape (Mode %d) .  Optimal: P=%.3f, R=%.3f', ...
              OBJ_MODE, opt_perf, opt_rec));
saveas(fig2, 'out/out_COGs_Landscape.png');
fprintf('Landscape plot saved to out/out_COGs_Landscape.png\n');