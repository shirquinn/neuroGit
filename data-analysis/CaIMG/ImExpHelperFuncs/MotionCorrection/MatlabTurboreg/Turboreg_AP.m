function Turboreg_AP(targetfilename, sourcefilename, savefilename, channels, imageinfo)
%
% Call ImageJ class and Turboreg class to do motion correction on input
% image data file. Only works with translation of Turboreg. For other
% transformation algorithms, further modification is needed.
%
% squre_flag -- whether to scale the image to sqare before run Turboreg.
%
% Based on TurboregTK by TK.
% 
% NX - May 09
%

% Load reference(tiff), otherwise assume im_t from gui
if ischar(targetfilename)
    im_t(:,:) = imread(targetfilename,'tiff');
else
    im_t = targetfilename;
end

target = im_t;
target_ij = array2ijStackAK(target);


% Load in data to be corrected(tiff), otherwise just assume im_s from gui
% if ischar(sourcefilename)
% [sourcepath, sourcename, sourceext] = fileparts(sourcefilename);
%    n_frame = length(imfinfo(sourcefilename,'tiff'))/channels;
%     for u = 1:channels:n_frame*channels
%         im_s(:,:,ceil(u/channels))=imread(sourcefilename,'tiff',u);
%     end
% else
%     im_s = sourcefilename;
%     n_frame = size(im_s,3);
% end

% Get information about source image
imageinfo=imfinfo(sourcefilename,'tiff');
numframes=length(imageinfo);
M=imageinfo(1).Width;
N=imageinfo(1).Height;

%Do turboreg
h_waitbar = waitbar(0, 'running turboreg ....');
for ii = 1:channels:numframes
    % do one frame at a time, no memory issues this way
    im_s(:,:)=imread(sourcefilename,'tiff',ii);
    
    source = im_s(:,:);
    source_ij=array2ijStackAK(source);

    Cropping= ['0 0 ' num2str(size(target,2)) ' ' num2str(size(target,1))];
    Transformation='-translation';
    center_x = num2str(fix(size(source,2)/2)-1);
    center_y = num2str(fix(size(source,1)/2)-1);
    landmarks = [center_x,' ',center_y,' ',center_x,' ',center_y];
    cmdstr=['-align -window s ',Cropping,' -window t ', Cropping,' ',Transformation, ' ', landmarks,' -hideOutput'];
    
    al=IJAlign_AK;
    registered = al.doAlign(cmdstr, source_ij, target_ij);
    registered = ij2arrayAK(registered);
    a=uint16(round(registered));
    
    % You might get an error here about not being able to write to file
    % because of permissions: SOLUTION IS TO NOT HAVE WINDOWS EXPLORER OPEN
    % SIMULTANEOUSLY (but this windows lock solution might help fix)
    
    if ii == 1,
        for windows_lock = 1:100
            try
                imwrite(a,[savefilename '.tif'],'tif','Compression','none','WriteMode','overwrite', ...
                    'Description', imageinfo(1).ImageDescription);%, 'Description', ImageDescriptio]);
                break;
             catch me
                 pause(0.2);
            end
        end
    else
        for windows_lock = 1:100
            try
                imwrite(a,[savefilename '.tif'],'tif','Compression','none','WriteMode','append', ...
                    'Description', imageinfo(1).ImageDescription);
                break;
             catch me
                 pause(0.2);
            end
        end
        
    end;
    waitbar(ii/(numframes),h_waitbar)
end
close(h_waitbar);
