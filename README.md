    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    [window endEditing:YES];
    photoBroswer = [[MmiaPhotoAlbum alloc]initWithArray:imageArray];
    photoBroswer.albumDelegate = self;
    photoBroswer.curIndex = imageView.tag - Tag_Detail_Image;
    photoBroswer.firstIndex = imageView.tag - Tag_Detail_Image;
    CGRect imageInVCFrame = [imageView convertRect:imageView.bounds toView:window];
    photoBroswer.originalFrame = imageInVCFrame;
    [window addSubview:photoBroswer];
    
    [photoBroswer show];
