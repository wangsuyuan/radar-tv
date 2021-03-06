function [ A R ] = radon_tomo(P,theta)
%Creates a 2D tomography test problem using Radon parallel beams technique
%
%   [A R] = paralleltomo(I,N,theta)


% This function creates a 2D tomography test problem with an N-times-N
% domain, using p parallel rays for each angle in the vector theta.
%
% Input: 
%   P           The image must be a square N-times-N
%
%   theta       Vector containing the angles in degrees. Default: theta = 
%               0:1:179.
%
% Output:
%   A           Coefficient matrix with N^2 columns and Number angles * Number of parallel rays for each angle rows, 
%             
%   R           Vector containing the results of projections


%Seek N the size of the image
[N,~]=size(P);

% The distance from the first ray to the last.

    d = sqrt(2)*N;

% The number of rays.  

    p = round(d);


% Default value of the angles theta.
if nargin < 2 || isempty(theta)
    theta = 0:179;
end

% Define the number of angles.
nA = length(theta);

% The starting values both the x and the y coordinates. 
x0 = linspace(-d/2,d/2,p)';
y0 = zeros(p,1);

% The intersection lines.
x = (-N/2:N/2)';
y = x;

% Initialize vectors that contains the row numbers, the column numbers and
% the values for creating the matrix A effiecently.
rows = zeros(2*N*nA*p,1);
cols = rows;
vals = rows;
idxend = 0;


% Loop over the chosen angles.
for i = 1:nA    
    
    
    % All the starting points for the current angle.
    x0theta = cosd(theta(i))*x0-sind(theta(i))*y0;
    y0theta = sind(theta(i))*x0+cosd(theta(i))*y0;
    
    % The direction vector for all the rays corresponding to the current 
    % angle.
    a = -sind(theta(i));
    b = cosd(theta(i));
    
    % Loop over the rays.
    for j = 1:p
        
        % Use the parametrisation of line to get the y-coordinates of
        % intersections with x = k, i.e. x constant.
        tx = (x - x0theta(j))/a;
        yx = b*tx + y0theta(j);
        
        % Use the parametrisation of line to get the x-coordinates of
        % intersections with y = k, i.e. y constant.
        ty = (y - y0theta(j))/b;
        xy = a*ty + x0theta(j);

        
        % Collect the intersection times and coordinates. 
        t = [tx; ty];
        xxy = [x; xy];
        yxy = [yx; y];
        
        % Sort the coordinates according to intersection time.
        [t I] = sort(t);
        xxy = xxy(I);
        yxy = yxy(I);        
        
        % Skip the points outside the box.
        I = (xxy >= -N/2 & xxy <= N/2 & yxy >= -N/2 & yxy <= N/2);
        xxy = xxy(I);
        yxy = yxy(I);
        
        % Skip double points.
        I = (abs(diff(xxy)) <= 1e-10 & abs(diff(yxy)) <= 1e-10);
        xxy(I) = [];
        yxy(I) = [];
        
        % Calculate the length within cell and determines the number of
        % cells which is hit.
        d = sqrt(diff(xxy).^2 + diff(yxy).^2);
        numvals = numel(d);
        
        % Store the values inside the box.
        if numvals > 0
            
            % If the ray is on the boundary of the box in the top or to the
            % right the ray does not by definition lie with in a valid cell.
            if ~((b == 0 && abs(y0theta(j) - N/2) < 1e-15) || ...
                 (a == 0 && abs(x0theta(j) - N/2) < 1e-15)       )
                
                % Calculates the midpoints of the line within the cells.
                xm = 0.5*(xxy(1:end-1)+xxy(2:end)) + N/2;
                ym = 0.5*(yxy(1:end-1)+yxy(2:end)) + N/2;
                
                % Translate the midpoint coordinates to index.
                col = floor(xm)*N + (N - floor(ym));
                
                % Create the indices to store the values to vector for
                % later creation of A matrix.
                idxstart = idxend + 1;
                idxend = idxstart + numvals - 1;
                idx = idxstart:idxend;
                
                % Store row numbers, column numbers and values. 
                rows(idx) = (i-1)*p + j;
                cols(idx) = col;
                vals(idx) = d;   
                
            end
        end
        
    end
end

% Truncate excess zeros.
rows = rows(1:idxend);
cols = cols(1:idxend);
vals = vals(1:idxend);

% Create sparse matrix A from the stored values.
A = sparse(rows,cols,vals,p*nA,N^2);

% Reshaping the image on only one row
P=P(:);
% Create rhs.
   R = A*P;
% Reshpe the row R to the matrix R, the Radon sinogram.
R=reshape(R,p,nA);

end

