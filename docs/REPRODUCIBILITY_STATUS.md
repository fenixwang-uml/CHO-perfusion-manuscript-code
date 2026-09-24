# Reproducibility status

The available source is not yet linked to all submitted figures. This package preserves the equations and workflow logic while narrowing dataset selection and parameter loading to the manuscript scope. It is not an assertion that current defaults reproduce historical results.

- The original 250 h fitting statement precedes the reported Day 13 temperature shift. The source of the LT estimates remains unresolved.
- DT_readdata retains the source temperature defaults of 37 to 32 degrees C at 120 h. These are not the manuscript's reported 37 to 35 degrees C on Day 13. They must be resolved before a study reproduction. They have not been silently relabeled as the experimental schedule.
- Current GSA uses 2,000 joint samples and its own search bounds. These are sensitivity ranges, not extra fitted parameter sets or verified historical bounds.
- The supplied manuscript parameter function is the only stored fitted set. Parameter-estimation runs can produce new coefficients, which are new computational results.
- Current volumes, feed settings, optimizer options, objective scaling and code metadata differ from some manuscript descriptions. Historical run settings and saved outputs are still needed.
- DT_plotout uses a fixed 10% display interval. It is not replicate SD or a confidence interval.
- DT_paraestobjfn normalizes logged-grid RMSE by the maximum of each supplied experimental series. It is not pointwise relative error.
- Amino-acid behavior uses measured inputs. GEM constraints depend on external prior-data bounds. The implementation does not demonstrate an independently predictive amino-acid model.
- No MATLAB/Simulink execution was possible in the preparation environment. Only static content/dependency checks were completed. The scripts and generated type setup need execution in the author's working MATLAB installation.

The manuscript-specific data files are deliberately absent. This is a code-sharing package, not a complete independently executable reproduction archive.
