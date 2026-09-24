% Manuscript code distribution. See docs/REPRODUCIBILITY_STATUS.md.
function [Harvest_stream, Retentate_stream]=DT_cellretention(Stream, Harvest_Vflow, Retention_efficiency)
% This function calculates the flow rates of the harvest and retentate streams
% Inputs:
% Stream: a structure containing the current flow rate and concentrations of the stream
% Harvest_Vflow: the flow rate of the harvest stream
% Retention_efficiency: the efficiency of the retention, between 0 and 1, where 1 is complete retention, all the cells are retained in the retentate stream and Xv = 0 in the harvest stream.
% Outputs:
% Harvest_stream: a structure containing the flow rate and concentrations of the harvest stream
% Retentate_stream: a structure containing the flow and concentrations of the retentate stream feeding back to the bioreactor

% Author: Zhao Wang, UMass Lowell, zhao_wang@student.uml.edu,2025

arguments
    Stream
    Harvest_Vflow
    Retention_efficiency
end

% Unpack the stream into flow and concentrations as current conditions
Vflow = Stream.Vflow;
concs = Stream.conc;
Xv = concs.Xv;

Harvest_stream = Stream;
Retentate_stream = Stream;

if Retention_efficiency > 1
    error('Retention efficiency cannot be greater than 1');
end

if Vflow == 0
    Harvest_stream = Stream;
    Retentate_stream = Stream;
    return
end

% Material balances
% flow in
inXv = Xv * Vflow;

% Calculate the flow rates of the harvest and retentate streams
Harvest_stream.Vflow = Harvest_Vflow;

% Calculate the flow rate of the retentate stream
Retentate_stream.Vflow = Vflow - Harvest_Vflow;

% Calculate the Xv of the harvest and retentate streams
retXv = inXv * Retention_efficiency; % Xv in the retentate stream, retXv = inXv at Retention_efficiency = 1
harvXv = inXv * (1 - Retention_efficiency );  % Xv in the harvest stream, harvXv = 0 at Retention_efficiency = 1

Harvest_stream.conc.Xv = harvXv / Harvest_stream.Vflow;
Retentate_stream.conc.Xv = retXv / Retentate_stream.Vflow;

end
