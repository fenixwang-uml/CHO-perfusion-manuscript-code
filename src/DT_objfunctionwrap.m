% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function objfn = DT_objfunctionwrap(x,endtime,expdata)
arguments
    x
    endtime
    expdata
end
[err_VCD, err_glc, err_lac, err_mAb] = DT_paraestobjfn(x,endtime,expdata);

    weight_XV  = 1.0;
    weight_GLC = 1.0;
    weight_LAC = 1.0;
    weight_MAB = 1.0;

    objfn = (weight_XV * err_VCD) + ...
        (weight_GLC * err_glc) + ...
        (weight_LAC * err_lac) + ...
        (weight_MAB * err_mAb);
end
