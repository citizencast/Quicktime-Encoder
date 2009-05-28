//$ cc encoder.m -framework QTKit -framework Foundation -framework AppKit

#import <QTKit/QTKit.h>
#import <stdio.h>

int parse_arguments(int ac, char **av, char **input, char **output)
{
  if (ac != 3)
  {
    fprintf(stderr, "Format: %s 'input' 'output'\n", av[0]);
    return (-1);
  }
  
  *input = av[1];
  *output = av[2];
  
  return (1);
}

QTMovie *open_movie(char *file)
{
  NSError *error = nil;  
  
  QTMovie *movie = [QTMovie movieWithFile:[NSString stringWithCString:file]
    error:&error];
  
  NSLog(@"Error: %x", (int)error);
  
  if (error != nil)
  {
    fprintf(stderr, "Unable to open video file\n");
    return ((QTMovie *)-1);
  }
  
  // Debug informations: dimensions
  NSLog(@" QTMovieNaturalSizeAttribute %@", 
    NSStringFromSize(
      [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue]
    )
  );
  
  return (movie);
}

int main (int ac, char**av)
{  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Hack to avoid warning. Startup function to call when running Cocoa code
  //  from a Carbon application.
  NSApplicationLoad();
 
  char *input;
  char *output; 
  if (parse_arguments(ac, av, &input, &output) == -1)
  {
    return (-1);
  }  
  NSLog(@"Input: %s", input);
  NSLog(@"Output: %s", output);
  
  QTMovie *movie = open_movie(input);
  if ((int)movie == -1)
  {
    return (-1);
  }
  
  // ************** //
  // Encode to FLV  //
  // ************** //
  
  [movie setAttribute:[NSValue valueWithSize:
             NSMakeSize(320, 240)]
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
  

  [[image TIFFRepresentationUsingCompression:NSJPEGFileType factor:80.0]
      writeToFile:@"/tmp/sample.jpg" atomically:YES];

  [pool release];
  
  exit(1);
}