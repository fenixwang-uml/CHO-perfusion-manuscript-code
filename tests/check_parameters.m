function check_parameters()
% Small static numerical check; not a simulation-validation test.
[h,l] = DT_manuscript_parameters();
assert(numel(fieldnames(h))==16 && numel(fieldnames(l))==16);
assert(h.umaxglc==0.6673 && l.umaxglc==0.6000);
r = DT_kinetic(h, 1, 1, 0);
assert(all(isfinite([r.rXv,r.rGlc,r.rLac,r.rmab])));
fprintf('Parameter and kinetic-rate checks passed.\n');
end
