
function demo_batch(test_set)

mode = 1;

%% Initialization and parameters

% PKTEST ==================================================================
if( test_set == 1 )
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path	= 'result\pktest02\'; %folder for the tracking result

%preparing frames
fprefix		= 'pktest02\frame';%folder storing the images
fext		= 'jpg';				%image format
start_frame	= 1130;%1087;					%starting frame number
nframes		= 300;					%number of frames to be tracked
sz_T		= [36 45];	%size of the template
numzeros	= 5;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});

init_pos	= [	128 150 120;
			    116 136 129];

init_pos	= [	134 156 126;
                132 152 145];

elseif( test_set == 2 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path	= 'result\Campus\'; %folder for the tracking result

%preparing frames
fprefix         = 'OR_Dataset_GT\Campus\Images\seq5-';
fext            = 'jpg';

path_GT         = 'OR_Dataset_GT/Campus/gt_boxes.mat';

start_frame     = 201;
nframes         = 182;

sz_T		= [24 30];	%size of the template
numzeros	= 3;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});

learn_GT = load( path_GT );    
init_pos = learn_GT.rect_GT(:,1:3,1);    
    

elseif( test_set == 3 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path	= 'result\Shop\'; %folder for the tracking result

%preparing frames
    
fprefix         = 'OR_Dataset_GT\CAVIAR\Images\OneShopOneWait2cor';
fext            = 'jpg';

path_GT         = 'OR_Dataset_GT\CAVIAR\gt_boxes.mat';

start_frame     = 1140;
nframes         = 315;

sz_T		= [36 45];	%size of the template
numzeros	= 4;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});

learn_GT = load( path_GT );    
init_pos = learn_GT.rect_GT(:,1:3,1);    
    

elseif( test_set == 4 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path        = 'result\Crossing\';

%preparing frames    
fprefix         = 'OR_Dataset_GT\TUD-Crossing\Images\';
fext            = 'jpeg';

path_GT         = 'OR_Dataset_GT\TUD-Crossing\gt_boxes.mat';

start_frame     = 0;
nframes         = 68;

sz_T		= [36 45];	%size of the template
numzeros	= 4;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});

learn_GT = load( path_GT );    
init_pos = learn_GT.rect_GT(:,1:3,1);    

elseif( test_set == 5 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path        = 'result\Postech\';

%preparing frames    
fprefix         = 'OR_Dataset_GT\Postech\Images\test8_00_00_';
fext            = 'jpg';

path_GT         = 'OR_Dataset_GT\Postech\gt_boxes.mat';

start_frame     = 33;
nframes         = 115;

sz_T		= [36 45];	%size of the template
numzeros	= 3;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});

learn_GT = load( path_GT );    
init_pos = learn_GT.rect_GT(:,1:3,1);    


elseif( test_set == 6 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path        = 'result\L1Examples\car4\';

%preparing frames    
fprefix         = 'OR_Dataset_GT\L1Examples\car4\car4_';
fext            = 'jpg';

path_GT         = 'OR_Dataset_GT\L1Examples\gt_boxes.mat';

% start_frame     = 130;
% nframes         = 300;

start_frame     = 180;
nframes         = 100;

sz_T		= [36 45];	%size of the template
numzeros	= 3;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});
% 
% learn_GT = load( path_GT );    
% init_pos = learn_GT.rect_GT(:,1:3,1);    
% 

% init_pos	= [	145 255 145;
%                 180 180 333]; %130

init_pos = [    137 233 137
                247 247 380 ]; %180
            
            elseif( test_set == 7 )
    
nT			= 10;		%number of T
n_sample	= 600;		%number of particles

res_path        = 'result\L1Examples\sylv\';

%preparing frames    
fprefix         = 'OR_Dataset_GT\L1Examples\sylv\sylv_';
fext            = 'jpg';

path_GT         = 'OR_Dataset_GT\L1Examples\gt_boxes.mat';

start_frame     = 400;
nframes         = 200;

sz_T		= [36 45];	%size of the template
numzeros	= 3;	%number of digits for the frame index

s_frames	= cell(nframes,1);

nz			= strcat('%0',num2str(numzeros),'d'); %number of zeros in the name of image
for t=1:nframes
    image_no	= start_frame + (t-1);
    fid			= sprintf(nz, image_no);
    s_frames{t}	= strcat(fprefix,fid,'.',fext);
end

%initialization
%	init_pos	- target selected by user (or automatically), it is a 2x3
%		matrix, such that each COLUMN is a point indicating a corner of the target
%		in the first image. Let [p1 p2 p3] be the three points, they are
%		used to determine the affine parameters of the target, as following
% 			  p1(128,116)-------------------p3(120,129)
% 					\						  \
% 					 \			target         \
% 					  \					        \
% 				  p2(150, 136)-------------------\


% %-One can also cropping the initial box through the following code
% init_pos	= SelectTarget(s_frames{1});
% 
% learn_GT = load( path_GT );    
% init_pos = learn_GT.rect_GT(:,1:3,1);    
% 


              
init_pos = [    53 106 53
                120 120 172 ]; %1

init_pos = [    63 106 63
                107 107 150 ]; %400
          
            
end





%% L1 tracking
fcdatapts       = [28 507; 82 721]; %the coordinates of the image on the figure
n_trial = 2;

for it_tri = 1 : n_trial
    tracking_res = L1Tracking_release( mode, s_frames, sz_T, n_sample, init_pos, res_path, fcdatapts, [] );
    s_res = sprintf('%s\\L1_result_%d.mat', res_path, it_tri);
    save(s_res, 'tracking_res');
end

