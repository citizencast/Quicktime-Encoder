//$ cc encoder.m -framework QTKit -framework Foundation -framework AppKit

#import <QTKit/QTKit.h>

int main (int ac, char**av)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  QTMovie *movie = [QTMovie movieWithFile:@"/tmp/sample.mov" error:nil];
  
  // Debug informations: dimensions
  NSLog(@" QTMovieNaturalSizeAttribute %@", NSStringFromSize([[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue]));
  
  // ************** //
  // Encode to FLV  //
  // ************** //
  
  [movie setAttribute:[NSValue valueWithSize:
             NSMakeSize(620, 240)]
         forKey: QTMovieCurrentSizeAttribute];
  
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], QTMovieExport,
                [NSNumber numberWithLong:'FLV1'], QTMovieExportType, nil];
  
  [movie writeToFile:@"/tmp/sample.flv" withAttributes:dictionary];
  
  // ******************** //
  // Export the thumbnail //
  // ******************** //
  
  [movie setAttribute:[NSValue valueWithSize: NSMakeSize(240, 180)]
         forKey: QTMovieCurrentSizeAttribute];
  
  QTTime time = QTTimeFromString(@"00:00:00:10.00/1");
  NSLog(@" Time %@", QTStringFromTime(time));
  
  NSImage *image = [movie frameImageAtTime:time];
  
  NSLog(@" ImageSize %@", NSStringFromSize([image size]));
  
  // Hack to avoid warning. Startup function to call when running Cocoa code
  //  from a Carbon application.
  NSApplicationLoad();
  [[image TIFFRepresentationUsingCompression:NSJPEGFileType factor:80.0]
      writeToFile:@"/tmp/sample.jpg" atomically:YES];

  [pool release];
  
  exit(1);
}