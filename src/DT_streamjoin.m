% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function joinedStream = DT_streamjoin(streamA, streamB)
    %This function joins two streams
    % Input:
    % streamA is a structure containing the flow rate and concentrations of the first stream A
    % streamB is a structure containing the flow rate and concentrations of the second stream B
    % Output:
    % joinedStream is a structure containing the flow rate and concentrations of the joined stream
    % Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025
    arguments
        streamA
        streamB
    end
    concA = streamA.conc;
    concB = streamB.conc;
    conclist = fieldnames(concA);
    VflowA = streamA.Vflow;
    VflowB = streamB.Vflow;
    
    joinedStream = streamA;
    concJ = joinedStream.conc;
    if VflowA == 0
        if VflowB == 0
            for i = 1:numel(conclist)
                concJ.(conclist{i}) = (concA.(conclist{i}) + concB.(conclist{i})) / 2;
            end
            joinedStream.conc = concJ;
            joinedStream.Vflow = 0;
        else
            joinedStream = streamB;
        end
    else
        if VflowB == 0
            joinedStream = streamA;
        else
            
            VflowJ = VflowA + VflowB;
            for i = 1:numel(conclist)
                concJ.(conclist{i}) = (concA.(conclist{i}) * VflowA + concB.(conclist{i}) * VflowB) / VflowJ;
            end
            joinedStream.conc = concJ;
            joinedStream.Vflow = VflowJ;
        end
    end
end
