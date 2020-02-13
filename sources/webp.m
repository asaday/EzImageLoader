
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)


#if TARGET_OS_TV  
 #import <WebPDecoderTV/decode.h>
#else
 #import <WebPDemux/decode.h>
 #import <WebPDemux/demux.h>
#endif

#import "webp.h"


// original library
// https://developers.google.com/speed/webp/download
// current use 1.0.3

UIImage* _Nullable webpConv(NSData* _Nonnull data){
    WebPData wdata;
    wdata.bytes = data.bytes;
    wdata.size = data.length;
    WebPDemuxer *demux = WebPDemux(&wdata);
    if(demux == NULL) { return nil; }
    
    WebPIterator iter;
    WebPDemuxGetFrame(demux, 1, &iter);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;

    NSMutableArray<UIImage*> *images = [NSMutableArray array];
    NSTimeInterval duration = 0;

    do {
        WebPData frame = iter.fragment;
        int width = iter.width;
        int height = iter.height;
        
        uint8_t *ddata = WebPDecodeRGBA(frame.bytes, frame.size, &width, &height);
        if(ddata == NULL) break;
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, ddata, width * height * 4, NULL);
        CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
        [images addObject:[UIImage imageWithCGImage:imageRef]];
        duration += (NSTimeInterval)iter.duration / 1000.0;

        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
    } while (WebPDemuxNextFrame(&iter));

    CGColorSpaceRelease(colorSpaceRef);
    WebPDemuxDelete(demux);

    if(images.count == 0) { return nil; }
    if(images.count == 1) { return [images firstObject]; }
    if(duration == 0) { duration = (NSTimeInterval)images.count * 0.1; }
    return [UIImage animatedImageWithImages:images duration:duration];
}
