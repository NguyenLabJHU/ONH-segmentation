function top_edge = top_boundary_marking(I,BMOL,BMOR)
[row,col] = size(I);
BW = edge(I,'sobel');
for k = 1:col
    idx = find(BW(:,k)==1);
    TF = isempty(idx);
    if TF==1
        if k==1
            i = 1;
            while TF==1
                idx = find(BW(:,k+i)==1);
                TF = isempty(idx);
                i = i+1;
            end
            top_edge(k) = min(idx);
        else
            top_edge(k) = top_edge(k-1);
        end
    else
        top_edge(k) = min(idx);
    end
end
top_edge = [(1:col).',top_edge.'];
ind = find(top_edge(:,1)<=BMOL(1));
top_edge_left = top_edge(ind,:);
ind = find(top_edge(:,1)>=BMOR(1));
top_edge_right = top_edge(ind,:);
ind = find(top_edge(:,1)>BMOL(1) & top_edge(:,1)<BMOR(1));
top_edge_center = top_edge(ind,:);

top_edge_left = fit_line(top_edge_left,14);
top_edge_right = fit_line(top_edge_right,14);
top_edge_center = fit_line(top_edge_center,14);
top_edge = [top_edge_left;top_edge_center;top_edge_right];

    function line = fit_line(boundary_name,poly_order)
        % Sort points left to right
        pts = sortrows(boundary_name);
        % Fit polynomial
        [c(1,:),~,mu(:,1)] = polyfit(pts(:,1),pts(:,2),poly_order);
        % Evaluate polynomials at 15 points evenly spaced between left- and
        % rightmost points
        start = pts(1,1);
        finish = pts(end,1);
        x = linspace(start,finish,15);
        line(:,1) = x;
        line(:,2) = polyval(c(1,:),x,[],mu(:,1));
    end
end