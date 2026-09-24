# CHO perfusion manuscript code

Code supporting the manuscript “Integrated dynamic and multiscale modeling for continuous CHO cell cultures: toward a predictive core for bioprocess digital twins”.

## Scope

This distribution contains the author-written kinetic model, process balances, Simulink flowsheet and block library, FBA coupling, sensitivity screening, parameter estimation, plotting, and operational optimization workflows discussed in the manuscript. Only the manuscript HT/LT parameter values are included. The experimental dataset is described as the 55-day perfusion run with recycling.

Experimental workbooks, feed-composition/constraint data, genome-scale model databases, saved simulation results, unrelated contextualization and media-design projects, web applications, third-party toolboxes and backups are excluded. Simulink graphical source files (.slx) are code. The type dictionary is reconstructed locally from MATLAB source; no .sldd database is shipped.

## Status

This is a code-only distribution assembled from the available working implementation. It has passed static dependency and content checks. MATLAB could not start in the preparation environment, so the packaged workflows and type-dictionary reconstruction have not been runtime-tested. This is not a certified reproduction of the submitted figures. See [reproducibility status](docs/REPRODUCIBILITY_STATUS.md) and [source changes](docs/SOURCE_CHANGES.json).

## Requirements and use

1. Install a MATLAB release capable of opening the supplied Simulink models, with Simulink, Global Optimization Toolbox and Statistics and Machine Learning Toolbox. Additional products referenced by the models may be required. The source models were saved with differing MATLAB release metadata; do not assume the manuscript's historical release identifies the current files.
2. For genome-scale workflows, install COBRA Toolbox and a compatible LP solver (Gurobi or GLPK) separately. Supply the selected reconstruction separately. No third-party software or metabolic database is bundled.
3. Read [external inputs](docs/EXTERNAL_INPUTS.md). Place only your local inputs at the documented locations. The .gitignore excludes these files from Git.
4. In MATLAB, start from this directory and run `setup_manuscript`. This adds paths, reconstructs the Simulink type dictionary, creates the output directory, and switches to `src`.
5. Use `DT_run` for the experiment-driven kinetic or GEM-coupled simulation, `DT_Run_GSA` for sensitivity screening, `DT_run_ParaEst` for a new computational fit, and `DT_run_OptimizeCOGs` for landscape/optimization calculations. Model type and solver selections remain interactive. The first three workflows request the local study workbook path.
6. To exercise the small parameter/rate check, add `tests` to the MATLAB path and call `check_parameters`. This check does not validate full simulations.

The recorded temperature defaults and current algorithm settings require reconciliation with the manuscript-generating configuration. Do not treat a new fit or optimization as the original analysis. Raw numerical outputs must accompany any future claim of figure reproduction.

## Upload to GitHub

Upload the contents of this directory as the repository root. Do not upload the parent revision directory, manuscript drafts or local input files. Add the final repository URL/archival DOI to the manuscript after publication of the code. Select a code license with the rights holder before public release; this preparation step does not grant a license on behalf of the authors or institution.
