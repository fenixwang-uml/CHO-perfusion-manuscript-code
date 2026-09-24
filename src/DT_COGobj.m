% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [obj, sim_out] = DT_COGobj(x, OBJ_MODE, PENALTY_WEIGHT,Constrain)
    % This function is the objective function for parameter estimation
    % Inputs:
    % x: a vector of parameters
    % Outputs:
    % obj: a structure with fields Fval (objective) and Ineq (constraints <= 0)
    % sim_out: KPIs from the simulation

    arguments
        x
        OBJ_MODE
        PENALTY_WEIGHT
        Constrain
    end
    
    process = 'Spent Media Recycling';
    totalday = 20;              % Total simulation days
    perfusionratestart = 3;     % Day perfusion starts
    recyclestart = 10;          % Day recycling starts
    media_name = 'AMBIC11';     % Media sheet to load
    endtime = totalday * 24;    % Total simulation hours
    MEDIA_COST_PER_ML = 0.15;    % Normalised cost unit 

    V2_Vinit = 1600;
    
    % --- Constraint thresholds -----------------------
    MIN_TAH=0;
    MIN_VCD=0;
    MIN_TAHset = Constrain(1);
    MIN_VCDset = Constrain(2);

    % Unpack decision variables
    p_rate  = x(1);   % Perfusion rate (VVD)
    r_ratio = x(2);   % Recycle ratio  [0,1]

    mdl = "DT_GeneralFSM";
    load_system(mdl);
    set_param(mdl, 'StopTime', num2str(endtime));
    set_param(mdl, 'FastRestart', 'on');

    [expdata, feeddata] = DT_generatedata(process, totalday, p_rate, perfusionratestart, r_ratio, recyclestart, media_name, V2_Vinit);

    assignin('base','expdata',expdata);
    assignin('base','feeddata',feeddata);

    % Initialize structure for surrogateopt
    obj = struct('Fval', NaN, 'Ineq', [NaN, NaN]);

    % Run Simulink
    try
        out = sim(mdl);

        % Extract KPIs -----------------------------------------------
        try mediaused = out.freshfeedvol.Data(end);        catch, mediaused = NaN; end
        try final_TTA = out.harvmab.Data(end);             catch, final_TTA = NaN; end
        try final_VCD = out.bioreactor.conc.Xv.Data(end);  catch, final_VCD = NaN; end
        try final_vol = out.bioreactor.Volume.Data(end);   catch, final_vol = NaN; end

        fprintf('Success! Media: %.2f mL | VCD: %.2f | Titer: %.2f\n', mediaused, final_VCD, final_TTA);
        
        sim_out = struct('mediaused', mediaused, ...
                         'final_TTA', final_TTA, ...
                         'final_VCD', final_VCD, ...
                         'final_vol', final_vol);
                         
        % Guard against NaN output from solver failures
        if any(isnan([mediaused, final_TTA, final_VCD]))
            obj.Fval = PENALTY_WEIGHT;
            obj.Ineq = [PENALTY_WEIGHT, PENALTY_WEIGHT]; % Mark as highly infeasible
            return
        end              
        
        % Base COGs (Objective) --------------------------------------
        media_cost = mediaused * MEDIA_COST_PER_ML;

        switch OBJ_MODE
            case 1   % cost per total mAb harvested
                MIN_TAH = MIN_TAHset; 
                if final_TTA <= 0
                    base_cogs = PENALTY_WEIGHT;
                else
                    base_cogs = media_cost / final_TTA;
                end
            case 2   % cost per final cells
                MIN_VCD = MIN_VCDset; 
                final_cell = final_VCD * final_vol;
                if final_cell <= 0
                    base_cogs = PENALTY_WEIGHT;
                else
                    base_cogs = media_cost / final_cell;
                end
            otherwise
                error('Unknown OBJ_MODE. Choose 1 or 2.');
        end
        
        % Non-linear Constraints (surrogateopt expects c(x) <= 0) ----
        % MIN_TAH <= final_TTA  ==>  MIN_TAH - final_TTA <= 0
        % MIN_VCD <= final_VCD  ==>  MIN_VCD - final_VCD <= 0
        ineq_TAH = MIN_TAH - final_TTA;
        ineq_VCD = MIN_VCD - final_VCD;

        % Assign to output structure
        obj.Fval = base_cogs;
        obj.Ineq = [ineq_TAH, ineq_VCD];

    catch ME
        fprintf('[Sim Error] P=%.3f R=%.3f : %s\n', p_rate, r_ratio, ME.message);
        sim_out = struct('mediaused', NaN, 'final_TTA', NaN, 'final_VCD', NaN, 'final_vol', NaN);
        obj.Fval = PENALTY_WEIGHT;
        obj.Ineq = [PENALTY_WEIGHT, PENALTY_WEIGHT]; % Mark as highly infeasible
    end
end