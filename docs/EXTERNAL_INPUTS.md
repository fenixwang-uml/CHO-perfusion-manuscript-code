# External inputs, supplied locally and excluded from Git

| Input | Location expected by the available implementation | Purpose |
|---|---|---|
| Experimental workbook | Absolute path entered at the prompt | One study sheet plus Feed1/Feed2/Feed3, glucose/galactose sheets as applicable. Use the original column order and MATLAB-normalized identifiers listed in DT_input_schema.m. |
| Feed and exchange metadata | data/feedcomp.xlsx relative to the distribution root | comp, name, GEMrnxEX1, GEMrnxEX2, GEMrnxEX3, constrain, fluxdata. Contains feed mapping and prior-data flux constraints; it is deliberately not distributed. |
| Scenario inputs | src/DATA_Simulation.xlsx, sheet Master_Data | Required by operational optimization. Includes Init_BRX, configured media column, GlucoseFeed, component names, exchange identifiers, constrain and fluxdata. No values are provided here. |
| Metabolic reconstruction | src/iCHO1766.mat, src/iCHO2441.mat or src/iCHO3K.mat | Required only for the selected GEM mode. Obtain the exact licensed version separately. Filename matching alone does not establish reconstruction identity. |

DT_readdata and DT_generatedata create temp_constrain_exrxn.mat from local inputs. GEM initialization creates temp_model_obj.mat and temp_model_obj_prod.mat. These temporary databases and all outputs must stay local. The package contains none of them.

The experiment loader currently requires feed mapping even in kinetic-only mode. Core kinetic calculations can be inspected independently, but full runs require these external inputs. The original experiment loader is order-dependent. Preserve the original column order; generic spreadsheets with reordered columns are not supported by this historical routine.

No actual measurements, raw duplicates, feed recipes, reconstruction matrices or archived outputs are included. Data availability for journal submission must be handled separately from this code-only upload.
