% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
%% This is the main script for running the app
% The main functions of the app are:
% 1. Initiate Cobra Toolbox
% 2. Run the app
% 3. Plot the results
% 4. Save the results
% The model is developed by Zhao Wang (fenixwang@gmail.com, zhao_wang@student.uml.edu)
% The dependt libraries are:
% 1. Cobra Toolbox
% 2. Simulink
% 3. Bioinformatics Toolbox
% 4. Industrial Communications Toolbox
% 5. Optimization Toolbox
% 6. Simscape
% 7. Statistics and Machine Learning
% Version 1.0
% Date: 08/03/2025


%% 0. Initiate of Cobra Toolbox
if ~exist('initcbtb','var')
    initcbtb = 1;
else
    initcbtb = 0;
end
if initcbtb == 1
    initCobraToolbox(false);  %initial loading of cobratoolbox (only run one time per session)
end
phase = 1; %growth phase to start

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
%   UNIT IN mL
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
%% pick parameter set

endtime = expdata.time(end)-10;
tmp = input('Enter end time (hours): ','s');
if ~isempty(tmp)
    val = str2double(tmp);
    if ~isnan(val) && val > 0
        endtime = val;
    end
end
fprintf('endtime = %.2f\n', endtime);

%% choose parameter
[K_ht, K_lt] = DT_manuscript_parameters();
%% run simulink
mdl = "DT_GeneralFSM";
load_system(mdl);

set_param(mdl, 'FastRestart', 'on');

set_param(mdl,"StopTime",num2str(endtime));
simout = sim(mdl);
%% Plot results
out = simout;
DT_plotout(out,expdata);
if GSmode == 1
    gs = 'gs';
else
    gs = 'nogs';
end
filename = "out/results_" + expname +"_"+ runname +"_"+ gs+".png";
saveas(gcf, filename);
%% Other output options
%     [NDXV,~] = size(out.DXV.data);
%     [NDGLC,~] = size(out.DGLC.data);
%     [NDLAC,~]=  size(out.DLAC.data);
%     [NDMAB,~] = size(out.DMAB.data);

%     % Calculate RMSE
%     RMSEXV = sqrt(sum((out.DXV.data).^2)/NDXV);
%     RMSEGLC = sqrt(sum((out.DGLC.data).^2)/NDGLC);
%     RMSELAC = sqrt(sum((out.DLAC.data).^2)/NDLAC);
%     RMSEMAB = sqrt(sum((out.DMAB.data).^2)/NDMAB);
%    % Calculate Relative RMSE

%     max_exp_XV  = max(expdata.Xv.Var1);
%     max_exp_GLC = max(expdata.Glc.Var1);
%     max_exp_LAC = max(expdata.Lac.Var1);
%     max_exp_MAB = max(expdata.mAb.Var1);

%     RRMSEXV = RMSEXV/max_exp_XV;
%     RRMSEGLC = RMSEGLC/max_exp_GLC;
%     RRMSELAC = RMSELAC/max_exp_LAC;
%     RRMSEMAB = RMSEMAB/max_exp_MAB;

%     RRMSE.XV  = RRMSEXV;
%     RRMSE.GLC = RRMSEGLC;
%     RRMSE.LAC = RRMSELAC;
%     RRMSE.MAB = RRMSEMAB;

%     save('output_RRMSE.mat', '-struct', 'RRMSE');
% mediaused = out.freshfeedvol.Data(end);
% fprintf('%f\n',mediaused);
% ttt = out.logsout{9}.Values.Time;
% tts = out.logsout{9}.Values.Data;
