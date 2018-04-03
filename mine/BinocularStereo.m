clear all
clf
home

tl = double(imread('tsukuba_l.ppm'));
tr = double(imread('tsukuba_r.ppm'));
patch_size = 9;
points = [136 83; 203 304; 182 119; 186 160; 123 224; 153 338];
rows = size(tl, 1);
cols = size(tl, 2);

for p = 1:6
    row = points(p, 1);
    col = points(p, 2);
    left = tl(row-(patch_size-1)/2:row+(patch_size-1)/2, col-(patch_size-1)/2:col+(patch_size-1)/2, :);
    min = Inf;
    max = -Inf;
    cor_col = 0;
    x_axis = (patch_size+1)/2 : cols-(patch_size-1)/2; % column range
    y_axis = zeros(1,size(x_axis,2));
    
    for c = x_axis(1,:)
        right = tr(row-(patch_size-1)/2:row+(patch_size-1)/2, c-(patch_size-1)/2:c+(patch_size-1)/2,:);
        diff = sum(sum(sum((right - left).^2))); % sum of squared difference
        y_axis(c-(patch_size-1)/2) = diff;
        
        if(min>diff)
            cor_col=c;
            min=diff;
        end
        if(max<diff)
            max=diff;
        end
        
    end
    
    a = plot(x_axis-col, y_axis);
    title("p"+p+": delta along "+row+"th row");%(delta, sum of squared difference)
    %saveas(a,'p6.jpg');
    pause;
    
    % 1st REJECTION
    if(cor_col-col>0 || cor_col-col < -18) % delta district threshold = (-18,0)
        disp("district rejection: p"+p);
    end
    % 2nd REJECTION
    num = size(find(y_axis-min<0.01*max),2); % similarity percentage threshold=(0,0.05)
    disp(num/cols);
    if(num/cols>0.07) % reliable threshold
        disp("not reliable patch: p"+p);
    end
    
end

disparity = zeros(size(tl(:,:,1)));

for row = (patch_size+1)/2 : rows-(patch_size-1)/2
    for col = (patch_size+1)/2 : cols-(patch_size-1)/2
        left = tl(row-(patch_size-1)/2:row+(patch_size-1)/2, col-(patch_size-1)/2:col+(patch_size-1)/2,:);
        min = Inf;
        max = -Inf;
        cor_col = 0;
        x_axis = (patch_size+1)/2 : cols-(patch_size+1)/2; % column range
        y_axis = zeros(1,size(x_axis,2));

        for c = x_axis(1,:)
            right = tr(row-(patch_size-1)/2:row+(patch_size-1)/2, c-(patch_size-1)/2:c+(patch_size-1)/2,:);
            diff = sum(sum(sum((right - left).^2))); % sum of squared difference
            y_axis(c-(patch_size-1)/2) = diff;

            if(min>diff)
                cor_col=c;
                min=diff;
            end
            if(max<diff)
                max=diff;
            end

        end

        flag = false;
        % 1st REJECTION
        if(cor_col-col>0 || cor_col-col < -18) % delta district threshold = (-18,0)
            %disp("district rejection: p"+p);
            flag = true;
        end
        % 2nd REJECTION
        num = size(find(y_axis-min<0.01*max),2); % similarity percentage threshold=(0,0.05)
        disp(num/cols);
        if(num/cols>0.07) % reliable threshold
            %disp("not reliable patch: p"+p);
            flag = true;
        end
        
        if(flag == true)
            disparity(row, col) = -cols;
        else
            disparity(row, col) = cor_col - col;
        end   
            
    end
end

dis = disparity((patch_size+1)/2 : rows-(patch_size-1)/2,(patch_size+1)/2 : cols-(patch_size-1)/2);
temp = dis;
temp(find(dis<-18)) = 0;
[row, col] = find(temp==0);
colormap('jet');

range = [min(min(temp)), max(max(temp))];
imagesc(temp, range);
colorbar
hold on

plot(col, row, 's', 'markers', 2, 'MarkerEdgeColor','black','MarkerFaceColor','black');
pause;
%%

[rows, cols] = size(dis);
[x_axis, y_axis] = meshgrid(1:cols, 1:rows);
res = find(dis>=-18);
inter = griddata(x_axis(res),y_axis(res),dis(res), x_axis, y_axis,'nearest');
imagesc(inter, [-18,18]);













