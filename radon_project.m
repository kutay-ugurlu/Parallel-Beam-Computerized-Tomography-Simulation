%% PART 1: FORWARD PROJECTION 
% This document describes the Radon Transform MATLAB script written for
% EE415 Term Project Part 1.
% The algorithm is presumed to input only square images.
% Angle step size input is assumed to be in degrees.

function [PROJECTIONS, t_s] = radon_project(I,sampling_points, angle_step_size)

%% Getting relevant parameters from image.
% Using size function to arrange beams.
[M,~] = size(I);
left_end = M * -0.5;
right_end = M * 0.5;

%% Forming angle, t and grid vectors.
% Vectors that are going to be iterated are formed here. 
thetas = deg2rad(0:angle_step_size:180-angle_step_size) ; 
t_s = linspace(left_end*sqrt(2),right_end*sqrt(2),sampling_points);
X_grid = left_end : right_end;
Y_grid = X_grid;

%% PROJECTIONS matrix to store the projection values:
% A matrix that is going to store the projection values are formed here
% with rows representing beams and columns representing projection angles.
PROJECTIONS = zeros(length(t_s),length(thetas));

%% Main Loop
% There are 2 loops passing through each beam and angle to compute the
% projection value. First loop iterates on angle values and the second loop
% interates on beams.
for angle = 1:length(thetas)
    theta = thetas(angle);
    for ray = 1:length(t_s)
        t = t_s(ray);   
        %%
        % Creating intersection vectors for each angle using the equation
        % _t_ = cos($$ \  \theta $$)  _x_  +  sin($$ \  \theta $$)  _y_

        intersect_y = ((t - X_grid * cos(theta)) / sin(theta));
        intersect_x = ((t - Y_grid * sin(theta)) / cos(theta));
        %%
        % Putting the sorted intersections in a matrix where first column is x,
        % second is y and merge them: 
        INTERSECTS_x = [X_grid'  intersect_y'];
        INTERSECTS_y = [intersect_x'  Y_grid'];
        INTERSECTS_all = [INTERSECTS_x ; INTERSECTS_y];
%         INTERSECTS_all = sortrows(unique(INTERSECTS_all,'rows'));
        INTERSECTS_all = sortrows(uniquetol(INTERSECTS_all,'ByRows',1e-10));
        %%
        % Discarding the intersections out of the grid by conditionally
        % selecting the rows
        INTERSECTS_all = INTERSECTS_all(INTERSECTS_all(:,1)>=left_end & INTERSECTS_all(:,1)<=right_end & INTERSECTS_all(:,2)>=left_end & INTERSECTS_all(:,2)<=right_end,:);
        %%
        % Assigning 0 projection value for 1 point intersections.
        if size(INTERSECTS_all,1) == 1
        PROJECTIONS(ray,angle) = 0;
        continue
        end
        %%
        % Using Pisagor to compute distances travelled in pixels by
        % computing the $$ l_2 $$ norm row vectors of intersection matrix
        weights = vecnorm(diff(INTERSECTS_all),2,2); 
        %%
        % Arithmetic mean of consecutive elements to find mid point: To
        % find the mid point between consecutive intersections, 2 point
        % moving average is used with factor 0.5.
        midpoints_x = movsum(INTERSECTS_all(:,1),2) * 0.5;
        midpoints_y = movsum(INTERSECTS_all(:,2),2) * 0.5;
        
        %%
        % MATLAB function movesum padds a 0 to the beginning of the
        % vector. To get rid of this extra entry at the beginning, vectors
        % are sliced.
        % This block of code is problematic when there is 1 intersection. 
        % Hence, if block above is added.
        midpoints_y = midpoints_y(2:end); 
        midpoints_x = midpoints_x(2:end);
        
        
        %%
        % The pixels that beam passes through are found.
        row_pixel_indices = right_end - floor(midpoints_y);
        column_pixel_indices = right_end + ceil(midpoints_x);
        
        %%
        % The pixel values are extracted and stored in a vector.
        
        pixels = zeros(length(column_pixel_indices),1);
        
        for i = 1:length(column_pixel_indices)
            pixels(i) = I(row_pixel_indices(i),column_pixel_indices(i));
        end
        
        %%
        % Projection is just the  weighted sum of pixel values weighted
        % with distance weights. It's basically a dot product.
        
        projection_val = dot(weights,pixels);
        PROJECTIONS(ray,angle) = projection_val;
    end
end
end
