% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
% Dependent toolbox from matlab:
% Global Optimization Toolbox
%% 0. Initiate of Cobra Toolbox
if ~exist('initcbtb_done', 'var')
    initCobraToolbox(false);
    initcbtb_done = true;
end
%% Temporary for moving average smoothing window and overlap

%phase = 1;
%Estimate_K = 1; % 1 for ht parameters, 2 for lt parameters
paramiterate = 3000;
phase = 1;
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

%% pick initial parameter
[K_ht, K_lt] = DT_manuscript_parameters();
%% Parameter estimation

% 1. Initial guess
% list of parameters: umaxglc umaxlac udmaxs udmaxt	kilac	kiglc	kglc	klac	kdlac	kdglc	Yxvglc	mglc	Ymabxv	YmabxvB Ylacglc	Yxvlac
 x0 = [K_ht.umaxglc,K_ht.umaxlac,K_ht.udmaxs,K_ht.udmaxt,K_ht.kilac,K_ht.kiglc,K_ht.kglc,K_ht.klac,K_ht.kdlac,K_ht.kdglc,K_ht.Yxvglc,K_ht.mglc,K_ht.Ymabxv,K_ht.YmabxvB,K_ht.Ylacglc,K_ht.Yxvlac,...
       K_lt.umaxglc,K_lt.umaxlac,K_lt.udmaxs,K_lt.udmaxt,K_lt.kilac,K_lt.kiglc,K_lt.kglc,K_lt.klac,K_lt.kdlac,K_lt.kdglc,K_lt.Yxvglc,K_lt.mglc,K_lt.Ymabxv,K_lt.YmabxvB, K_lt.Ylacglc,K_lt.Yxvlac];


%. 2. Parameter Bounds for surrogateopt
%   Order: [umaxglc, umaxlac, udmaxs, udmaxt, kilac, kiglc, kglc, klac,
%         kdlac, kdglc, Yxvglc, mglc, Ymabxv, YmabxvB, Ylacglc, Yxvlac]

% Initialize arrays
num_params = 16; % for each condition, there are 16 parameters. For high temperatur and low temperature there are 32 parameters.

% Format: {'ParamName', lb_HT, ub_HT, lb_LT, ub_LT}
% bounds_data = {
%     'umaxglc',  0.60,   1.50,    0.05,   0.60;   % Growth rate (1/day)
%     'umaxlac',  0.05,   0.35,    0.05,   0.35;   % Growth on lactate (1/day)
%     'udmaxs',   0.01,   0.20,    0.20,   1.50;   % Starvation death (1/day)
%     'udmaxt',   0.01,   0.10,    0.10,   0.80;   % Toxic death (1/day)
%     'kilac',    3.00,   15.00,   3.00,   15.00;  % Lactate inhibition (g/L)
%     'kiglc',    0.50,   3.00,    0.50,   3.00;   % Glucose inhibition (g/L)
%     'kglc',     0.01,   0.50,    0.01,   0.50;   % Glc Monod constant (g/L)
%     'klac',     0.10,   1.50,    0.10,   1.50;   % Lac Monod constant (g/L)
%     'kdlac',    0.50,   5.00,    0.50,   5.00;   % Lac death constant (g/L)
%     'kdglc',    0.01,   0.20,    0.01,   0.20;   % Glc death constant (g/L)
%     'Yxvglc',   0.50,   3.00,    0.50,   4.00;   % Cell yield from Glc (1e6/g)
%     'mglc',     0.01,   0.10,    0.01,   0.10;   % Maintenance (g/L/day)
%     'Ymabxv',   0.0001, 0.005,   0.001,  0.015;  % Growth-coupled mAb (g/1e6)
%     'YmabxvB',  0.000,  0.010,   0.010,  0.040;  % Non-growth mAb (g/1e6/day)
%     'Ylacglc',  0.80,   2.00,    0.05,   1.20;   % Lac yield from Glc (g/g)
%     'Yxvlac',   0.80,   3.00,    0.80,   3.00    % Cell yield from Lac (1e6/g)
% };
bounds_data = {
    'umaxglc',  0.40,   1.20,    0.05,   0.60;   % Lowered HT ub to reduce VCD/Glc error
    'umaxlac',  0.01,   0.20,    0.05,   0.35;   % Lowered HT ub to reduce VCD error
    'udmaxs',   0.05,   0.40,    0.20,   1.50;   % Raised HT bounds for more starvation death (helps VCD)
    'udmaxt',   0.01,   0.10,    0.10,   0.80;   % Unchanged
    'kilac',    1.00,   10.00,   3.00,   15.00;  % Lowered HT bounds to increase lactate inhibition
    'kiglc',    0.50,   3.00,    0.50,   3.00;   % Unchanged
    'kglc',     0.01,   0.50,    0.01,   0.50;   % Unchanged
    'klac',     0.10,   1.50,    0.10,   1.50;   % Unchanged
    'kdlac',    0.50,   5.00,    0.50,   5.00;   % Unchanged
    'kdglc',    0.01,   0.20,    0.01,   0.20;   % Unchanged
    'Yxvglc',   0.50,   2.00,    0.50,   4.00;   % Lowered HT ub to heavily reduce VCD error
    'mglc',     0.05,   0.20,    0.01,   0.10;   % Raised HT bounds (helps VCD, Glc, and Lac simultaneously)
    'Ymabxv',   0.001,  0.010,   0.001,  0.015;  % Raised HT bounds to help mAb production
    'YmabxvB',  0.005,  0.025,   0.010,  0.040;  % Raised HT bounds significantly (major driver for mAb error)
    'Ylacglc',  0.40,   1.50,    0.05,   1.20;   % Lowered HT bounds heavily to fix Lactate overprediction
    'Yxvlac',   0.50,   2.00,    0.80,   3.00    % Lowered HT bounds (positive corr with Lactate error)
};
% Unpack the cell array dynamically
param_names = bounds_data(:, 1)';
lb_HT       = cell2mat(bounds_data(:, 2))';
ub_HT       = cell2mat(bounds_data(:, 3))';
lb_LT       = cell2mat(bounds_data(:, 4))';
ub_LT       = cell2mat(bounds_data(:, 5))';

