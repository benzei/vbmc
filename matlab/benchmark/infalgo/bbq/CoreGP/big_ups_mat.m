function mat = big_ups_mat...
    (sqd_dist_stack_Amu, sqd_dist_stack_Bmu, sqd_dist_stack_AB, ...
    gp_A_hypers, gp_B_hypers, prior)
% Returns the matrix
% Ups_s_s' = int K(x_s, x) K(x, x_s') prior(x) dx
% = V_A * V_B * N([x_s, x_s'], [mu, mu], [W_A + L, L; L, W_B + L]);
% where x_s is an element of A (forming the rows), which is modelled by a
% GP with sqd input scales W_A and sqd output scales V_A. 
% where x_s' is an element of B (forming the cols), which is modelled by a
% GP with sqd input scales W_B and sqd output scales V_B. 
% the prior is Gaussian with mean mu and variance L.

num_dims = size(sqd_dist_stack_Amu, 3);

th_A = gp_A_hypers.log_input_scales;
th_B = gp_B_hypers.log_input_scales;
th_L = log(sqrt(diag(prior.covariance)))';

sqd_input_scales_stack_A = ...
    reshape(exp(2*th_A), 1, 1, num_dims);
sqd_input_scales_stack_B = ...
    reshape(exp(2*th_B), 1, 1, num_dims);



prior_var_stack = reshape(diag(prior.covariance), 1, 1, num_dims);

prior_var_times_sqd_dist_stack_AB = bsxfun(@times, prior_var_stack, ...
                    sqd_dist_stack_AB);

opposite_A = sqd_input_scales_stack_A;
opposite_B = sqd_input_scales_stack_B;


log_out_factor = 4/num_dims * ...
    (gp_A_hypers.log_output_scale + gp_B_hypers.log_output_scale);

% 2 pi does nto have to be sqrt-ed because each element of determ is
% actually the determinant of a 2 x 2 matrix
constant = (2*pi)^(-num_dims)...
    * prod((...
        exp(2*th_A + 2*th_B - log_out_factor) + ...
        exp(2*th_L + 2*th_B - log_out_factor) + ...
        exp(2*th_L + 2*th_A - log_out_factor)).^(-0.5));
    
inv_determ_del_r = (prior_var_stack.*(...
    sqd_input_scales_stack_B + sqd_input_scales_stack_A) + ...
    sqd_input_scales_stack_B.*sqd_input_scales_stack_A).^(-1);


mat = constant .* ...
    exp(-0.5 * sum(bsxfun(@times,inv_determ_del_r,...
                    bsxfun(@plus, ...
                        bsxfun(@times, opposite_B, ...
                            sqd_dist_stack_Amu), ...
                        bsxfun(@times, opposite_A, ...
                            tr(sqd_dist_stack_Bmu)) ...
                    ) + prior_var_times_sqd_dist_stack_AB...
                ),3));

            
%     % some code to test that this construction works          
%     Lambda = diag(prior_var);
%     W_del = diag(del_input_scales.^2);
%     W_r = diag(logl_input_scales.^2);
%     mat = kron(ones(2),Lambda)+blkdiag(W_del,W_r);
% 
%     Ups_sca_a_test = @(i) del_sqd_output_scale * l_sqd_output_scale *...
%         mvnpdf([x_sc(i,:)';new_sample_location'],[prior.mean';prior.mean'],mat);