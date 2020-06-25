function [cell_seq_parts, sz_seq_parts] = ck_seq2parts( seq, sz_seq, cntmx_parts, is_overlapped )

cnt_parts = prod(cntmx_parts);

cnt_r_parts = zeros(cntmx_parts(1),1);
cnt_c_parts = zeros(cntmx_parts(2),1);

cell_idxes_r_seq_parts = cell( cntmx_parts(1),1 );
cell_idxes_c_seq_parts = cell( cntmx_parts(2),1 );

if( is_overlapped )
    cnt_base_parts = floor(sz_seq ./ (cntmx_parts + 1) * 2);    
    cnt_r_parts(:) = cnt_base_parts(1);
    cnt_c_parts(:) = cnt_base_parts(2);
        
    modidx_part = mod( sz_seq, cntmx_parts );
    sup_begin = ceil( (cntmx_parts-modidx_part)/2 );
    sup_end = sup_begin + (modidx_part - 1);
    
    if( sup_end(1) > sup_begin(1) )
        cnt_r_parts(sup_begin(1):sup_end(1)) = cnt_r_parts(sup_begin(1):sup_end(1)) + 1;
    end
    if( sup_end(2) > sup_begin(2) )
        cnt_c_parts(sup_begin(2):sup_end(2)) = cnt_c_parts(sup_begin(2):sup_end(2)) + 1;
    end
    
    idx_begin = 1;
    for i=1:cntmx_parts(1)
        cell_idxes_r_seq_parts{i} = floor( [idx_begin:(idx_begin+(cnt_r_parts(i)-1))]' );
        idx_begin = idx_begin + cnt_base_parts(1)/2;
    end

    idx_begin = 1;
    for i=1:cntmx_parts(2)
        cell_idxes_c_seq_parts{i} = floor( idx_begin:(idx_begin+(cnt_c_parts(i)-1)) );
        idx_begin = idx_begin + cnt_base_parts(2)/2;
    end
else
    cnt_base_parts = floor(sz_seq ./ cntmx_parts);    
    cnt_r_parts(:) = cnt_base_parts(1);
    cnt_c_parts(:) = cnt_base_parts(2);
        
    modidx_part = mod( sz_seq, cntmx_parts );
    sup_begin = ceil( (cntmx_parts-modidx_part)/2 );
    sup_end = sup_begin + (modidx_part - 1);
    
    if( sup_end(1) > sup_begin(1) )   
        cnt_r_parts(sup_begin(1):sup_end(1)) = cnt_r_parts(sup_begin(1):sup_end(1)) + 1;
    end
    if( sup_end(2) > sup_begin(2) )
        cnt_c_parts(sup_begin(2):sup_end(2)) = cnt_c_parts(sup_begin(2):sup_end(2)) + 1;
    end
    
    idx_begin = 1;
    for i=1:cntmx_parts(1)
        cell_idxes_r_seq_parts{i} = floor( [idx_begin:(idx_begin+(cnt_r_parts(i)-1))]' );
        idx_begin = idx_begin + cnt_r_parts(i);
    end

    idx_begin = 1;
    for i=1:cntmx_parts(2)
        cell_idxes_c_seq_parts{i} = floor( idx_begin:(idx_begin+(cnt_c_parts(i)-1)) );
        idx_begin = idx_begin + cnt_c_parts(i);
    end
end

cell_seq_parts = cell( cnt_parts, 1 );
sz_seq_parts = zeros( cnt_parts, 2 );
idx = 1;
for c=1:cntmx_parts(2)
    for r=1:cntmx_parts(1)       
       idxes = cell_idxes_r_seq_parts{r} * ones(1,cnt_c_parts(c)) + ...
                ((ones(cnt_r_parts(r),1) * cell_idxes_c_seq_parts{c} - 1) * sz_seq(1));
       idxes = reshape( idxes, cnt_r_parts(r) * cnt_c_parts(c), 1 );

       cell_seq_parts{idx} = seq(idxes);
       sz_seq_parts(idx,:) = [cnt_r_parts(r) , cnt_c_parts(c)];

       idx = idx + 1;
   end
end


