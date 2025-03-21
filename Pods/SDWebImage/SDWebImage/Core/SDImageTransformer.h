/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "UIImage+Transform.h"

/**
 Return the transformed cache key which applied with specify transformerKey.

 @param key The original cache key
 @param transformerKey The transformer key from the transformer
 @return The transformed cache key
 */
FOUNDATION_EXPORT NSString * _Nullable SDTransformedKeyForKey(NSString * _Nullable key, NSString * _Nonnull transformerKey);

/**
 Return the thumbnailed cache key which applied with specify thumbnailSize and preserveAspectRatio control.
 @param key The original cache key
 @param thumbnailPixelSize The thumbnail pixel size
 @param preserveAspectRatio The preserve aspect ratio option
 @return The thumbnailed cache key
 @note If you have both transformer and thumbnail applied for image, call `SDThumbnailedKeyForKey` firstly and then with `SDTransformedKeyForKey`.`
 */
FOUNDATION_EXPORT NSString * _Nullable SDThumbnailedKeyForKey(NSString * _Nullable key, CGSize thumbnailPixelSize, BOOL preserveAspectRatio);

/**
 A transformer protocol to transform the image load from cache or from download.
 You can provide transformer to cache and manager (Through the `transformer` property or context option `SDWebImageContextImageTransformer`).
 From v5.20, the transformer class also can be used on animated image frame post-transform logic, see `SDAnimatedImageView`.
 
 @note The transform process is called from a global queue in order to not to block the main queue.
 */
@protocol SDImageTransformer <NSObject>

@optional

/**
 Defaults to YES if you don't implements this method.
 We keep some metadata like Image Format (`sd_imageFormat`)/ Animated Loop Count (`sd_imageLoopCount`) via associated object on UIImage instance.
 When transformer generate a new UIImage instance, in most cases you still want to keep these information. So this is what for during the image loading pipeline.
 If the value is YES, we will keep and override the metadata **After you generate the UIImage**
 If the value is NO, we will not touch the UIImage metadata and it's controlled by you during the generation. Read `UIImage+Medata.h` and pick the metadata you want for the new generated UIImage.
 */
@property (nonatomic, assign, readonly) BOOL preserveImageMetadata;

@required
/**
 For each transformer, it must contains its cache key to used to store the image cache or query from the cache. This key will be appened after the original cache key generated by URL or from user.
 Which means, the cache should match what your transformer logic do. The same `input image` + `transformer key`, should always generate the same `output image`.

 @return The cache key to appended after the original cache key. Should not be nil.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *transformerKey;

/**
 Transform the image to another image.

 @param image The image to be transformed
 @param key The cache key associated to the image. This arg is a hint for image source, not always useful and should be nullable. In the future we will remove this arg.
 @return The transformed image, or nil if transform failed
 */
- (nullable UIImage *)transformedImageWithImage:(nonnull UIImage *)image forKey:(nonnull NSString *)key API_DEPRECATED("The key arg will be removed in the future. Update your code and don't rely on that.", macos(10.10, API_TO_BE_DEPRECATED), ios(8.0, API_TO_BE_DEPRECATED), tvos(9.0, API_TO_BE_DEPRECATED), watchos(2.0, API_TO_BE_DEPRECATED));

@end

#pragma mark - Pipeline

/**
 Pipeline transformer. Which you can bind multiple transformers together to let the image to be transformed one by one in order and generate the final image.
 @note Because transformers are lightweight, if you want to append or arrange transformers, create another pipeline transformer instead. This class is considered as immutable.
 */
@interface SDImagePipelineTransformer : NSObject<SDImageTransformer>
/// For pipeline transformer, this property is readonly and always return NO. We handle each transformer's choice inside implementation
@property (nonatomic, assign, readonly) BOOL preserveImageMetadata;
/**
 All transformers in pipeline
 */
@property (nonatomic, copy, readonly, nonnull) NSArray<id<SDImageTransformer>> *transformers;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithTransformers:(nonnull NSArray<id<SDImageTransformer>> *)transformers;

@end

