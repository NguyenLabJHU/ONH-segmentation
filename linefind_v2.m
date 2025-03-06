function [out] = linefind_v2(alg_marks,ncols,low_poly)
BMOL = alg_marks.bruch_op_left;
BMOR = alg_marks.bruch_op_right;

% Fit the points to polynomials and output 15 points per tissue along those
% polynomials
BML = alg_marks.bruch_mem_left;
BMR = alg_marks.bruch_mem_right;
CSL = alg_marks.chor_scl_left;
CSR = alg_marks.chor_scl_right;
ALC = alg_marks.ant_lam_lim;

BML = [BML;BMOL];
BMR = [BMOR;BMR];

alg_marks.bruch_op_left = BMOL(:,1:2);
alg_marks.bruch_op_right = BMOR(:,1:2);
if low_poly == true
    alg_marks.bruch_mem_left = fit_line(BML,5,1,(BMOL(1)-1)); %Offset from BMO to prevent covering marker
    alg_marks.bruch_mem_right = fit_line(BMR,5,(BMOR(1)+1),ncols);
    alg_marks.chor_scl_left = fit_line(CSL,6,1,BMOL(1)); 
    alg_marks.chor_scl_right = fit_line(CSR,6,BMOR(1),ncols); 
else
    alg_marks.bruch_mem_left = fit_line(BML,14,1,(BMOL(1)-1)); %Offset from BMO to prevent covering marker
    alg_marks.bruch_mem_right = fit_line(BMR,14,(BMOR(1)+1),ncols); 
    alg_marks.chor_scl_left = fit_line(CSL,14,1,BMOL(1)); 
    alg_marks.chor_scl_right = fit_line(CSR,14,BMOR(1),ncols); 
end
alg_marks.ant_lam_lim = fit_line(ALC,14,BMOL(1),BMOR(1));

out = alg_marks;

    function line = fit_line(boundary_name,poly_order,start,finish)
        % Sort points left to right
        pts = sortrows(boundary_name);
        pts = pts(pts(:,1)>=start,:);
        pts = pts(pts(:,1)<=finish,:);
        
        % Fit polynomial
        [c,~,mu] = polyfitweights(pts(:,1),pts(:,2),poly_order,pts(:,3));
        %[c,~,mu] = polyfit(pts(:,1),pts(:,2),poly_order);
        
        % Evaluate polynomials at 15 points evenly spaced between left- and
        % right boundaries
        x = linspace(start,finish,15);
        line(:,1) = x;
        line(:,2) = polyval(c,x,[],mu);
    end
end