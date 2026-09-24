% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [dvoldt, dConcdt, AAflux] = DT_VesselCalc(Vesselcondition, Instream, Outflow, Params, SecondOutflow, gsrate, dAAdt,GSmode)
    % This function calculates the change in volume and concentrations in the vessel
    % Inputs:
    % Vesselcondition: a structure containing the current volume and concentrations in the vessel
    % Instream: a structure containing the current flow rate and concentrations of the inflow
    % Outflow: the flow rate of the outflow of the vessel
    % Params: a structure containing the parameters of the model
    % SecondOutflow: the flow rate of the second outflow, normally zero, used for bleed stream.
    % gsrate: the igg specific productivity of the cell
    % dAAdt: the observed change in amino acid concentrations (come from time derivative of the amino acid fluxes)
    % GSmode: a flag indicating whether to use the growth model (1) or not (otherwise)

    % Outputs:
    % dvoldt: the change of volume of the vessel in term of time derivative
    % dConcsdt: the change in concentrations of the vessel in term of time derivative
    % AAflux: the amino acid fluxes calculated based on the change in AA concentrations and cell density.

    % Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
    arguments
        Vesselcondition
        Instream
        Outflow 
        Params 
        SecondOutflow 
        gsrate 
        dAAdt 
        GSmode 
    end

    % Unpack the vesselcondition into volume and concentrations as current conditions
    vol = Vesselcondition.Volume;
    concs = Vesselcondition.conc;
    inconcs = Instream.conc;    
    complist = fieldnames(concs); 
    compnum = length(complist);
    AAlist = fieldnames(dAAdt);
    AAnum = length(AAlist);

    %unpack the parameters
    K_kinetic = Params;

    % Material balances
    % flow in
    for i = 1:compnum
        flowin.(complist{i}) = inconcs.(complist{i}) * Instream.Vflow;
    end

    % flow out
    for i = 1:compnum
        flowout.(complist{i}) = concs.(complist{i}) * Outflow;
    end

    %second outflow
    for i = 1:compnum
        flowout2.(complist{i}) = concs.(complist{i}) * SecondOutflow;
    end

    Glc = concs.Glc;
    Lac = concs.Lac;
    Xv = concs.Xv;
  
%     % Kinetic models for reactions
%     u = umax * Glc/(kglc + Glc) * kilac/(kilac + Lac);
%     % u = umax * Glc/(kglc + Glc);
%     ud = udmax * Lac/(kdlac + Lac) * mglc/(Glc + mglc);
%     % ud = udmax * Lac/(kdlac + Lac) * kdglc/(kdglc + Glc);
%     mu = u - ud;
%     qglc = (u / Yxvglc);
%    % qglc = (mu / Yxvglc) + mglc;
%     qlac = Ylacglc * qglc - (u / Yxvlac);
%     % qmab = (1 - u/umax) * Ymabxv;
%     if GSmode == 1
%         qmab = gsrate;
%         %qmab = (1+gsrate)* (1 - u/umax) * Ymabxv;
%     else
%         qmab = (1 - u/umax) * Ymabxv;
%     end

%     %reactions for concentrations
%     rXv = mu * Xv;
%     rGlc = -qglc * Xv;
%     rLac = qlac * Xv;
%     rmab = qmab * Xv;
    rate = DT_kinetic(K_kinetic,Xv,Glc,Lac);
    rXv = rate.rXv;
    rGlc = rate.rGlc;
    rLac = rate.rLac;
    rmab = rate.rmab;

    if GSmode == 1
        qp = gsrate;
        rmab = Xv*qp;
    end

    %ODEs
    dConcdt = zeros(compnum, 1);
    dmdt = struct();
    dvoldt = Instream.Vflow - Outflow - SecondOutflow; % volume balance
    for i = 1:compnum
        dmdt.(complist{i}) = 0;
    end

    AAflux = struct();
    for i = 1:AAnum
        AAflux.(AAlist{i}) = 0;
    end

    if vol > 0
        for i = 1:compnum
            dmdt.(complist{i}) = (flowin.(complist{i}) - flowout.(complist{i}) - flowout2.(complist{i}) - concs.(complist{i}) * dvoldt) / vol;
        end
        dmdt.Xv = rXv + (flowin.Xv - flowout.Xv - flowout2.Xv) / vol - (concs.Xv * dvoldt) / vol;
        dmdt.Glc = rGlc + (flowin.Glc - flowout.Glc - flowout2.Glc) / vol - (concs.Glc * dvoldt) / vol;
        dmdt.Lac = rLac + (flowin.Lac - flowout.Lac - flowout2.Lac) / vol - (concs.Lac * dvoldt) / vol;
        dmdt.mAb = rmab + (flowin.mAb - flowout.mAb - flowout2.mAb) / vol - (concs.mAb * dvoldt) / vol;
        for i = 1:AAnum
            dmdt.(AAlist{i}) = dAAdt.(AAlist{i});
        end 
        if Xv > 0
            for i = 1:AAnum
                AAflux.(AAlist{i}) = -(-dAAdt.(AAlist{i}) * vol - flowin.(AAlist{i}) + flowout.(AAlist{i}) + flowout2.(AAlist{i}) + concs.(AAlist{i}) * dvoldt) / vol / Xv * 0.00369*1000;
            end
        end
    end

    % Pack the concentrations rates
    for i = 1:compnum
        dConcdt(i) = dmdt.(complist{i});
    end 
end