#pragma mark - Base
/// This is the base class for our built-in concrete transformers. You should not use this class directlly, use cconcrete subclass (like `SDImageRoundCornerTransformer`) instead.
@interface SDImageBaseTransformer : NSObject<SDImageTransformer>
/// For concrete transformer, this property is readwrite and defaults to YES. You can choose whether to preserve image metadata **After you generate the UIImage**
@property (nonatomic, assign, readwrite) BOOL preserveImageMetadata;
@end

// There are some built-in transformers based on the `UIImage+Transformer` category to provide the common image geometry, image blending and image effect process. Those transform are useful for static image only but you can create your own to support animated image as well.
// Because transformers are lightweight, these class are considered as immutable.
#pragma mark - Image Geometry

/**
 Image round corner transformer
 */
@interface SDImageRoundCornerTransformer: SDImageBaseTransformer

/**
 The radius of each corner oval. Values larger than half the
 rectangle's width or height are clamped appropriately to
 half the width or height.
 */
@property (nonatomic, assign, readonly) CGFloat cornerRadius;

/**
 A bitmask value that identifies the corners that you want
 rounded. You can use this parameter to round only a subset
 of the corners of the rectangle.
 */
@property (nonatomic, assign, readonly) SDRectCorner corners;

/**
 The inset border line width. Values larger than half the rectangle's
 width or height are clamped appropriately to half the width
 or height.
 */
@property (nonatomic, assign, readonly) CGFloat borderWidth;

/**
 The border stroke color. nil means clear color.
 */
@property (nonatomic, strong, readonly, nullable) UIColor *borderColor;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(nullable UIColor *)borderColor;

@end

/**
 Image resizing transformer
 */
@interface SDImageResizingTransformer : SDImageBaseTransformer

/**
 The new size to be resized, values should be positive.
 */
@property (nonatomic, assign, readonly) CGSize size;

/**
 The scale mode for image content.
 */
@property (nonatomic, assign, readonly) SDImageScaleMode scaleMode;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode;

@end

/**
 Image cropping transformer
 */
@interface SDImageCroppingTransformer : SDImageBaseTransformer

/**
 Image's inner rect.
 */
@property (nonatomic, assign, readonly) CGRect rect;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithRect:(CGRect)rect;

@end

/**
 Image flipping transformer
 */
@interface SDImageFlippingTransformer : SDImageBaseTransformer

/**
 YES to flip the image horizontally. ⇋
 */
@property (nonatomic, assign, readonly) BOOL horizontal;

/**
 YES to flip the image vertically. ⥯
 */
@property (nonatomic, assign, readonly) BOOL vertical;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical;

@end

/**
 Image rotation transformer
 */
@interface SDImageRotationTransformer : SDImageBaseTransformer

/**
 Rotated radians in counterclockwise.⟲
 */
@property (nonatomic, assign, readonly) CGFloat angle;

/**
 YES: new image's size is extend to fit all content.
 NO: image's size will not change, content may be clipped.
 */
@property (nonatomic, assign, readonly) BOOL fitSize;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize;

@end

#pragma mark - Image Blending

/**
 Image tint color transformer
 */
@interface SDImageTintTransformer : SDImageBaseTransformer

/**
 The tint color.
 */
@property (nonatomic, strong, readonly, nonnull) UIColor *tintColor;
/// The blend mode, defaults to `sourceIn` if you use the initializer without blend mode
@property (nonatomic, assign, readonly) CGBlendMode blendMode;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithColor:(nonnull UIColor *)tintColor;
+ (nonnull instancetype)transformerWithColor:(nonnull UIColor *)tintColor blendMode:(CGBlendMode)blendMode;

@end

#pragma mark - Image Effect

/**
 Image blur effect transformer
 */
@interface SDImageBlurTransformer : SDImageBaseTransformer

/**
 The radius of the blur in points, 0 means no blur effect.
 */
@property (nonatomic, assign, readonly) CGFloat blurRadius;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithRadius:(CGFloat)blurRadius;

@end

#if SD_UIKIT || SD_MAC
/**
 Core Image filter transformer
 */
@interface SDImageFilterTransformer: SDImageBaseTransformer

/**
 The CIFilter to be applied to the image.
 */
@property (nonatomic, strong, readonly, nonnull) CIFilter *filter;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;

+ (nonnull instancetype)transformerWithFilter:(nonnull CIFilter *)filter;

@end
#endif
