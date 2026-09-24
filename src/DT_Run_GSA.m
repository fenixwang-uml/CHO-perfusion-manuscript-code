% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
%dependent toolbox from matlab:
% Statistics and Machine Learning Toolbox

%% 0. Initiate of Cobra Toolbox
if ~exist('initcbtb_done', 'var')
    initCobraToolbox(false);
    initcbtb_done = true;
end

%% 1. User inputs for Simulation model selection
% Simulation mode selection
GSmode = input(['Choose the model type\n' ...
                '   [1] Kinetic + Genome-Scale Model\n' ...
                '   [2] Kinetic Only\n' ...
                'Response: ']);
if GSmode == 1
    % Select solver
    pick = input(['Choose the solver\n' ...
                    '   [1] glpk\n' ...
                    '   [2] gurobi\n' ...
                    'Response: ']);
    switch pick
        case 1
            solverName='glpk';
        case 2
            solverName='gurobi';
        otherwise
            disp('Invalid Input, simulation aborted.');
            return
    end
    solverType='LP';
    modelsolver = changeCobraSolver(solverName,solverType);
    % Select gsmodel
    pick = input(['Choose the GS Model\n' ...
                    '   [1] iCHO3K\n' ...
                    '   [2] iCHO2441\n' ...
                    '   [3] iCHO1766\n' ...
                    'Response: ']);
    switch pick
        case 1
            load('iCHO3K.mat')
            model =iCHO3K;
        case 2
            load('iCHO2441.mat')
            model = iCHO2441;
        case 3
            load('iCHO1766.mat')
        otherwise
            disp('Invalid Input, simulation aborted.');
            return
    end
    model_work = model;
    % Select objective function reaction
    pick = input(['Choose the Objective function\n' ...
                    '   [1] biomass_cho_s\n' ...
                    '   [2] biomass_cho\n' ...
                    '   [3] biomass_cho_prod\n' ...
                    '   [4] biomass_cho_producing\n' ...
                    'Response: ']);
    switch pick
        case 1
            objective.rxnname = 'biomass_cho_s';
        case 2
            objective.rxnname = 'biomass_cho';
        case 3
            objective.rxnname = 'biomass_cho_prod';
        case 4
            objective.rxnname = 'biomass_cho_producing';
        otherwise
            disp('Invalid Input, simulation aborted.');
            return
    end
    % check selected obj function reaction whether exist in model
    objective.rxnid = findRxnIDs(model,objective(1).rxnname);
    objective.rxnidprod=findRxnIDs(model,'igg_formation');

    if objective.rxnid ==0
        fprintf('Objective Rxn Not Found, Try Again.');
        return
    else
        fprintf('Objective Rxn is found as %d\n',objective.rxnid);
                disp('Running Genome-Scale model integrated with Kinetic Model...');
        model_obj = changeObjective(model_work, model_work.rxns(objective.rxnid));
        model_obj_prod=changeObjective(model_work, model_work.rxns(objective.rxnidprod));
    end
    save('temp_model_obj.mat', '-struct', 'model_obj');
    save('temp_model_obj_prod.mat', '-struct', 'model_obj_prod');
elseif GSmode == 2
        disp('Running Kinetic Only mode...');
else
    disp('Invalid Input, simulation aborted.');
    return
end
%% 2. Select experiment input
% Supply the study workbook locally. No experimental database is distributed.
datafilename = input('Full path to the 55-day perfusion workbook: ', 's');
assert(isfile(datafilename), 'The local experimental workbook was not found.');
expname = 'perfusion55d';
dataoption = detectImportOptions(datafilename);
datasheets = sheetnames(datafilename);
datainputs=struct();
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
for i = 1:numel(datasheets)
    datainputs.(datasheets(i))=readtable(datafilename,'Sheet', i);
