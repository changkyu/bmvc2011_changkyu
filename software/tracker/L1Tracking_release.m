function [track_res] = L1Tracking_release( mode, s_frames, sz_T, n_sample, init_pos, ...
    s_debug_path,  fcdatapts, rect_GT)
% L1Tracking  Visual tracking using L1-regularized least square.
%	[track_res] = L1Tracking( s_frames, sz_T, n_sample, init_pos )
%	tracks a target defined by the user using 'init_pos'
%
% Input:
%	s_frames	- names of sequence images to be tracked.
%	sz_T		- template size, e.g. 12 x 15
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1-------------------p3
% 				\					\
% 				 \       target      \
% 				  \                   \
% 				  p2-------------------\
%
% Output:
%	track_res - a 6xN matrix where each column contains the six affine parameters
%		for the corresponding frame, where N is the number of frames.
%
% For more details, refer to
%		X. Mei and H. Ling, Robust Visual Tracking using L1 Minimization,
%		IEEE International Conference on Computer Vision (ICCV), Kyoto, Japan, 2009.
%
% Xue Mei and Haibin Ling, Oct. 2009

%% Initialize T
%-Generate T from single image
nT			= 10;		% number of templates used, fixed in this version
img_name	= s_frames{1};
[T,T_norm,T_mean,T_std] = InitTemplates(sz_T,img_name,init_pos);

norms = T_norm.*T_std; %template norms

%% L1 function settings
lambda	= .01;
rel_tol = 0.01;
quiet	= true;

dim_T	= size(T,1);	%number of elements in one template, sz_T(1)*sz_T(2)=12x15 = 180
% A		= [T eye(dim_T) -eye(dim_T)]; %data matrix is composed of T, positive trivial T.
A		= [T eye(dim_T) -eye(dim_T)]; %suha: data matrix is composed of T, positive trivial I, and negative trivial -I
alpha = 30;
aff_obj = corners2afnv(init_pos, sz_T); %get affine transformation parameters from the corner points in the first frame
map_aff = aff_obj.afnv;
aff_samples = ones(n_sample,1)*map_aff;
if( mode == 0 )
    rel_std_afnv = [0.005,0.0005,0.0005,0.005,3,3];
else
%     rel_std_afnv = [0.005,0.0005,0.0005,0.005,1,1];
%     rel_std_afnv = [0.06,0.01,0.01,0.06,1,1];
     rel_std_afnv = [0.01,0.005,0.005,0.01,1,1];       
end

W = [1 1 1 1 1 1 1 1 1 1]; %W are initialized to
T_id	= -(1:10);	% template IDs, for debugging
fixT = T(:,1)/nT; % first template is used as a fixed template

%% [cksong] Template for partition

cntmx_parts = [3,3];
cnt_parts = prod(cntmx_parts);
is_overlapped = false;

% T_part = cell(nT,1);
% for n=1:nT
%     [T_part{n}, sz_T_part] = ck_seq2parts( T(:,n), sz_T, cntmx_parts, is_overlapped );    
% end

[T_part,sz_T_part] = ck_InitTemplates_parts( sz_T, img_name, init_pos, nT, cntmx_parts, is_overlapped);

A_part = cell( cnt_parts, 1 );
dim_T_part = zeros(cnt_parts,1);
for p=1:cnt_parts
    
    dim_T_part(p) = prod(sz_T_part(p,:));
    A_part{p} = zeros( dim_T_part(p), nT + dim_T_part(p) );
    
    for n=1:nT
        A_part{p}(:,n) = T_part{n}{p};
    end
%     A_part{p}(:,(n+1):n+dim_T_part(p)) = eye( dim_T_part(p) );
    A_part{p}(:,(n+1):n+2*dim_T_part(p)) = [eye( dim_T_part(p) ), -eye( dim_T_part(p) )];  % suha: negative trivial templates for part reconstruction
    
end

fixT_part = ck_seq2parts( fixT, sz_T, cntmx_parts, is_overlapped );

%% rankings

ranking_cut = -inf;
valid_samples_cut = inf;


%% Tracking
nframes	= length(s_frames);
track_res	= zeros(6,nframes);

train_data = cell(nframes,1);
result_data = cell(nframes,1);

tic;

