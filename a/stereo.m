%% 1. Depth from binocular stereo
% 1.1 Solving Correspondence

%echo off
clear all
clf
home
%echo on
%% 
% 
clf
left = imread('tsukuba_l.ppm');
right = imread('tsukuba_r.ppm');

subplot 121, imshow(left);
subplot 122, imshow(right);
pause;

%% Question 1
% * Answer: Choose a patch size and a similarity metric, and provide a rationale for why you chose what you did.
% I would choose sum of squared distances as my similarity metric. And size of 9 as the patch size. If we choose too big a size, then we tend to get inaccurate depth though we tend to have less unidentified case. However, if we choose too small a size, we will run into unidentified cases a lot.
patch_size = 9;




clf
left_double = double(left)/255.0;
right_double = double(right)/255.0;
imshow(left_double);
pause;
p1_loc = [136 83]; 
%% Question 2
%   
% * p1 should have a reliable extremum, because the patch has 
% corners of 2-3 objects on the shelf, no other patch on that horizontal row should have the same feature
p2_loc = [203 304]; 
%%
% * p2 should not have a reliable extremum, because the patch only 
% contained information of being the surface of the front face of the table, and there are many other patches sharing same feature on that row
p3_loc = [182 119];
%% 
% * p3 should have a reliable extremum, because this pixel lies at the the edge of the statue
p4_loc = [186 160];

%% 
% * p4, this one may not have a reliable extremum, but it is not as bad as for pixel 2,
% it has the feature of the nose of the statue, but since the statue is all
% in white, that caused the pixel not standing out that much. In my
% implementation, I did not reject this pixel
p5_loc = [123 224];
%%
% * p5, should have a reliable extremum, because this pixel lies
% at the edge of the red lamp with the black background
p6_loc = [153 338]; 
%% 
% * P6 should have a reliable extremum, because this pixel includes
% the orange steel of the lamp, which is very different with other pixel at
% the same row.

