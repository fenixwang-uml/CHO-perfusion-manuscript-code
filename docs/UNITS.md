# Units verified for the manuscript state variables

- Glucose: g/L. The source experimental column is labeled Glucose (g/L). DT_input_schema maps it to Glc. DT_readdata applies no concentration conversion, and DT_kinetic uses it directly.
- Lactate: g/L. The source column is labeled Lactate (g/L). It maps to Lac and is also used without concentration conversion.
- Other measured species can be in mmol/L. Their units must not be applied to glucose or lactate. GEM exchange rates have separate flux units.
- VCD numerical state: millions of cells per mL. With product or substrate concentration in g/L, a numerical cell-specific rate has units g per billion cells per hour.
- Kinetic parameters are stored in the manuscript convention. DT_kinetic divides growth/death rates, glucose maintenance and non-growth-associated mAb production by 24 to work in hours.
- The type definitions include legacy volume/flow labels. The process implementation uses mL and mL/h in several places. Those separate volume-label inconsistencies do not change the confirmed input concentration units, but require reconciliation for a full reproduction.

The code package contains no source measurements. Unit verification was performed against the local source records before packaging.
