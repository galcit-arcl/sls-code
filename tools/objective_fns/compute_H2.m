function objective = compute_H2(R, M, C, D, TFIR)
% return ||[C,D][R;M]||_H2^2
% see eqns (3.1), (4.20) of long tutorial

objective = 0;
for t = 1:TFIR
    %need to do the vect operation because of quirk in cvx
    vect = vec([C,D]*[R{t};M{t}]);
    objective = objective + vect'*vect;
end