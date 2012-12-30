/*
 * iSGL3D: http://isgl3d.com
 *
 * Copyright (c) 2010-2012 Stuart Caunt
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "Isgl3dGLTextureFactory.h"
#import "Isgl3dGLTextureFactoryState.h"
#import "Isgl3dGLTexture.h"
#import "Isgl3dLog.h"
#import "Isgl3dDirector.h"
#import <OpenGLES/EAGL.h>


static Isgl3dGLTextureFactory * _instance = nil;

@interface Isgl3dGLTextureFactory ()
- (id)initSingleton;
- (Isgl3dGLTexture *) createTextureFromCompressedFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY;
- (UIImage *) loadImage:(NSString *)path;
- (void)copyImage:(UIImage *)image toRawData:(void *)data width:(unsigned int)width height:(unsigned int)height flip:(BOOL)flip;
- (BOOL) imageIsHD:(NSString *)path;
- (NSString *) textureKeyForFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY;
- (unsigned int) nearestPowerOf2:(unsigned int)value;
@end



@implementation Isgl3dGLTextureFactory


- (id)init {
	Isgl3dLog(Isgl3dLogLevelError, @"Isgl3dGLTextureFactory::init should not be called on singleton. Instance should be accessed via sharedInstance");
	
	return nil;
}

- (id)initSingleton {
	
	if ((self = [super init])) {
		_textures = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
    
	[_textures release];
    
	if (_state) {
		[_state release];
	}
	
	[super dealloc];
}

+ (Isgl3dGLTextureFactory *) sharedInstance {
	
	@synchronized (self) {
		if (!_instance) {
			_instance = [[Isgl3dGLTextureFactory alloc] initSingleton];
		}
	}
    
	return _instance;
}

+ (void) resetInstance {
	if (_instance) {
		[_instance release];
		_instance = nil;
	}
}

- (void)setState:(Isgl3dGLTextureFactoryState *)state {
    
	if (state != _state) {
		if (_state) {
			[_state release];
			_state = nil;
		}
		
		if (state) {
			_state = [state retain];
		}
	}
}

- (void)clear {
	[_textures removeAllObjects];
}

- (Isgl3dGLTexture *) createTextureFromFile:(NSString *)file {
	return [self createTextureFromFile:file precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
}

- (Isgl3dGLTexture *) createTextureFromFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	return [self createTextureFromFile:file precision:precision repeatX:repeatX repeatY:repeatY mirrorX:NO mirrorY:NO];
}

- (Isgl3dGLTexture *) createTextureFromFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY mirrorX:(BOOL)mirrorX mirrorY:(BOOL)mirrorY {
    return [self createTextureFromFile:file precision:precision repeatX:repeatX repeatY:repeatY mirrorX:mirrorX mirrorY:mirrorY flip:NO];
}

- (Isgl3dGLTexture *) createTextureFromFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY mirrorX:(BOOL)mirrorX mirrorY:(BOOL)mirrorY flip:(BOOL)flip {
	NSString * extension = [file pathExtension];
	if ([extension isEqualToString:@"pvr"]) {
		return [self createTextureFromCompressedFile:file precision:precision repeatX:repeatX repeatY:repeatY];
	}
	
	if (_state) {
		NSString * textureKey = [self textureKeyForFile:file precision:precision repeatX:repeatX repeatY:repeatY];
		Isgl3dGLTexture * texture = [_textures objectForKey:textureKey];
		if (texture) {
			return texture;
		}
        
		
		UIImage * image = [self loadImage:file];
		if (!image) {
			Isgl3dDebugLog(Isgl3dLogLevelError, @"image %@ cannot be loaded", file);
			return nil;
		}
		
		// Get nearest power of 2 dimensions
		unsigned int width = [self nearestPowerOf2:CGImageGetWidth(image.CGImage)];
		unsigned int height = [self nearestPowerOf2:CGImageGetHeight(image.CGImage)];
        
		void * data = malloc(width * height * 4);
		[self copyImage:image toRawData:data width:width height:height flip:flip];
		unsigned int textureId = [_state createTextureFromRawData:data width:width height:height mipmap:YES precision:precision repeatX:repeatX repeatY:repeatY mirrorX:mirrorX mirrorY:mirrorY];
		free(data);
		
		// Create texture and store in dictionary
		CGSize contentSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
		texture = [Isgl3dGLTexture textureWithId:textureId width:width height:height contentSize:contentSize];
		
		BOOL isHD = [self imageIsHD:file];
		texture.isHighDefinition = isHD;
		
		[_textures setObject:texture forKey:textureKey];
		
		return texture;
	}
    
	Isgl3dDebugLog(Isgl3dLogLevelError, @"createTextureFromFile: not initialised with factory state");
	return nil;
}

- (Isgl3dGLTexture *) createTextureFromUIImage:(UIImage *)image key:(NSString *)key {
	return [self createTextureFromUIImage:image key:key precision:Isgl3dTexturePrecisionMedium repeatX:NO repeatY:NO];
}

- (Isgl3dGLTexture *) createTextureFromUIImage:(UIImage *)image key:(NSString *)key  precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	return [self createTextureFromUIImage:image key:key precision:precision repeatX:repeatX repeatY:repeatY mirrorX:NO mirrorY:NO];
}

- (Isgl3dGLTexture *) createTextureFromUIImage:(UIImage *)image key:(NSString *)key  precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY mirrorX:(BOOL)mirrorX mirrorY:(BOOL)mirrorY {
    return [self createTextureFromUIImage:image key:key precision:precision repeatX:repeatX repeatY:repeatY mirrorX:mirrorX mirrorY:mirrorY flip:NO];
}

- (Isgl3dGLTexture *) createTextureFromUIImage:(UIImage *)image key:(NSString *)key  precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY mirrorX:(BOOL)mirrorX mirrorY:(BOOL)mirrorY flip:(BOOL)flip {
	
	if (_state) {
		NSString * textureKey = [self textureKeyForFile:key precision:precision repeatX:repeatX repeatY:repeatY];
		Isgl3dGLTexture * texture = [_textures objectForKey:textureKey];
		if (texture) {
			return texture;
		}
        
		// Get nearest power of 2 dimensions
		unsigned int width = [self nearestPowerOf2:CGImageGetWidth(image.CGImage)];
		unsigned int height = [self nearestPowerOf2:CGImageGetHeight(image.CGImage)];
        
		void * data = malloc(width * height * 4);
		[self copyImage:image toRawData:data width:width height:height flip:flip];
		unsigned int textureId = [_state createTextureFromRawData:data width:width height:height mipmap:YES precision:precision repeatX:repeatX repeatY:repeatY mirrorX:mirrorX mirrorY:mirrorY];
		free(data);
		
		// Create texture and store in dictionary
		CGSize contentSize = CGSizeMake(CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
		texture = [Isgl3dGLTexture textureWithId:textureId width:width height:height contentSize:contentSize];
		
		texture.isHighDefinition = NO;
		
		[_textures setObject:texture forKey:textureKey];
		
		return texture;
	}
    
	Isgl3dDebugLog(Isgl3dLogLevelError, @"createTextureFromUIImage: not initialised with factory state");
	return nil;
}

- (Isgl3dGLTexture *) createTextureFromText:(NSString *)text fontName:(NSString*)name fontSize:(CGFloat)size repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	if (_state) {
		if ([text length] == 0) {
			return nil;
		}
		
		
		CGSize dimensions = [text sizeWithFont:[UIFont fontWithName:name size:size]];
		CGSize contentSize = CGSizeMake(dimensions.width, dimensions.height);
		
		UITextAlignment alignment = UITextAlignmentCenter;
		
		unsigned int width = [self nearestPowerOf2:dimensions.width];
		unsigned int height = [self nearestPowerOf2:dimensions.height];
		
		void * data = malloc(width * height * 4);
		memset(data, 0, (int)(width * height * 4));
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		CGColorSpaceRelease(colorSpace);
        
		CGContextTranslateCTM(context, 0.0f, height);
		CGContextScaleCTM(context, 1.0f, -1.0f);
		UIGraphicsPushContext(context);
        //		CGContextSetGrayFillColor(context, 0.5f, 1.0f);
        //		CGContextFillRect(context, CGRectMake (0.0, 0.0, dimensions.width, dimensions.height));
		CGContextSetGrayFillColor(context, 1.0f, 1.0f);
        
		UIFont * uiFont = [UIFont fontWithName:name size:size];
	    [text drawInRect:CGRectMake(0, 0, dimensions.width, dimensions.height) withFont:uiFont lineBreakMode:UILineBreakModeWordWrap alignment:alignment];
		
		if (!uiFont) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Font '%@' not found", name);
		}
		UIGraphicsPopContext();
		
		unsigned int textureId = [_state createTextureFromRawData:data width:width height:height mipmap:YES precision:Isgl3dTexturePrecisionMedium repeatX:repeatX repeatY:repeatY mirrorX:NO mirrorY:NO];
		
		CGContextRelease(context);
		free(data);
        
		return [Isgl3dGLTexture textureWithId:textureId width:width height:height contentSize:contentSize];
        
	}
    
	Isgl3dDebugLog(Isgl3dLogLevelError, @"createTextureFromText: not initialized with factory state");
	return nil;
}

- (Isgl3dGLTexture *) createTextureFromText:(NSString *)text fontName:(NSString*)name fontSize:(CGFloat)size {
	return [self createTextureFromText:text fontName:name fontSize:size repeatX:NO repeatY:NO];
}


- (Isgl3dGLTexture *) createTextureFromCompressedFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	if (_state) {
		NSString * textureKey = [self textureKeyForFile:file precision:precision repeatX:repeatX repeatY:repeatY];
		Isgl3dGLTexture * texture = [_textures objectForKey:textureKey];
		if (texture) {
			return texture;
		}
        
		// cut filename into name and extension
		NSString * extension = [file pathExtension];
		NSString * origFileName = [file stringByDeletingPathExtension];
        
		NSString * fileName = origFileName;
		if ([Isgl3dDirector sharedInstance].retinaDisplayEnabled) {
			fileName = [origFileName stringByAppendingString:@"-hd"];
		}
        
        
		NSString * filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
		
		BOOL isHD = [Isgl3dDirector sharedInstance].retinaDisplayEnabled;
		if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Compressed image file not found %@.%@", fileName, extension);
            
			if ([Isgl3dDirector sharedInstance].retinaDisplayEnabled) {
				fileName = origFileName;
				filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
                
				Isgl3dClassDebugLog(Isgl3dLogLevelInfo, @"Trying %@...", file);
                
				isHD = NO;
				if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
					Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Compressed image file not found %@.%@", fileName, extension);
					return nil;
				}
				
			} else {
				return nil;
			}
		}
		
		unsigned int width=0, height=0;
		unsigned int textureId = [_state createTextureFromPVR:filePath outWidth:&width outHeight:&height];
        
		texture = [Isgl3dGLTexture textureWithId:textureId width:width height:height];
		texture.isHighDefinition = isHD;
		
		[_textures setObject:texture forKey:textureKey];
        
		return texture;
	} else {
		Isgl3dDebugLog(Isgl3dLogLevelError, @"createTextureFromCompressedFile: not initialized with factory state");
	}
    
	return nil;
}

- (Isgl3dGLTexture *) createCubemapTextureFromFiles:(NSArray *)files precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	return [self createCubemapTextureFromFiles:files precision:precision repeatX:repeatX repeatY:repeatY mirrorX:NO mirrorY:NO];
}


- (Isgl3dGLTexture *) createCubemapTextureFromFiles:(NSArray *)files precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY mirrorX:(BOOL)mirrorX mirrorY:(BOOL)mirrorY {
    
	if (_state) {
		NSMutableArray * images = [[NSMutableArray alloc] init];
        
		BOOL compressed = NO;
        
		for (NSString * file in files) {
			[images addObject:[self loadImage:file]];
            
			NSString * extension = [file pathExtension];
			if ([extension isEqualToString:@"pvr"]) {
				compressed = YES;
			}
		}
        
		if (compressed) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Cubemaps using compressed images is not yet available");
			[images release];
			return nil;
		}
        
        
		if ([images count] != 6) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Generation of cubmap texture requires 6 images: only %i given", [images count]);
			[images release];
			return nil;
		}
        
		UIImage * posXImage = [images objectAtIndex:0];
		UIImage * negXImage = [images objectAtIndex:1];
		UIImage * posYImage = [images objectAtIndex:2];
		UIImage * negYImage = [images objectAtIndex:3];
		UIImage * posZImage = [images objectAtIndex:4];
		UIImage * negZImage = [images objectAtIndex:5];
        
		unsigned int imageWidth = CGImageGetWidth(posXImage.CGImage);
		unsigned int imageHeight = CGImageGetHeight(posXImage.CGImage);
		// Get nearest power of 2 dimensions
		unsigned int width = [self nearestPowerOf2:imageWidth];
		unsigned int height = [self nearestPowerOf2:imageHeight];
		
		if (imageHeight != imageWidth) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Generation of cubmap texture requires images of equal width and height");
			[images release];
			return nil;
		}
		
		if (CGImageGetWidth(negXImage.CGImage) != imageWidth ||
			CGImageGetHeight(negXImage.CGImage) != imageWidth ||
			CGImageGetWidth(posYImage.CGImage) != imageWidth ||
			CGImageGetHeight(posYImage.CGImage) != imageWidth ||
			CGImageGetWidth(negYImage.CGImage) != imageWidth ||
			CGImageGetHeight(negYImage.CGImage) != imageWidth ||
			CGImageGetWidth(posZImage.CGImage) != imageWidth ||
			CGImageGetHeight(posZImage.CGImage) != imageWidth ||
			CGImageGetWidth(negZImage.CGImage) != imageWidth ||
			CGImageGetHeight(negZImage.CGImage) != imageWidth) {
			Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Generation of cubmap texture requires all images to be the same size");
			[images release];
			return nil;
		}
		
		
		unsigned int stride = width * height * 4;
		void * data = malloc(stride * 6);
		unsigned int offset = 0;
        
		[self copyImage:posXImage toRawData:data + offset width:width height:height flip:NO];
		offset += stride;
		[self copyImage:negXImage toRawData:data + offset width:width height:height flip:NO];
		offset += stride;
		[self copyImage:posYImage toRawData:data + offset width:width height:height flip:NO];
		offset += stride;
		[self copyImage:negYImage toRawData:data + offset width:width height:height flip:NO];
		offset += stride;
		[self copyImage:posZImage toRawData:data + offset width:width height:height flip:NO];
            offset += stride;
		[self copyImage:negZImage toRawData:data + offset width:width height:height flip:NO];
        
		unsigned int textureId = [_state createCubemapTextureFromRawData:data width:width mipmap:YES precision:precision repeatX:repeatX repeatY:repeatY mirrorX:mirrorX mirrorY:mirrorY];
		
		free(data);
		[images release];
		
		return [Isgl3dGLTexture textureWithId:textureId type:GL_TEXTURE_CUBE_MAP width:width height:height contentSize:CGSizeMake(width, height)];
	}
    
	Isgl3dDebugLog(Isgl3dLogLevelError, @"createCubemapTextureFromFiles: not initialised with factory state");
	return nil;
}

- (Isgl3dGLDepthRenderTexture *) createDepthRenderTexture:(int)width height:(int)height {
	if (_state) {
		return [_state createDepthRenderTexture:width height:height];
	}
    
	Isgl3dDebugLog(Isgl3dLogLevelError, @"createDepthRenderTexture: not initialised with factory state");
	return nil;
}



- (void)deleteTexture:(Isgl3dGLTexture *)texture {
	if (_state) {
		[_state deleteTextureId:texture.textureId];
		
		NSString * textureKey = nil;
		for (NSString * key in _textures) {
            Isgl3dGLTexture * storedTexture = [_textures objectForKey:key];
            if (storedTexture.textureId == texture.textureId) {
			 	textureKey = key;
			 	break;
            }
		}
		
		if (textureKey) {
			[_textures removeObjectForKey:textureKey];
		}
		
	} else {
		Isgl3dDebugLog(Isgl3dLogLevelError, @"deleteTexture: not initialized with factory state");
	}
}


- (UIImage *) loadImage:(NSString *)path {
    NSString *filePath = path;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        // cut filename into name and extension
        NSString * extension = [path pathExtension];
        NSString * origFileName = [path stringByDeletingPathExtension];
        
        NSString * fileName = origFileName;

        if ([Isgl3dDirector sharedInstance].retinaDisplayEnabled) {
            fileName = [origFileName stringByAppendingString:@"-hd"];
        }
        
        filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
        if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            Isgl3dClassDebugLog(Isgl3dLogLevelError, @"image file not found %@.%@", fileName, extension);
            if ([Isgl3dDirector sharedInstance].retinaDisplayEnabled) {
                fileName = origFileName;
                filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
                
                Isgl3dClassDebugLog(Isgl3dLogLevelInfo, @"Trying %@...", path);
                
                if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Image file not found %@.%@", fileName, extension);
                    return nil;
                }
                
            } else {
                return nil;
            }
            
        }
        
        
        filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
        if (!filePath) {
            Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Failed to load %@.%@", fileName, extension);
            return nil;
        }
    }
    
	NSData *texData = [[NSData alloc] initWithContentsOfFile:filePath];
    UIImage *image = [[UIImage alloc] initWithData:texData];
   	[texData release];
    
	if (image == nil) {
		Isgl3dClassDebugLog(Isgl3dLogLevelError, @"Failed to load %@", filePath);
	}
    return [image autorelease];
    
}

- (BOOL) imageIsHD:(NSString *)path {
	// cut filename into name and extension
	NSString * extension = [path pathExtension];
	NSString * origFileName = [path stringByDeletingPathExtension];
	
	if ([Isgl3dDirector sharedInstance].retinaDisplayEnabled) {
		NSString *fileName = [origFileName stringByAppendingString:@"-hd"];
		NSString * filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
		
		if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
			
			return YES;
		}
        
	}
	return NO;
}

- (void)copyImage:(UIImage *)image toRawData:(void *)data width:(unsigned int)width height:(unsigned int)height flip:(BOOL)flip {
	unsigned int imageWidth = CGImageGetWidth(image.CGImage);
	unsigned int imageHeight = CGImageGetHeight(image.CGImage);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
	CGContextRef context = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	CGContextClearRect(context, CGRectMake(0, 0, width, height));
    if (flip) {
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -(int)imageHeight);
    } else {
        CGContextTranslateCTM(context, 0, height - imageHeight);
    }
	CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
	CGContextRelease(context);
}


- (NSString *) textureKeyForFile:(NSString *)file precision:(Isgl3dTexturePrecision)precision repeatX:(BOOL)repeatX repeatY:(BOOL)repeatY {
	return [NSString stringWithFormat:@"%@%i%i%i", file, precision, repeatX, repeatY];
}

- (unsigned int) nearestPowerOf2:(unsigned int)value {
	unsigned int i;
	unsigned int po2Value = value;
	if ((po2Value != 1) && (po2Value & (po2Value - 1))) {
		i = 1;
		while (i < po2Value) {
			i *= 2;
		}
		po2Value = i;
	}
	return po2Value;
}


@end
