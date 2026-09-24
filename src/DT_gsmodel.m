% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function gsrate= DT_gsmodel(flux,phase,GSmode)
    % This function calculates the growth rate of the cell
    % Inputs:
    % flux: a structure containing the fluxes of the exchange reactions of the amino acids;
    %       The field name of the structure is the name of the amino acid, and the field value is the flux of the reaction
    % phase: a flag indicating whether the cell is in the growth phase (1) or in the stationary phase (otherwise)
    % GSmode: a flag indicating whether to use the growth model (1) or not (otherwise)
    % Outputs:
    % gsrate: the igg specific productivity of the cell
    % AAflux: a vector containing the fluxes of the exchange reactions of the amino acids
    % Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
    arguments
        flux
        phase
        GSmode
    end
    if GSmode == 1
        % select the model based on the objective funtion. phase = 1 for growth phase, phase = 2 for production phase.
        if phase == 1
        % load model
        model_obj = load('temp_model_obj.mat');
        else
        model_obj = load('temp_model_obj_prod.mat');
        end
        loadconstrains = load('temp_constrain_exrxn.mat');
        constrain_exrxn = loadconstrains.constrain_exrxn;
        fluxlist = fieldnames(flux);  % list of flux names from the model, e.g. Asp, His, Ile...
        if findRxnIDs(model_obj, 'EX_glc_e') > 0
            constrain_exrxnlist = constrain_exrxn(:,1);
            iggid = findRxnIDs(model_obj, 'DM_igg_g');
            o2name = 'EX_o2_e';
        elseif findRxnIDs(model_obj, 'EX_glc_e_') > 0
            constrain_exrxnlist = constrain_exrxn(:,2);
            iggid = findRxnIDs(model_obj, 'DM_igg[g]');
            o2name = 'EX_o2_e_';
        elseif findRxnIDs(model_obj, 'EX_glc(e)') > 0
            constrain_exrxnlist = constrain_exrxn(:,3);
            iggid = findRxnIDs(model_obj,'DM_igg[g]');
            o2name = 'EX_o2(e)';
        end
        constrain_check = constrain_exrxn(:,4); % 1: used as constrains, 2: skipped
        fluxfixdata = constrain_exrxn(:,5); % flux data of constrains measured in previous experiments
        fixconstrains = struct();
        fixconstrains.Glc.flux = fluxfixdata{2};
        fixconstrains.Glc.name = constrain_exrxnlist{2};
        fixconstrains.Lac.flux = fluxfixdata{3};
        fixconstrains.Lac.name = constrain_exrxnlist{3};
        fixconstrains.Glu.flux = fluxfixdata{5};
        fixconstrains.Glu.name = constrain_exrxnlist{5};
        fixconstrains.Gln.flux = fluxfixdata{6};
        fixconstrains.Gln.name = constrain_exrxnlist{6};
        fixconstrains.Na.flux = fluxfixdata{10};
        fixconstrains.Na.name = constrain_exrxnlist{10};
        fixconstrains.NH4.flux = fluxfixdata{11};
        fixconstrains.NH4.name = constrain_exrxnlist{11};
        fixconstrains.Cys.flux = fluxfixdata{16};
        fixconstrains.Cys.name = constrain_exrxnlist{16};
        fixconstrains.O2.flux = -1.127;
        fixconstrains.O2.name = o2name;
        fixconstrains_list = fieldnames(fixconstrains);
        % add constrained fluxes
        constrains = struct();
        err = zeros(numel(fluxlist), 1);
        for i = 1:numel(fluxlist)
            if constrain_check{i} == 1
                constrains.(fluxlist{i}).flux = flux.(fluxlist{i});               
                constrains.(fluxlist{i}).rxn = constrain_exrxnlist{i};
                constrains.(fluxlist{i}).fixflux = fluxfixdata{i};
                diff = flux.(fluxlist{i}) - fluxfixdata{i};
                err(i) = abs(diff/fluxfixdata{i}); 
            end
        end
        tterr = sum(err);
        if tterr > 0.5*numel(fluxlist)
            for i = 1:numel(fluxlist)
                if constrain_check{i} == 1
                    constrains.(fluxlist{i}).flux = flux.(fluxlist{i});               
                    constrains.(fluxlist{i}).rxn = constrain_exrxnlist{i};
                    constrains.(fluxlist{i}).fixflux = fluxfixdata{i};
                end
            end
        end
        constrains_list = fieldnames(constrains);
        model_constrained = model_obj;
        band=0.0;
        for i = 1:numel(fixconstrains_list)
            thisfixflux = fixconstrains.(fixconstrains_list{i});
            flux_id = findRxnIDs(model_constrained,thisfixflux.name);
            if thisfixflux.flux > 0
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisfixflux.flux*(1-band), 'l');
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisfixflux.flux*(1+band), 'u');
            else
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisfixflux.flux*(1+band), 'l');
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisfixflux.flux*(1-band), 'u');
            end
        end
        % set the bounds of the constrain fluxes
        for i = 1:numel(constrains_list)
            thisflux = constrains.(constrains_list{i});
            flux_id = findRxnIDs(model_constrained,thisflux.rxn);
            if thisflux.flux > 0
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisflux.flux*(1-band), 'l');
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisflux.flux*(1+band), 'u');
            else
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisflux.flux*(1+band), 'l');
                model_constrained = changeRxnBounds(model_constrained, model_constrained.rxns(flux_id), thisflux.flux*(1-band), 'u');
            end
        end
        % perform the FBA
        model_solution = optimizeCbModel(model_constrained,'max');
        % disp(model_solution.f);
        % disp(iggid)
        % the solution is the growth rate at the growth phase and is the productivity at the stationary phase
        if ~isnan(model_solution.v)
        solution = model_solution.v(iggid);
        else
            solution = 0;
        end
        % convert the
        gsrate = solution/0.00369/24;
        if gsrate < 0
            gsrate = 0;
        end
    else
        gsrate = 0;
    end
end
