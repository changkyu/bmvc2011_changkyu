function [T_part , sz_T_part] = ck_InitTemplates_parts(tsize, img_name, cpt, nT, cntmx_parts, is_overlapped)


% generate templates from single image
%   (r1,c1) ***** (r3,c3)            (1,1) ***** (1,cols)
%     *             *                  *           *
%      *             *       ----->     *           *
%       *             *                  *           *
%     (r2,c2) ***** (r4,c4)              (rows,1) **** (rows,cols)
% r1,r2,r3;
% c1,c2,c3

%% prepare templates geometric parameters
p{1}= cpt;
p{2} = cpt + [-1 0 0; 0 0 0];
p{3} = cpt + [1 0 0; 0 0 0];
p{4} = cpt + [0 -1 0; 0 0 0];
p{5} = cpt + [0 1 0; 0 0 0];
p{6} = cpt + [0 0 1; 0 0 0];
p{7} = cpt + [0 0 0; -1 0 0];
p{8} = cpt + [0 0 0; 1 0 0];
p{9} = cpt + [0 0 0; 0 -1 0];
p{10} = cpt + [0 0 0; 0 1 0];

%% Initializating templates and image
%jeany
% T	= zeros(prod(tsize),nT);

% nz	= strcat('%0',num2str(numzeros),'d');
% image_no = sfno;
% fid = sprintf(nz, image_no);
% img_name = strcat(fprefix,fid,'.',fext);

img = imread(img_name);
if(size(img,3) == 3)
    img = double(rgb2gray(img));
end

%% cropping and normalizing templates
%jeany
for n=1:nT
%     [T(:,n),T_norm(n),T_mean(n),T_std(n)] = ...
% 		corner2image(img, p{n}, tsize);   

    afnv_obj = corners2afnv( p{n}, tsize);
    map_afnv = afnv_obj.afnv;
    img_map = IMGaffine_r(img, map_afnv, tsize);

    T(:,n) = reshape(img_map, prod(tsize), 1);
end

% divide into several parts
cnt_parts = prod(cntmx_parts);
T_part = cell(nT,1);
for n=1:nT
    [T_part{n}, sz_T_part] = ck_seq2parts( T(:,n), tsize, cntmx_parts, is_overlapped );    

    for p=1:cnt_parts
        [gly_crop,gly_crop_mean,gly_crop_std] = gly_zmuv( T_part{n}{p} ); %gly_crop is a vector
        gly_crop_norm = norm(gly_crop);
        T_part{n}{p} = gly_crop/gly_crop_norm;
    end
end

end

