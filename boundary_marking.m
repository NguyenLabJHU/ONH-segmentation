function im = boundary_marking(I,BMO,BML,BMR,ALC,CSL,CSR)
% read dimensions of the strain data (should be 460x742x24):
[row,col] = size(I);

im = zeros(row,col);
BMO = round(BMO);

% find all (R,Z) points sort by the first
% column, which records the R position:
BMO = sortrows(BMO);
ptsLC =  sortrows(ALC);
ptsBML = sortrows(BML);
ind = find(ptsBML(:,1)<BMO(1,1));
ptsBML = ptsBML(ind,:);
ptsBML = [ptsBML;BMO(1,:)];
ptsBMR = sortrows(BMR);
ind = find(ptsBMR(:,1)>BMO(2,1));
ptsBMR = ptsBMR(ind,:);
ptsBMR = [BMO(2,:);ptsBMR];
ptsCSL = sortrows(CSL);
ptsCSR = sortrows(CSR);

im = fit_curve(ptsBML,2,im);
im = fit_curve(ptsBMR,2,im);
im = fit_curve(ptsCSL,3,im);
im = fit_curve(ptsCSR,3,im);
im = fit_curve(ptsLC,4,im);

im(BMO(1,2),BMO(1,1)) = 1;
im(BMO(2,2),BMO(2,1)) = 1;
   
    function im = fit_curve(pts, label, im)
        % generate a line segment border defined at every pixel in R between
        % the marked points
        for j=1:1:length(pts)-1
            % calculate the pixel positions of the segmented divider from the
            % marked points at the first pressure:
            polynomial = polyfit([pts(j,1);pts(j+1,1)],[pts(j,2);pts(j+1,2)],1);
            line(1,ceil(pts(j,1)):floor(pts(j+1,1))) = polyval(polynomial,ceil(pts(j,1)):floor(pts(j+1,1)));
        end
        idx = find(line);
        for m = 1:length(idx)
            im(ceil(line(idx(m))),idx(m)) = label;
        end
    end
end