//$ cc mov23gp.m -framework QTKit -framework Foundation

#import <QTKit/QTKit.h>

int main (int ac, char**av)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	QTMovie *movie = [QTMovie movieWithFile:@"/tmp/sample.mov" error:nil];
	
	// Handle the first video track 
	NSArray* trackArray = [movie tracksOfMediaType:QTStringForOSType((OSType)VideoMediaType)];
	if ( ![trackArray count] ) 
	{
		return (-1);
	}
	QTTrack* track = nil;
	track = [trackArray objectAtIndex:0];
	
	// Debug informations: dimensions
	NSLog(@" QTMovieCurrentSizeAttribute %@", NSStringFromSize([[movie attributeForKey:QTMovieCurrentSizeAttribute] sizeValue]));
	NSLog(@" QTMovieNaturalSizeAttribute %@", NSStringFromSize([[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue]));
	NSLog(@" QTTrackBoundsAttribute      %@", NSStringFromRect([[track attributeForKey:QTTrackBoundsAttribute] rectValue]));
	NSLog(@" QTTrackDimensionsAttribute  %@", NSStringFromSize([[track attributeForKey:QTTrackDimensionsAttribute] sizeValue]));
	
	[movie setAttribute:[NSValue valueWithSize:
						 NSMakeSize(620, 240)]
				 forKey: QTMovieCurrentSizeAttribute];
	
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithBool:YES], QTMovieExport,
								[NSNumber numberWithLong:'FLV1'], QTMovieExportType, nil];
	
//	[movie writeToFile:@"/tmp/sample.flv" withAttributes:dictionary];
	
//	dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
//				  [NSNumber numberWithBool:YES], QTMovieExport,
//				  [NSNumber numberWithLong:'PICT'], QTMovieExportType,
//				  @"jpeg", QTAddImageCodecType, nil];
//	
//	[movie writeToFile:@"/tmp/sample.jpg" withAttributes:dictionary];
	
	QTTime time = QTTimeFromString(@"00:00:00:10.00/1");
	NSLog(@" Time %@", QTStringFromTime(time));
	
	NSImage *image = [movie frameImageAtTime:time];
	
	NSLog(@" ImageSize %@", NSStringFromSize([image size]));
	
	[[image TIFFRepresentationUsingCompression:NSJPEGFileType factor:80.0] writeToFile:@"/tmp/sample.jpg" atomically:YES];

	[pool release];
	
	exit(1);
}