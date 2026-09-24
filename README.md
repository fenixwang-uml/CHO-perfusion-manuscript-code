# CHO perfusion manuscript code

MATLAB/Simulink code for the 55-day perfusion run with recycling, including kinetic modeling, FBA coupling, parameter estimation, sensitivity analysis and optimization.

Requires MATLAB, Simulink and the relevant toolboxes. FBA additionally requires COBRA Toolbox and an LP solver.

Run `setup_manuscript`, then `DT_run`. Other entry points are `DT_run_ParaEst`, `DT_Run_GSA` and `DT_run_OptimizeCOGs`.

Experimental data and metabolic model databases are not included. See [external inputs](docs/EXTERNAL_INPUTS.md). Full simulation execution has not been verified for this package.
