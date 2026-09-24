% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [Flowthrough, Retentate] = DT_splitstream(u,f)
    %This function splits the SPTFF feed stream into flowthrough and retentate
    % Input:
    % u: a structure of the feed stream containing the flow rate and concentrations
    % Output:
    % Flowthrough: spent media stream that flows through the SPTFF and can be recycled to the bioreactor.
    % Retentate: concentrated product harvest stream retained by the SPTFF and sent to the product vessel.
    % Filter efficiency k. If k = 1, 100% mAb is held in retentate/product side. If k = 0.9, 90% mAb is held in retentate/product side.
    % Filter flow split f. If f = 0.8, 80% flow of total feed is spent-media flowthrough. If f = 0.2, 20% flow of total feed is spent-media flowthrough.
    % Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
    arguments
        u
        f
    end
k = 1;
if f < 0 || f > 1
    error('DT_splitstream:InvalidFlowRatio', 'SPTFF flow ratio f must be between 0 and 1.');
end

Flowthrough = u;
Retentate = u;
Flowthrough.Vflow = Flowthrough.Vflow*f;
Retentate.Vflow = Retentate.Vflow*(1-f);
mab = u.conc.mAb;

if f <= eps
    Flowthrough.conc.mAb = 0;
else
    Flowthrough.conc.mAb = mab*(1-k)/f;
end

if (1-f) <= eps
    Retentate.conc.mAb = 0;
else
    Retentate.conc.mAb = mab*k/(1-f);
end

end