end
warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
expdatalist=[];
Media = struct();
for i = 1:numel(datasheets)
    if datasheets(i) == "Feed1"
        Media.Feed1 = datainputs.(datasheets(i));
    elseif datasheets(i) == "Feed2"
        Media.Feed2 = datainputs.(datasheets(i));
    elseif datasheets(i) == "Feed3"
        Media.Feed3 = datainputs.(datasheets(i));
    elseif datasheets(i) == "glucose"
        Media.glucose = datainputs.(datasheets(i));
    elseif datasheets(i) == "galactose"
        Media.galactose = datainputs.(datasheets(i));
    else
        expdatalist = [expdatalist; datasheets(i)];
    end
end
selectlist = string();
for i = 1: numel(expdatalist)
selectlist(i,:) = string(i)+". " + expdatalist(i);
end
disp("Choose the experiment set numnber:")
disp(selectlist)
pickrun = input("Response:");
runname = expdatalist(pickrun);
selecteddata = datainputs.(expdatalist(pickrun));
[expdata,feeddata] = DT_readdata(selecteddata, Media);
%% Bioreactor Initial Values by defult
V1.volume = 50000; % volume of Feed1
V2.volume = 3000;% volume of Bioreactor
V3.volume = 20000; %  volume of glucose
V4.volume = 20000; % volume of Feed2
V5.volume = 20000; % volume of Feed3
V6.volume = 20000; %  volume of Bleed Bag
V7.volume = 20000; % volume of Product Harvest Bag
V8.volume = 20000; % volume of Spent Media Bag
V1.Vinit = 50000; % initial volume of Feed1
V2.Vinit = 1600;% initial volume of Bioreactor
V3.Vinit = 10000; % initial volume of glucose
V4.Vinit = 50000; % initial volume of Feed2
V5.Vinit = 50000; % initial volume of Feed3
V6.Vinit = 0; % initial volume of Bleed Bag
V7.Vinit = 0; % initial volume of Product Harvest Bag
V8.Vinit = 0;  % initial volume of Spent Media Bag
%% load flowsheet model

endtime = expdata.time(end)-10;
tmp = input('Enter end time (hours): ','s');
if ~isempty(tmp)
    val = str2double(tmp);
    if ~isnan(val) && val > 0
        endtime = val;
    end
end
fprintf('endtime = %.2f\n', endtime);
endtime = num2str(endtime);

mdl = "DT_GeneralFSM";
load_system(mdl);
set_param(mdl,"StopTime",endtime);
%% pick initial parameter
[K_ht, K_lt] = DT_manuscript_parameters();
%% 3. Parameter Bounds
num_base_params = 16; 
% Format: {'ParamName', lb_HT, ub_HT, lb_LT, ub_LT}
bounds_data = {
    'umaxglc',  0.60,   1.50,    0.05,   0.60;   % Growth rate (1/day)
    'umaxlac',  0.05,   0.35,    0.05,   0.35;   % Growth on lactate (1/day)
    'udmaxs',   0.01,   0.20,    0.20,   1.50;   % Starvation death (1/day)
    'udmaxt',   0.01,   0.10,    0.10,   0.80;   % Toxic death (1/day)
    'kilac',    3.00,   15.00,   3.00,   15.00;  % Lactate inhibition (g/L)
    'kiglc',    0.50,   3.00,    0.50,   3.00;   % Glucose inhibition (g/L)
    'kglc',     0.01,   0.50,    0.01,   0.50;   % Glc Monod constant (g/L)
    'klac',     0.10,   1.50,    0.10,   1.50;   % Lac Monod constant (g/L)
    'kdlac',    0.50,   5.00,    0.50,   5.00;   % Lac death constant (g/L)
    'kdglc',    0.01,   0.20,    0.01,   0.20;   % Glc death constant (g/L)
    'Yxvglc',   0.50,   3.00,    0.50,   4.00;   % Cell yield from Glc (1e6/g)
    'mglc',     0.01,   0.10,    0.01,   0.10;   % Maintenance (g/L/day)
    'Ymabxv',   0.0001, 0.005,   0.001,  0.015;  % Growth-coupled mAb (g/1e6)
    'YmabxvB',  0.000,  0.010,   0.010,  0.040;  % Non-growth mAb (g/1e6/day)
    'Ylacglc',  0.80,   2.00,    0.05,   1.20;   % Lac yield from Glc (g/g)
    'Yxvlac',   0.80,   3.00,    0.80,   3.00    % Cell yield from Lac (1e6/g)
};

