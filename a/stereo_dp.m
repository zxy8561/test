%% 1.2 Scanline stereo
%%
% 1. Read the included paper4, ?Stereo by intra- and inter-scanline search
% using dynamic programming,? until section 3.2. What are the key points of this
% portion of the paper? With their approach in mind, how could smoothness,
% uniqueness and ordering con- straints be incorporated to improve the quality
% of correspondences? Note: although this paper discusses edge correspondences,
% many of the concepts can be applied to patch correspondences also.
%
% * Answer: Instead of assigning pixel on right picture to each of the pixel
% on the left individually, the paper proposed a way to think about these
% pixels all together, in a more coherent way. So the intra-line step
% will ensure that we consider correspondence matching jointly on each
% scanline (horizontally), and then the inter-line step ensures that we consider
% correspondence matching jointly vertically. In this assignment, we are
% only required to do intra-line step. If we also do inter-line, then our
% result will be more accurate and be free of artifacts (like streaks)? for
% example, if we have a vertical line on the left image, we should also get
% a vertical line on the right image by adopting method proposed in this paper,
% instead of having the line breaken into different segments.
% Using intra-line step, will ensure the uniqueness and ordering constraint
% considered. And using inter-line, we are also incorporating the
% smoothness constrain.
%%
% 2. Implement dynamic programming to solve the patch correspondence problem. 
% They refer to this as the ?intra-scanline search? in the paper.
% * I noted the steps as along the code lays out:
image1 = imread('tsukuba_l.ppm');
image2 = imread('tsukuba_r.ppm');

imshow(image1);
img1 = double(rgb2gray(image1));
img2 = double(rgb2gray(image2));
patch_size = 9;

[rows, columns] = size(img1);
disparity_map = zeros(rows,columns);

%%
% do a loop for each row of image (intra-line)
%%
% define a C_i_j matrix first, which refers to the cost of matching pixel i
% on left image and pixel j on right image, which could be defined as the
% sum of squared difference btw the two patches around them. 
 for row_num = ceil(patch_size/2) : rows-floor(patch_size/2)

    c_i_j = zeros(columns,columns);
    cost = zeros(columns, columns);
    %display(row_num);
    for i = ceil(patch_size/2) : columns-floor(patch_size/2)
        for j = ceil(patch_size/2) : columns-floor(patch_size/2)
        c_i_j(i,j) = patch_diff(img1,img2,row_num,i,j,patch_size);
        end  
    end
    
  
  % initialize the first row & col
    for i = ceil(patch_size/2) : columns-floor(patch_size/2)
        if i == ceil(patch_size/2)
            cost(ceil(patch_size/2), i) = c_i_j(ceil(patch_size/2), i);
        else
            cost(ceil(patch_size/2), i) = c_i_j(ceil(patch_size/2), i) + cost(ceil(patch_size/2), i-1);
        end
    end
    
    for i = ceil(patch_size/2) : columns-floor(patch_size/2)
        if i == patch_size/2
            cost(i, ceil(patch_size/2)) = c_i_j(i, ceil(patch_size/2));
        else
            cost(i, ceil(patch_size/2)) = c_i_j(i, ceil(patch_size/2)) + cost(i-1, ceil(patch_size/2));
        end
    end
    
  
  % and then iteratively calculated all cumulative cost over entire image
    for i = 1+ceil(patch_size/2) : columns-floor(patch_size/2)
        for j = 1+ceil(patch_size/2) : columns-floor(patch_size/2)
            cost(i,j) = min([cost(i-1,j)+c_i_j(i,j), cost(i,j-1)+c_i_j(i,j), cost(i-1,j-1)+c_i_j(i,j)]); 
        end
    end
    
    
    col = columns-floor(patch_size/2);
    row = columns-floor(patch_size/2);
    disparity = 0;
    
  
  % Backtrack to get the optimized path
    while( col > ceil(patch_size/2) && row > ceil(patch_size/2) ) 
       
        disparity_map(row_num, row) = disparity;
        
        mcost = min([cost(row,col-1), cost(row-1,col-1), cost(row-1,col)]);
        
        if mcost == cost(row,col-1)
            disparity = disparity - 1;
            col = col -1;
        end
        
        if mcost == cost(row-1,col)
                disparity = disparity + 1;
                row = row - 1;
        end
        
        if mcost == cost(row-1,col-1)
                col = col - 1;
                row = row - 1;
        end 
        
        
    end     
 end
% Show the disparity map using dp
colormap('jet')

imagesc(disparity_map);
colorbar
pause;

% Fuction for finding sum of squared difference 
function [ diff ] = patch_diff( image1, image2, row1, col1, col2, patchsize )
%COMPUTECOST Summary of this function goes here
%   Detailed explanation goes here
ps = (patchsize -1)/2;
patch1  = image1(row1-ps:row1+ps, col1-ps:col1+ps);
patch2 = image2(row1-ps:row1+ps, col2-ps:col2+ps);


%sum of squared difference
diff = sum(sum((patch1 - patch2).^2));

end

