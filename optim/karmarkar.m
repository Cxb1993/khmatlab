function [x, cf, xtraj, cftraj, its, s, lambda, flag] = karmarkar(x0, H, c, D, f)
% [x, flag] = karmarkar(x0, H, c, D, f)
% Karmarkars optimization algorithm for the quadratic programming
% problem with inequality constraints
%   min       0.5*x'*H*x + c'*x
%   subj to   D*x > f
%
% Input
%    x0   ->  initial value. Vector of length n
%    H    ->  n x n (symmetric) matrix
%    c    ->  n x 1 vector
%    D    ->  m x n matrix
%    f    ->  m x 1 vector
%
% Output
%    x    ->  solution
%    cf   ->  value of criterion fcn at solution

% Kjartan Halvorsen
% 2008-05-15

if nargin > 0

  crit_thr = 1e-12;
 
  % Criteria for stopping the algorithm
  delta_x_thr = 1e-14;
  delta_fcn_thr = 1e-14;
  delta_x = 1;
  delta_fcn = 1;

  % Sizes
  n = length(x0);
  m = length(f);

  %initial values
  eta = 0.999;
  my = ones(size(f));
  s = ones(size(f));
  lambda = s;

  % left hand matrix in the system of equations solved in each
  % iteration. Only the last block row is updated.
  AA = cat(1, ...
	   cat(2, H, zeros(n, m), -D'), ...
	   cat(2, D, -eye(m, m), zeros(m,m)), ...
	   zeros(m, 2*m+n));
  % right hand side. Just allocate memory
  bb = zeros(n+2*m, 1);

  x = x0;
  cf_old = x'*H*x + c'*x;

  if nargout > 2
    xtraj = x;
    cftraj = cf_old;
  end
  
  its = 0;
  while ( (delta_x > delta_x_thr) & (delta_fcn > delta_fcn_thr) ) 
    its = its+1;
    % Calculate search direction
    AA(n+m+1:end, n+1:n+m) = diag(lambda);
    AA(n+m+1:end, n+m+1:end) = diag(s);
    bb(1:n) = -H*x - c + D'*lambda;
    bb(n+1:n+m) = -D*x + s + f;
    bb(n+m+1:end) = -diag(s)*lambda + my;
    
    %sdir = AA\bb;
     [U,S,V] = svd(AA);
     sdir = generalized_inverse(U,S,V)*bb;
    
    % Max step length
    deltas = sdir(n+1:n+m);
    deltalambda = sdir(n+m+1:end);
    
    ds_nonzero = find(deltas ~= 0);
    dl_nonzero = find(deltalambda ~= 0);
    alpha_s_all = -s(ds_nonzero)./deltas(ds_nonzero);
    alpha_max_s = min(alpha_s_all(find(alpha_s_all > 0)));
    if (isempty(alpha_max_s))
      alpha_max_s = 1;
    end
    
    
    alpha_l_all = -lambda(dl_nonzero)./deltalambda(dl_nonzero);
    alpha_max_l = min(alpha_l_all(find(alpha_l_all > 0)));
    if (isempty(alpha_max_l))
      alpha_max_l = 1;
    end
    
    alpha_max = min(alpha_max_s, alpha_max_l);
    if isempty(alpha_max)
      alpha_max = 0;
    end
    
    alpha = min(1, eta*alpha_max);
    
    %keyboard
    % Update
    x = x + alpha*sdir(1:n);
    s = s + alpha*deltas;
    lambda = lambda + alpha*deltalambda;
    
    my = my./10;
    
    cf_new = 0.5*x'*H*x + c'*x;
    delta_fcn = abs(cf_new - cf_old);
    cf_old = cf_new;
    delta_x = max(abs(alpha*sdir(1:n)));

    if nargout > 2
      xtraj = cat(2, xtraj, x);
      cftraj = cat(1, cftraj, cf_old);
    end

  end % while loop
  
  cf = cf_old;

  % Test solution
  crit1 = D*x-s-f;
  crit2 = H*x - D'*lambda + c;
  crit3 = diag(s)*lambda;

  if (  ( max(abs(crit1)) > crit_thr) ...
       |( max(abs(crit2)) > crit_thr) ...
       |( max(abs(crit3)) > crit_thr) )
    warning('Test of optimality above threshold');
    crit1
    crit2
    crit3
  end
  


else % unit test
  
  % Simple two dimensional problem
  A = randn(2,2);
  H = A'*A;
  c = randn(2,1);
  
  D = cat(1, eye(2), [-1 -1]);
  f = [0;0;-2];

  x0 = [0.5; 0.5];

  [x, cf_sol, xtraj, cftraj, its, s, lambda] = karmarkar(x0, H, c, D, f);
  cftraj
  
  % Test solution
  disp('The following expressions should be close to zero')
  crit1 = D*x-s-f
  crit2 = H*x - D'*lambda + c
  crit3 = diag(s)*lambda
  disp('The following vectors should have all positive elements')
  s
  lambda
  
  % plot results
  figure(1)
  clf
  np = 40;
  xx = linspace(-0.5, 2, np);
  yy = linspace(-0.5, 2, np);
  
  cf = zeros(np,np);
  for i=1:np
    for j=1:np
      xij = [xx(j); yy(i)];
      cf(i,j) = xij'*H*xij + c'*xij;
    end
  end
  
  nc = 20;
  contour(xx, yy, cf, nc);
  hold on
  %plot3(xtraj(1,:)', xtraj(2,:)', cftraj);
  %plot3(x(1), x(2), cf_sol, 'ro');
  plot(xtraj(1,:)', xtraj(2,:)', 'm', 'LineWidth', 2);
  plot(x(1), x(2), 'ro', 'MarkerSize', 12, 'LineWidth', 2);
  plot(x0(1), x0(2), 'bs', 'MarkerSize', 12, 'LineWidth', 2);
  title(['#iterations = ', int2str(its)])
  xlabel('x')
  ylabel('y')
  

end