% Unpack the cell array dynamically
param_names = bounds_data(:, 1)';
lb_HT       = cell2mat(bounds_data(:, 2))';
ub_HT       = cell2mat(bounds_data(:, 3))';
lb_LT       = cell2mat(bounds_data(:, 4))';
ub_LT       = cell2mat(bounds_data(:, 5))';

% Combine for LHS / Optimization
lb_full = [lb_HT, lb_LT]; 
ub_full = [ub_HT, ub_LT];

full_param_names = [strcat('HT_', param_names), strcat('LT_', param_names)];

%% 4. GSA: LHS
num_samples = 2000; 
num_total_params = 32;

disp('Generating Latin Hypercube Samples...');
% generate LHS design matrix
X_norm = lhsdesign(num_samples, num_total_params); 

% apply to parameters
X_samples = zeros(num_samples, num_total_params);
for i = 1:num_total_params
    X_samples(:, i) = lb_full(i) + X_norm(:, i) .* (ub_full(i) - lb_full(i));
end

%% 5. SA for each outputs
% create N x 4 matrix to store results
Y_results = zeros(num_samples, 4); 
disp(['Starting Monte Carlo simulations for ', num2str(num_samples), ' runs...']);

for i = 1:num_samples
    if mod(i, 20) == 0
        fprintf('Running sample %d of %d...\n', i, num_samples);
    end
    

    [err_vcd, err_glc, err_lac, err_mab] = DT_paraestobjfn(X_samples(i,:), endtime, expdata);
    

    Y_results(i, 1) = err_vcd;
    Y_results(i, 2) = err_glc;
    Y_results(i, 3) = err_lac;
    Y_results(i, 4) = err_mab;
end

%% 6. draw 2x2 plots for each metric
disp('Calculating Spearman Rank Correlation Coefficients for each metric...');

[rho_matrix, pval_matrix] = corr(X_samples, Y_results, 'Type', 'Spearman');
rho_matrix(isnan(rho_matrix)) = 0; 

metric_names = {'VCD RMSE', 'Glucose RMSE', 'Lactate RMSE', 'mAb RMSE'};

figure('Position', [100, 100, 1600, 1000]); 

for m = 1:4

    rho_current = rho_matrix(:, m);
    
    % rank by value
    [sorted_rho, sort_idx] = sort(abs(rho_current), 'ascend');
    sorted_real_rho = rho_current(sort_idx);
    sorted_names = full_param_names(sort_idx);
    
    
    subplot(2, 2, m);
    b = barh(sorted_real_rho, 'FaceColor', 'flat');
    
    % Red = positively correlated, smaller = better
    % Blue = negatively correlated, larger = better
    b.CData = bsxfun(@times, sorted_real_rho > 0, [0.8 0.2 0.2]) + ...
              bsxfun(@times, sorted_real_rho < 0, [0.2 0.4 0.8]);
          
    yticks(1:num_total_params);
    yticklabels(sorted_names);
    xlabel('Correlation (Impact on Error)');
    title(['Sensitivity for ', metric_names{m}]);
    grid on;
    
    % top 3 parameters
    fprintf('\n--- Top 3 Parameters for %s ---\n', metric_names{m});
    for i = 0:2
        idx = num_total_params - i;
        fprintf('%d. %s (Rho: %.4f)\n', i+1, sorted_names{idx}, sorted_real_rho(idx));
    end
end

sgtitle('Decoupled Global Sensitivity Analysis (Spearman Rank Correlation)', 'FontSize', 16, 'FontWeight', 'bold');