
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


UIImage* _Nullable webpConv(NSData* _Nonnull data){
    WebPData wdata;
    wdata.bytes = data.bytes;
    wdata.size = data.length;
    WebPDemuxer *demux = WebPDemux(&wdata);
    
    WebPIterator iter;
    WebPDemuxGetFrame(demux, 1, &iter);
    WebPDecoderConfig config;
    WebPInitDecoderConfig(&config);

    config.input.width = iter.width;
    config.input.height = iter.height;
    config.input.has_alpha = iter.has_alpha;
    config.input.has_animation = 1;
    config.options.no_fancy_upsampling = 1;
    config.options.bypass_filtering = 1;
    config.options.use_threads = 1;
    config.output.colorspace = MODE_RGBA;

    NSMutableArray<UIImage*> *images = [NSMutableArray array];
    double duration = 0;

    do {
        WebPData frame = iter.fragment;
        int width = iter.width;
        int height = iter.height;
        
        VP8StatusCode status = WebPDecode(frame.bytes, frame.size, &config);
        if (status != VP8_STATUS_OK) { break; }

        uint8_t *ddata = WebPDecodeRGBA(frame.bytes, frame.size, &width, &height);
        CGDataProviderRef provider = CGDataProviderCreateWithData(&config, ddata, width * height * 4, NULL);

        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;

        CGImageRef imageRef = CGImageCreate(width, height, 8, 32, width * 4, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        [images addObject:image];
        duration +=  (double)iter.duration / 1000.0;

        CGImageRelease(imageRef);
        CGColorSpaceRelease(colorSpaceRef);
        CGDataProviderRelease(provider);
    } while (WebPDemuxNextFrame(&iter));

    WebPDemuxDelete(demux);

    if(images.count == 0) { return [UIImage new];}
    if(images.count == 1) { return [images firstObject];}
    if(duration == 0) { duration = (double)images.count * 0.1;}
    return [UIImage animatedImageWithImages:images duration:duration];
}
