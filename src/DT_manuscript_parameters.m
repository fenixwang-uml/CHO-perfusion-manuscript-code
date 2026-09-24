function [K_ht,K_lt] = DT_manuscript_parameters()
% Only the HT and LT coefficient values reported in the manuscript.
% Rates are stored per day. DT_kinetic converts relevant rates to per hour.
% Glucose and lactate concentrations and saturation constants use g/L.
% See docs/UNITS.md for cell-density scaling. No other parameter sets included.
K_ht.umaxglc = 0.6673; K_lt.umaxglc = 0.6000;
K_ht.umaxlac = 0.0100; K_lt.umaxlac = 0.0890;
K_ht.udmaxs = 0.2801; K_lt.udmaxs = 0.5697;
K_ht.udmaxt = 0.0508; K_lt.udmaxt = 0.4029;
K_ht.kilac = 7.6438; K_lt.kilac = 11.3676;
K_ht.kiglc = 1.0545; K_lt.kiglc = 1.2716;
K_ht.kglc = 0.3116; K_lt.kglc = 0.0100;
K_ht.klac = 1.3188; K_lt.klac = 0.6486;
K_ht.kdlac = 0.9661; K_lt.kdlac = 4.8710;
K_ht.kdglc = 0.1928; K_lt.kdglc = 0.0100;
K_ht.Yxvglc = 1.4858; K_lt.Yxvglc = 2.0270;
K_ht.mglc = 0.1852; K_lt.mglc = 0.0496;
K_ht.Ymabxv = 0.0099; K_lt.Ymabxv = 0.0011;
K_ht.YmabxvB = 0.0072; K_lt.YmabxvB = 0.0100;
K_ht.Ylacglc = 1.2224; K_lt.Ylacglc = 0.6923;
K_ht.Yxvlac = 0.6791; K_lt.Yxvlac = 1.2651;
end
