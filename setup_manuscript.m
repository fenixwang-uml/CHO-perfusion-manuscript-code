function setup_manuscript()
% Run from the distribution root before the manuscript workflows.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'src'),fullfile(root,'src','DTLib'));
DT_create_types();
if ~isfolder(fullfile(root,'src','out')), mkdir(fullfile(root,'src','out')); end
cd(fullfile(root,'src'));
fprintf('Code paths and local Simulink types prepared. External inputs are still required.\n');
end
