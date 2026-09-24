% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [err_VCD, err_glc, err_lac, err_mAb] = DT_paraestobjfn(x,endtime,expdata)
    % This function is the objective function for parameter estimation
    % Inputs:
    % x: a vector of parameters
    % Outputs:
    % objfn: the objective function value

    % Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
    %
    arguments
        x
        endtime
        expdata
    end

    % Assign parameters
    %    Order: [umaxglc, umaxlac, udmaxs, udmaxt, kilac, kiglc, kglc, klac,
%            kdlac, kdglc, Yxvglc, mglc, Ymabxv, YmabxvB, Ylacglc, Yxvlac]
    K_ht.umaxglc = x(1);
    K_ht.umaxlac = x(2);
    K_ht.udmaxs = x(3);
    K_ht.udmaxt = x(4);
    K_ht.kilac = x(5);
    K_ht.kiglc = x(6);
    K_ht.kglc = x(7);
    K_ht.klac = x(8);
    K_ht.kdlac = x(9);
    K_ht.kdglc = x(10);
    K_ht.Yxvglc = x(11);
    K_ht.mglc = x(12);
    K_ht.Ymabxv = x(13);
    K_ht.YmabxvB = x(14);
    K_ht.Ylacglc = x(15);
    K_ht.Yxvlac = x(16);

    K_lt.umaxglc = x(17);
    K_lt.umaxlac = x(18);
    K_lt.udmaxs = x(19);
    K_lt.udmaxt = x(20);
    K_lt.kilac = x(21);
    K_lt.kiglc = x(22);
    K_lt.kglc = x(23);
    K_lt.klac = x(24);
    K_lt.kdlac = x(25);
    K_lt.kdglc = x(26);
    K_lt.Yxvglc = x(27);
    K_lt.mglc = x(28);
    K_lt.Ymabxv = x(29);
    K_lt.YmabxvB = x(30);
    K_lt.Ylacglc = x(31);
    K_lt.Yxvlac = x(32);

    % Assign to base workspace for Simulink
    assignin('base','K_ht',K_ht);
    assignin('base','K_lt',K_lt);


  mdl = "DT_GeneralFSM";
    load_system(mdl);
    set_param(mdl,"StopTime",endtime);
    set_param(mdl, 'FastRestart', 'on');
    out = sim(mdl);

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

    err_VCD = RRMSEXV;
    err_glc = RRMSEGLC;
    err_lac = RRMSELAC;
    err_mAb = RRMSEMAB;



end
