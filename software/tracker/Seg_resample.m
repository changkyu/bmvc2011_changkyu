function [map_afnv, count] = Seg_resample(mode, curr_samples, prob, afnv, sz_T)
nsamples = size(curr_samples, 1);
if(sum(prob) == 0)
    map_afnv = ones(nsamples, 1)*afnv;
    count = zeros(size(prob));
else
%% [cksong] ORG
% 
%     prob = prob / sum(prob);
%     count = round(nsamples * prob);
%     map_afnv = [];
%     for i=1:nsamples
%         for j = 1:count(i)
%             map_afnv = [map_afnv; curr_samples(i,:)];
%         end
%     end
%     ns = sum(count); %number of resampled samples can be less or greater than nsamples
%     map_afnv = [map_afnv; ones(nsamples-ns, 1)*afnv]; %if less
%     map_afnv = map_afnv(1:nsamples, :); %if more
%     
%% [cksong] NEW

    prob = prob / sum(prob);        
    count = round(nsamples * prob);    
    sum_count = sum( count );
    sum_count_seed = 0;
    
    pool_afnv = [];
    seed_afnv = [];
    for i=1:nsamples
        if( 0 < count(i) )
            for j = 1:count(i)
                pool_afnv = [pool_afnv; curr_samples(i,:)];
            end
        else
            seed_afnv = [seed_afnv; curr_samples(i,:)];
            sum_count_seed = sum_count_seed + 1;
        end        
    end
    
    if( mode == 0 || mode == 2 )
        
        if( sum_count_seed > sum_count * 0.2 )
            sum_count_seed = round(sum_count * 0.2);
        end
        sum_count_random = (sum_count + sum_count_seed);
        %idx_rand = randperm(sum_count + sum_count_seed + sum_count_random);
        
        map_afnv = [];    
        for i=1:nsamples
            %idx = idx_rand(i);
            idx = randi(sum_count + sum_count_seed + sum_count_random);
            if( idx <= sum_count )
                map_afnv = [map_afnv; pool_afnv(idx,:)];
            elseif( idx <= sum_count + sum_count_seed )
                map_afnv = [map_afnv; seed_afnv(idx-sum_count,:)];
            else                
                rand_afnv = afnv;
                
                r_rand_tmp = randi([1,sz_T(1)]);
                c_rand_tmp = randi([1,sz_T(2)]);
                
                sign_rand = (rand(1,2) > 0.5) * 2 - 1;
                rand_afnv(5:6) = rand_afnv(5:6) + sign_rand .* [r_rand_tmp,c_rand_tmp];
                
                map_afnv = [map_afnv; rand_afnv];
            end       
        end
    
    else
        
        sum_count_seed = round(sum_count * 0.2);
        %idx_rand = randperm(sum_count + sum_count_seed);
        
        map_afnv = [];    
        for i=1:nsamples
            %idx = idx_rand(i);
            idx = randi(sum_count + sum_count_seed);
            if( idx <= sum_count )
                map_afnv = [map_afnv; pool_afnv(idx,:)];
            else
                map_afnv = [map_afnv; seed_afnv(idx-sum_count,:)];
            end       
        end
        
    end
    
    
end