%% Question 3
% * I used three criteria to reject unidentified pixel.
%
% 1. If the pixel found is faraway from targeting pixel, reject. In my
% impelentation, I would reject any disparity smaller than -20 and larger
% than 0. This is because I found the pixels on the lamp usually will have
% a depth of around -15, and it looks like the lamp surface should be at
% the most front of the image, so there should be no depth smaller than
% -20. And there is not drastic difference btw the two camera positions by
% observing the two images, thus, it is safe to say the higher bound is 0.
%
% 2. If a large portion of the calculated value of SSD are close to the
% minimum value, then reject. For example, in the case of pixel 2, we can
% see most of the pixel (~50%) are very close to the minimum value (ssd value within
% distance of 1.5% * (max of sum of squared difference - min of sum of squared difference);
%
% 3. If large number of pixels that are close to the calculated pixel (like within 30 pixels), but
% their values are also close to the minimum value (say if 50 out of these 60 neighboring pixels 
% are having calculated ssd values within distance of 1.5% * (max of sum of squared difference - 
% min of sum of squared difference), then reject.

% define the parameters for tunning our rejection rules
%
percent_num = 0.45;
percent_sim = 0.015;

threshold_dist = 20;

%criter3_thres = 0.015;
criter3_count = 50;

p_locs = [p1_loc;p2_loc;p3_loc;p4_loc;p5_loc;p6_loc];


for k = 1:6
    row = p_locs(k,1);
    col = p_locs(k,2);
    
% patch
    patch_l = left_double(row-ceil(patch_size/2)+1:row+floor(patch_size/2), col-ceil(patch_size/2)+1:(col+floor(patch_size/2)),:);
    %imshow(patch_l);title("Patch around the pixel");
    %pause;
% strip
    strip = right_double(row-ceil(patch_size/2)+1:row+floor(patch_size/2),:,:);
    %imshow(strip);title("Extracted Strip");
    %pause;

    [tot_row, tot_col] = size(left_double(:,:,1));
    pause;

    %length = tot_col - patch_size+1;
    plot_x = ceil(patch_size/2): tot_col-floor(patch_size/2);
    length = size(plot_x,2);
    plot_y = zeros(1, size(plot_x,2));

    
   % define a global minimum to catch the pixel that matches most with
   % target pixel
   global_min = [-1, Inf];
   global_max = -Inf;
    for i = ceil(patch_size/2) : tot_col-floor(patch_size/2)
        %display(i-patch_size/2);
        %display(i+patch_size/2-1);
        other_patch = strip(:, (i-ceil(patch_size/2)+1):(i+floor(patch_size/2)), :);
        value = sum(sum(sum((patch_l - other_patch).^2)));
        plot_y(i-ceil(patch_size/2)+1) = value;
        if (global_min(2) > value) 
            global_min(2) = value;
            global_min(1) = i;
        end
        
        if(global_max <value)
            global_max = value;
        end
    end
    
    reject = false;
    
    if (global_min(1)-col>0 || (global_min(1)-col) < - threshold_dist) 
        % first rejection criteria: if the minimum position found is very
        % far away from pixel on left picture under consideration    
        %display("rejected 1st");

        reject = true;
    else
        %sorted_y = sort(plot_y);
        index = find(plot_y-global_min(2)<percent_sim*global_max);
        count0 = size(index);
        %display(count0);
        % second rejection criteria: 
        if (count0(2)> length*percent_num)
            reject = true;
            %display("rejected 2nd");

        else
            % third rejection criteria: 
            %index_close = find(plot_y-global_min(2)<0.03*global_max);
            count = size(find(index-global_min(1)<30 & -index+global_min(1)<30));
            %display(count);
 
            if count(2) >criter3_count  
                reject = true;
                %display("rejected 3rd");
            end
        end
    end
    
    
    %display(global_min);
    %%
    plot(plot_x-col, plot_y); title("sum of squared difference for pixel nummber: " + k + "; Reject? " + reject);
    pause;
end
%% Question 4
% 4. Repeat this calculation for all left image pixels. Find the point of 
% maximal similarity in each case using your estimation strategy. The position
% of this estimate relative to the position of the left image pixel under consideration 
% is the estimated disparity value, ?est. Accumulate all these disparities (one for each 
% left image pixel) into a matrix and display the matrix as a heatmap. This is the disparity
% map. Be sure to mark the undefined locations clearly in some way.
[tot_row, tot_col] = size(left_double(:,:,1));

disparity_img = zeros(size(left(:,:,1)));
display(size(disparity_img));

global_pair = [Inf, -Inf];


%for row = ceil(patch_size/2)+200  :ceil(patch_size/2) +250
 %   for col = ceil(patch_size/2)+50:ceil(patch_size/2)+100
for row = ceil(patch_size/2) : tot_row - floor(patch_size/2) 
    for col = ceil(patch_size/2) : tot_col - floor(patch_size/2) 
    
% patch
    patch_l = left_double(row-ceil(patch_size/2)+1:row+floor(patch_size/2), col-ceil(patch_size/2)+1:(col+floor(patch_size/2)),:);
    %imshow(patch_l);title("Patch around the pixel");
% strip
    strip = right_double(row-ceil(patch_size/2)+1:row+floor(patch_size/2),:,:);
    %imshow(strip);title("Extracted Strip");

    %[tot_row, tot_col] = size(left_double(:,:,1));

    %length = tot_col - patch_size+1;
    plot_x = ceil(patch_size/2): tot_col-floor(patch_size/2);
    length = size(plot_x,2);
    plot_y = zeros(1, size(plot_x,2));

    
   % define a global minimum to catch the pixel that matches most with
   % target pixel
   global_min = [-1, Inf];
   global_max = -Inf;
    for i = ceil(patch_size/2) : tot_col-floor(patch_size/2)
        %display(i-patch_size/2);
        %display(i+patch_size/2-1);
        other_patch = strip(:, (i-ceil(patch_size/2)+1):(i+floor(patch_size/2)), :);
        value = sum(sum(sum((patch_l - other_patch).^2)));
        plot_y(i-ceil(patch_size/2)+1) = value;
        if (global_min(2) > value) 
            global_min(2) = value;
            global_min(1) = i;
        end
        
        if(global_max <value)
            global_max = value;
        end
    end
    
    reject = false;
    
    if (global_min(1)-col>0 || (global_min(1)-col) < - threshold_dist) 
        % first rejection criteria: if the minimum position found is very
        % far away from pixel on left picture under consideration
        
        reject = true;
        %display("rejected 1st");
        %display(abs(global_min(1)-col));

    else
        index = find(plot_y-global_min(2)<percent_sim*global_max);
        count0 = size(index);
        %display(count0);

        % second rejection criteria: 
        if (count0(2)> length*percent_num)
            reject = true;
            %display("rejected 2nd");


        else
            % third rejection criteria: 

            %index_close = find(plot_y-global_min(2)<0.03*global_max);
            count = size(find(index-global_min(1)<30 & -index+global_min(1)<30));
            %display(count);
            if count(2) >criter3_count  
                reject = true;
                %display("rejected 3rd");
            end
            
        end
    end
    

    if (reject == true)
        disparity_img(row, col) = -tot_col; % meaning the pixel's match is undefined
    else 
        disparity_img(row,col) = global_min(1)-col;
    end
    %display(global_min);
    %plot(plot_x-col, plot_y); title("sum of squared difference for pixel nummber: " + k + "; Reject? " + reject);
    %pause;
    %display([row,col]);
    
    if (global_pair(1) > global_min(1)-col) 
        global_pair(1) = global_min(1)-col;
    end
    if (global_pair(2) < global_min(1)-col) 
        global_pair(2) = global_min(1)-col;
    end
    
    
    end
 
end
%%
% * The following is the heatmap. Please note that the black region refers to
% rejected region. The way I displayed this rejected region is to first
% find the index set (note that in the loop for calculating depth map, I
% assigned value of
% "- total_column number" to a rejected pixel, that is because there can't
% be any depth smaller than that value), and then overlay a scatter point plot plotting that
% set over the disparity map, to make the rejected region standout from any 
% color that is in the range of the colorbar.

%imshow(disparity_img);
%pause;

%clims = [global_pair(1) global_pair(2)];
%clims = [-threshold_dist threshold_dist];
disparity_show = disparity_img(ceil(patch_size/2) : tot_row - floor(patch_size/2), ceil(patch_size/2) : ...
tot_col - floor(patch_size/2));
[row, col] = find(disparity_show<-threshold_dist);
disparity_show1 = disparity_show;
disparity_show1(find(disparity_show<-threshold_dist)) = 0;
colormap('jet')

clims = [min(min(disparity_show1)) max(max(disparity_show1))];
display(clims);

imagesc(disparity_show1,clims)
colorbar
hold on;
plot(col, row, 's','markers',2, 'MarkerEdgeColor','black','MarkerFaceColor','black');
pause;

%% Question 5
%
% 5. To fill in the undefined values, use an interpolation technique. There
% are a variety of possible options, including nearest-neighbor, linear, and 
% cubic3. Choose one, describe how it works in your own words, and use it to 
% estimate the unknown disparities. Provide a rationale for why you chose what 
% you did. Display the resulting disparity map.
%
% * Answer: I will choose nearest neighbor as my method. 
% Nearest neighbor: For a given unidentified pixel, we will look around it
% to find the closest pixel that already has a depth, and then assign that
% depth to this pixel. This applies for non-smooth depth changing. The
% reason I chose this method is: unlike other method (e.g. using
% linear/cubic interpolation, when we were assuming the depth unidentified
% region will have similar depth with its neighbors who already have depth
% identified. This is actually not the case, usually, when we did not
% identified the depth of a region, that usually means it is a background
% behind a object, and the depth of the object and background should be
% drastically different and not smooth, in which case we'd better not use
% linear/cubic.
%
clf
[rows, cols] = size(disparity_show);
[x,y] = meshgrid(1:cols, 1:rows);
index = find(disparity_show >= - threshold_dist);
interpolated_img = griddata(x(index), y(index), disparity_show(index), x, y, 'nearest');
colormap('jet')
imagesc(interpolated_img)
colorbar
pause;
%% Question 6
% 6. The technique described above attempts to find each pixel 
% correspondence indepen- dently. It uses a hard constraint of epipolar geometry 
% and a soft constraint of patch similarity in order to find the correspondence.
% But, in addition, we can also have other soft constraints like smoothness, 
% uniqueness and ordering of correspondences. These constraints help to relate 
% between pixels on the same row (epipolar line). Briefly ex- plain the three
% constraints (smoothness, uniqueness and ordering) and mention the cases when
% they would fail.
%
% * Uniqueness: a given pixel or feature from one image can match no more 
% one pixel or feature from the other image. 
% Failing case: This contraint will fail when there is occlusion, when one
% pixel from left image is occluded from right image
% * Smoothness: This refers to the common observation that most objects are
% smooth on their surfaces almost everywhere over the image. This
% contraints will fail if we are looking at an image with abrupt change in
% depth, for example, in the case when we have some object at the front and
% some at the back.
% * Order constraint: This means usually a pixel a is on the left of b in
% left image, then it should also be the case that a is on the left of b in
% right image. This does not hold true, say, if we are looking at our finger,
% when I put finger before my nose, left eye and right eye oberves that the 
% objects behind the finger will have different order compared to my
% finger.  Another case when it is not true, is when we are having
% transparent surface like glasses and having several marks on it, we might
% get different order by looking at a different angle.