for t = 1:nframes

    fprintf('Frame number: %d \n',t); %image_no);
    
    img_color	= imread(s_frames{t});
    if(size(img_color,3) == 3)
        img     = double(rgb2gray(img_color));
    else
        img     = double(img_color);
    end
    
    if( mode == 1 && t == 1 )
        [aff_samples, count] = Seg_resample(2, aff_samples, (ones(n_sample,1))/n_sample, map_aff, sz_T);
    end
    
    %-Draw transformation samples from a Gaussian distribution
    sc			= sqrt(sum(map_aff(1:4).^2)/2);
    
    std_aff		= rel_std_afnv.*[1, sc, sc, 1, sc, sc];
    map_aff		= map_aff + 1e-14;
    aff_samples = Seg_draw_sample(aff_samples, std_aff); %draw transformation samples from a Gaussian distribution

    % [cksong] randomize samples index    
    idx_rand = randperm(n_sample);
    aff_samples_tmp = [aff_samples, idx_rand'];
    aff_samples_tmp = sortrows( aff_samples_tmp, size(aff_samples_tmp,2) );
    aff_samples = aff_samples_tmp(:,1:6);
    %~[cksong]

    
    %-Crop candidate targets "Y" according to the transformation samples
    [Y, Y_inrange] = Seg_gly_crop(img, aff_samples(:,1:6), sz_T);
    if(sum(Y_inrange==0) == n_sample)
        sprintf('Target is out of the frame!\n');
    end
    
%     [Y,Y_crop_mean,Y_crop_std] = gly_zmuv(Y);	 % zero-mean-unit-variance
%     [Y, Y_crop_norm] = normalizeTemplates(Y);

    %-L1-LS for each candidate target
    eta_max	= -inf;
    eta_1	= zeros(n_sample,1);
    
    % [cksong]
    n_subset_samples = 30;
    cnt_valid_samples = 0;
    cnt_used_samples = 0;
    indexes_used_samples = zeros(n_sample,1);
    
    d_1_part        = zeros(cnt_parts, n_sample);
    likelihood      = zeros(cnt_parts, n_sample);
    rankings        = zeros(n_sample,1);

    classify_param = zeros(cnt_parts,n_subset_samples);
    cnt_classify_param = 0;
    indexes_classify_param = zeros(n_subset_samples,1);

    id_max = -inf;
    min_ranking = inf;
    %~[cksong]    
        
    for i=1:n_sample
        % ignore the out-of-frame image patch and constant image patch
%         if(Y_inrange(i) == 0 || sum(abs(Y(:,i))) == 0)
%             continue;
%         end


%         param.lambda = 0.01;
%         param.lambda2 = 0;
%         param.mode = 2;
%         param.L = length(Y(:,i));

% [cksong] ORG
%         param.lambda = 0.01;
%         param.lambda2 = 0;
%         param.mode = 2;
%         param.L = length(Y(:,i));
%         
%         c = mexLasso(Y(:,i), [A fixT], param);
%         c = full(c);
%  
%         D_s = (Y(:,i) - [A(:,1:nT) fixT]*[c(1:nT); c(end)]).^2;
%         eta_1(i) = exp(-alpha*sqrt(sum(D_s)));
%       
%         if(sum(c(1:nT))<0) %remove the inverse intensity patterns
%             continue;
%         elseif(eta_1(i)>eta_max)
%             id_max	= i;
%             c_max	= c;
%             eta_max = eta_1(i);
%         end
%~[cksong] ORG

        % [cksong] 
        % divide sample's frame into # of partitions,
        % and calculate the distance of each ones.
        
        % calculate distance
        [Y_part, sz_Y_part] = ck_seq2parts( Y(:,i), sz_T, cntmx_parts, is_overlapped );        
        
        for p=1:cnt_parts
            [Y_part{p},Y_crop_mean_part,Y_crop_std_part] = gly_zmuv(Y_part{p});	 % zero-mean-unit-variance
            [Y_part{p}, Y_crop_norm_part] = normalizeTemplates(Y_part{p});
        end
        
        c_part = zeros(cnt_parts,size(A_part{p},2) + 1);
        
        param.lambda = 0.01;
        param.lambda2 = 0;
        param.mode = 2;       
        param.pos = true;   % suha: positivity constraint
                
        for p=1:cnt_parts
            param.L = length(Y_part{p});
            c_part(p,:) = mexLasso(Y_part{p}, [A_part{p} fixT_part{p}], param)';
            D_s = (Y_part{p} - [A_part{p}(:,1:nT) fixT_part{p}]*[c_part(p,1:nT)'; c_part(p,end)']).^2;
            %d_1_part(p,i) = sqrt(sum(D_s)); dist
            d_1_part(p,i) = sum(D_s); % dist sq
            likelihood(p,i) = exp(-10*sqrt(sum(D_s))) * 100;
        end

        if(sum(c_part(:,1:nT))<0)
            continue;
        end
        
        if( mode == 1 )
        
            cnt_classify_param = cnt_classify_param + 1;

            indexes_classify_param(cnt_classify_param) = i;
            classify_param(:,cnt_classify_param) = d_1_part(:,i);
            %classify_param(:,cnt_classify_param) = likelihood(:,i);

            if( (cnt_classify_param == n_subset_samples) || (i == n_sample) )

                if( i==n_sample )
                    classify_param = classify_param(:,1:cnt_classify_param);
                    indexes_classify_param = indexes_classify_param(1:cnt_classify_param);
                    indexes_used_samples = indexes_used_samples(1:(n_sample - (n_subset_samples-cnt_classify_param) ));
                end

                rankings(indexes_classify_param) = ck_RVMclassifyLikelihood( classify_param' );

                [min_subset_ranking min_subset_id] = min(rankings(indexes_classify_param));
                if( min_ranking > min_subset_ranking  )
                    min_ranking = min_subset_ranking;
                    id_max = indexes_classify_param(min_subset_id);
                end

                test = 0;
                test = rankings(indexes_classify_param) > 20;
                if( sum( test ) < 0 )
                   a = 1; 
                end
                
                mx_is_valid_samples = rankings(indexes_classify_param) <= ranking_cut;
                cnt_valid_samples = cnt_valid_samples + sum(mx_is_valid_samples);
                indexes_used_samples( (cnt_used_samples+1):cnt_used_samples+cnt_classify_param ) = indexes_classify_param;
                cnt_used_samples = cnt_used_samples + cnt_classify_param;

                % if we get enough number of valid samples, stop calculate
                % likelihood
                if( cnt_valid_samples >= valid_samples_cut )
                    if( mode == 1 )
                        break;
                    end
                end          

                cnt_classify_param = 0;            
                indexes_classify_param = zeros(n_subset_samples,1);
            end
        
        else
            
            cnt_valid_samples = cnt_valid_samples + 1;
            cnt_used_samples = cnt_used_samples + 1;
            indexes_used_samples = 1:n_sample;
            
        end
        % ~[cksong]
        
    end
    
    if( mode == 0 )
        datas = zeros(n_sample,4 + cnt_parts + 1); % col : rank qid (reference value for rank) values ( .. )

        gt_obj = corners2afnv( rect_GT(:,1:3,t), sz_T );
        gt_aff = gt_obj.afnv;

        ratios = ck_IntersectionAreaRatio(gt_aff, sz_T, aff_samples);      

        [ maxS, id_max ] = max(ratios);

        % accending
        for i=1:n_sample
            datas(i,3) = ratios(i);                         % reference 1st value for evaluate rank
%             datas(i,4) = sum( d_1_part(:,i) ) / cnt_parts;   % reference 2nd value for evaluate rank
%             datas(i,5:(5+(cnt_parts-1))) = d_1_part(:,i);    % values
              datas(i,4) = sum( likelihood(:,i) ) / cnt_parts;
              datas(i,5:(5+(cnt_parts-1))) = likelihood(:,i);
        end

        datas(:,end) = 1:n_sample;

        datas = sortrows( datas, [-3 4] );                  % sort datas by reference value
        datas(:,2) = 1;%idx_frame;                             % qid
        datas(:,1) = 1:n_sample;                            % ranking

        rankings = zeros( n_sample, 1 );
        rankings(datas(:,end)) = 1:n_sample;
        datas = datas(:,1:end-1);
        % decending
        % rankings = round(ratios * 100);
        % for i=1:n_sample
        %     datas(i,1) = rankings(i);
        %     datas(i,2) = idx_frame;
        %     datas(i,3) = ratios(i);
        %     datas(i,4) = 0;
        %     datas(i,5:(5+(cnt_part-1))) = SamplesObj.d_1_part(:,i); % values
        % end

        % remove other rankings except        
%         n_elem = floor(n_sample / (3*5-1));
% 
%         datas(1:n_elem,1) = 1;
%         datas(n_elem*2+1:n_elem*3,1) = 50;
%         datas(end-n_elem+1:end,1) = 100;
%         datas_in = [datas(1:n_elem,:); datas(n_elem*2+1:n_elem*3,:); datas(end-n_elem+1:end,:)];
        datas(1:10,1) = 1;
        datas(21:40,1) = 10;
        datas(61:100,1) = 30;
        %datas(141:220,1) = 70;
        datas(301:600,1) = 100;

        datas_in = [datas(1:10,:); datas(21:40,:); datas(61:100,:); datas(141:220,:); datas(301:600,:)];
        
        % write Train.dat file
        ck_createTrainDAT(datas_in,t);
    elseif( mode == 1 && t == 1 )
        init_obj = corners2afnv( init_pos, sz_T );
        init_aff = init_obj.afnv;        
        ratios = ck_IntersectionAreaRatio(init_aff, sz_T, aff_samples);

        idx_tmp = find( ratios < 0.8 );
        ratios_tmp = ratios(idx_tmp);
        [max_v, idx_v] = max(ratios_tmp);
                
        ranking_cut = rankings(idx_tmp(idx_v));
        valid_samples_cut = 25;
    elseif( mode == 2 )
        gt_obj = corners2afnv( rect_GT(:,1:3,t), sz_T );
        gt_aff = gt_obj.afnv;
        ratios = ck_IntersectionAreaRatio(gt_aff, sz_T, aff_samples);
        [ maxS, id_max ] = max(ratios);
                
        %rank = ck_RVMclassifyLikelihood( likelihood' );        
        rankings = ck_RVMclassifyLikelihood( d_1_part' );        
        %rankings = ck_RVMclassifyLikelihood( sqrt(d_1_part)' );        
    end
    
    if( mode ~= 1 )
    train_data{t}.d_1_part = d_1_part;
    train_data{t}.ratios = ratios;
    train_data{t}.rankings = rankings;
    end
        
    % [cksong]
fprintf('\n');
fprintf('[cksong] enough number of valid samples (%d/%d)\n',cnt_valid_samples,i);
fprintf('[cksong] min_ranking : %f max_ranking : %f\n',min(rankings), max(rankings));

fprintf('[cksong] %2d %2d %2d \n',round(d_1_part((1:3) * 3 - 2,id_max)));
fprintf('[cksong] %2d %2d %2d \n',round(d_1_part((1:3) * 3 - 1,id_max)));
fprintf('[cksong] %2d %2d %2d \n',round(d_1_part((1:3) * 3 - 0,id_max)));
    
    indexes_used_samples = indexes_used_samples(1:cnt_used_samples);
    eta_1 = ck_ranks2scores(rankings,indexes_used_samples);

    
    %map_Y = Y(:,id_max);
    %map_Y = Y * eta_1;
    
    if( mode == 0 || mode == 2 )
        map_aff = aff_samples(id_max,:); 
    else
        map_aff = (aff_samples' * eta_1)';    
    end
    
    % result
    result_data{t}.map_aff = map_aff;
    result_data{t}.d_1_part = d_1_part;
    result_data{t}.rankings = rankings;
    result_data{t}.cnt_valid_samples = cnt_valid_samples;
    result_data{t}.cnt_used_samples = cnt_used_samples;
    result_data{t}.toc = toc;
    %~result
    
    [map_Y, map_Y_inrange] = Seg_gly_crop(img, map_aff, sz_T);    
    [map_Y2,map_Y2_mean,map_Y2_std] = gly_zmuv(map_Y);	 % zero-mean-unit-variance
    [map_Y2,map_Y2_norm] = normalizeTemplates(map_Y2);
    
    param.lambda = 0.01;
    param.lambda2 = 0;
    param.mode = 2;
    param.pos = true;
    param.L = length(map_Y2);
    
    c_max = mexLasso(map_Y2, [A fixT], param);
    c_max = full(c_max);
    
              
    %~[cksong]
    
    %id_max	= find_max_no(eta_1);
    %map_aff = aff_samples(id_max,1:6); %target transformation parameters with the maximum probability
    a_max	= c_max(1:nT);
    [aff_samples, count] = Seg_resample(mode, aff_samples, eta_1, map_aff, sz_T); %resample the samples wrt. the probability
    [maxA, indA] = max(a_max);
 
    min_angle = images_angle(map_Y,A(:,indA));
    
    %-Template update    
    W = W.*exp(a_max)';
    if( min_angle > 60 ) % 60
        % find the tempalte to be replaced
        
        %jeany 
%         W(find(W(:)==inf))=1;
         
        [temp,indW] = min(W);
        W(indW)		= 0;
        W(indW)		= median(W);

        % insert new template
%         T(:,indW)	= Y(:,id_max);
%         T_mean(indW)= Y_crop_mean(id_max);
%         T_id(indW)	= t; %track the replaced template for debugging
%         norms(indW) = Y_crop_std(id_max)*Y_crop_norm(id_max);

        T(:,indW)	= map_Y2;
        T_mean(indW)= map_Y2_mean;
        T_id(indW)	= t; %track the replaced template for debugging
        norms(indW) = map_Y2_std*map_Y2_norm;
        
        [T_part_target, sz_T_part_target] = ck_seq2parts( map_Y, sz_T, cntmx_parts, is_overlapped );
        for p=1:cnt_parts
            [T_part_target{p},tmp,tmp] = gly_zmuv(T_part_target{p});	 % zero-mean-unit-variance
            [T_part_target{p},tmp] = normalizeTemplates(T_part_target{p});
            
            T_part{indW}{p} = T_part_target{p};
        end
                
%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
indW
a_max
%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    end
    W			= normalizeWeights(W, 1); %remove it maybe
    [T, T_norm] = normalizeTemplates(T);
    T			= T.*(ones(dim_T,1)*W);
    A(:,1:nT)	= T;
    norms		= norms.*T_norm./W;
        
    for tt=1:nT
        for p=1:cnt_parts
            [T_part{tt}{p}, tmp] = normalizeTemplates(T_part{tt}{p});
            T_part{tt}{p} = T_part{tt}{p}.*(ones(dim_T_part(p),1)*W(tt));
            A_part{p}(:,tt) = T_part{tt}{p};
        end
    end
    
    %-Store tracking result
    track_res(:,t) = map_aff';
    
    %-Demostration and debugging
    if exist('s_debug_path', 'var')
%         % print debugging information
%         fprintf('minimum angle: %f\n', min_angle);
%         fprintf('T are: ');
%         for i = 1:nT
%             fprintf('%d ',T_id(i));
%         end
%         fprintf('\n');
%         fprintf('coffs are: ');
%         for i = 1:nT
%             fprintf('%.3f ',c_max(i));
%         end
%         fprintf('\n');
%         fprintf('W are: ');
%         for i = 1:nT
%             fprintf('%.3f ',W(i));
%         end
%         fprintf('\n\n');
        
        % draw tracking results
        img_color	= double(img_color);
        img_color	= showTemplates(img_color, T, T_mean, norms, sz_T, nT);
        imshow(uint8(img_color));
        text(5,10,num2str(t),'FontSize',18,'Color','r');
        color = [1 0 0];
        drawAffine(map_aff, sz_T, color, 2);
        
        % [ckosng]
        hold on;plot(aff_samples(:,6), aff_samples(:,5), '.'); 
%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
length(aff_samples(:, 1))
%%% DEBUG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        drawnow;
        
        if ~exist(s_debug_path,'dir')
            fprintf('Path %s not exist!\n', s_debug_path);
        else
            s_res	= s_frames{t}(1:end-4);
            s_res	= fliplr(strtok(fliplr(s_res),'/'));
            s_res	= fliplr(strtok(fliplr(s_res),'\'));
            s_res	= [s_debug_path s_res '_L1.png'];
            f		= getframe(gcf);
            %imwrite(uint8(fcdata(fcdatapts(1,1):fcdatapts(1,2), fcdatapts(2,1):fcdatapts(2,2), :)), s_res);
        end
    end
end

save( strcat( s_debug_path, '.\train_data.mat' ), 'train_data' );
save( strcat( s_debug_path, '.\result_data.mat' ) , 'result_data' );