% Combine for LHS / Optimization
lb = [lb_HT, lb_LT];
ub = [ub_HT, ub_LT];

% 2. Set up surrogateopt options
% We pass your initial guess (x0) here!
options = optimoptions('surrogateopt', ...
    'Display', 'iter', ...
    'InitialPoints', x0, ...     % Give it your baseline parameters
    'UseParallel', false, ...     % Turn this to false if you don't have the Parallel Computing Toolbox
    'CheckpointFile', 'my_surrogate_checkpoint.mat',...
    'MaxFunctionEvaluations', paramiterate); % Limit evaluations so it doesn't run forever

% 3. Run the Surrogate Optimization
% Notice the syntax is different: no x0 in the main arguments
[xlsqopt, fval, exitflag, output] = surrogateopt(@(x) DT_objfunctionwrap(x, endtime,expdata), lb, ub, options);

% 4. Display the result
fprintf('Optimization finished with exit flag: %d\n', exitflag);
fprintf('Best objective function value found: %f\n', fval);
%
Khtvalues = xlsqopt;
K_ht.umaxglc = Khtvalues(1,1);
K_ht.umaxlac = Khtvalues(1,2);
K_ht.udmaxs = Khtvalues(1,3);
K_ht.udmaxt = Khtvalues(1,4);
K_ht.kilac = Khtvalues(1,5);
K_ht.kiglc = Khtvalues(1,6);
K_ht.kglc = Khtvalues(1,7);
K_ht.klac = Khtvalues(1,8);
K_ht.kdlac = Khtvalues(1,9);
K_ht.kdglc = Khtvalues(1,10);
K_ht.Yxvglc = Khtvalues(1,11);
K_ht.mglc = Khtvalues(1,12);
K_ht.Ymabxv = Khtvalues(1,13);
K_ht.YmabxvB = Khtvalues(1,14);
K_ht.Ylacglc = Khtvalues(1,15);
K_ht.Yxvlac = Khtvalues(1,16);

K_lt.umaxglc = Khtvalues(1,17);
K_lt.umaxlac = Khtvalues(1,18);
K_lt.udmaxs = Khtvalues(1,19);
K_lt.udmaxt = Khtvalues(1,20);
K_lt.kilac = Khtvalues(1,21);
K_lt.kiglc = Khtvalues(1,22);
K_lt.kglc = Khtvalues(1,23);
K_lt.klac = Khtvalues(1,24);
K_lt.kdlac = Khtvalues(1,25);
K_lt.kdglc = Khtvalues(1,26);
K_lt.Yxvglc = Khtvalues(1,27);
K_lt.mglc = Khtvalues(1,28);
K_lt.Ymabxv = Khtvalues(1,29);
K_lt.YmabxvB = Khtvalues(1,30);
K_lt.Ylacglc = Khtvalues(1,31);
K_lt.Yxvlac = Khtvalues(1,32);


Kout = [Khtvalues(1,1:16);Khtvalues(1,17:32)];

save('output_Kout.mat','Kout');
%% run simulink
mdl = "DT_GeneralFSM";
load_system(mdl);
set_param(mdl,"StopTime",endtime);
out = sim(mdl);
DT_plotout(out,expdata);
if GSmode == 1
    gs = 'gs';
else
    gs = 'nogs';
end
filename = "out/results_" + expname +"_"+ runname +"_"+ gs+".png";

saveas(gcf, filename);
%% Other output options
    [NDXV,~] = size(out.DXV.data);
    [NDGLC,~] = size(out.DGLC.data);
    [NDLAC,~]=  size(out.DLAC.data);
    [NDMAB,~] = size(out.DMAB.data);

    % Calculate RMSE
    RMSEXV = sqrt(sum((out.DXV.data).^2)/NDXV);
    RMSEGLC = sqrt(sum((out.DGLC.data).^2)/NDGLC);
    RMSELAC = sqrt(sum((out.DLAC.data).^2)/NDLAC);
    RMSEMAB = sqrt(sum((out.DMAB.data).^2)/NDMAB);
   % Calculate Relative RMSE

    max_exp_XV  = max(expdata.Xv.Var1);
    max_exp_GLC = max(expdata.Glc.Var1);
    max_exp_LAC = max(expdata.Lac.Var1);
    max_exp_MAB = max(expdata.mAb.Var1);

    RRMSEXV = RMSEXV/max_exp_XV;
    RRMSEGLC = RMSEGLC/max_exp_GLC;
    RRMSELAC = RMSELAC/max_exp_LAC;
    RRMSEMAB = RMSEMAB/max_exp_MAB;

    RRMSE.XV  = RRMSEXV;
    RRMSE.GLC = RRMSEGLC;
    RRMSE.LAC = RRMSELAC;
    RRMSE.MAB = RRMSEMAB;

    save('output_RRMSE.mat', '-struct', 'RRMSE');
