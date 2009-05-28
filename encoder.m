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
    
  if (error != nil)
  {
    fprintf(stderr, "Unable to open video file\n");
    return ((QTMovie *)-1);
  }
  
  // Debug informations: dimensions
  NSLog(@"Dimensions: %@", 
    NSStringFromSize(
      [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue]
    )
  );
  
  return (movie);
}

NSString *append_path_extension(NSString *path, NSString *ext)
{
  NSString *path_with_extension = nil;
  
  // Remove the extension (if present), then add the new one.
  path_with_extension =
    [[path stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
          
  NSLog(@"Path: %@", path_with_extension);
  
  return (path_with_extension);
}

void encode_movie(QTMovie *movie, char *dest)
{
  [movie setAttribute:[NSValue valueWithSize:
             NSMakeSize(320, 240)]
         forKey: QTMovieCurrentSizeAttribute];
  
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], QTMovieExport,
                [NSNumber numberWithLong:'FLV1'], QTMovieExportType, nil];
  
  NSString *dest_with_flv_extension =
    append_path_extension([NSString stringWithCString:dest], @"flv");
    
  [movie writeToFile:dest_with_flv_extension withAttributes:dictionary];
}

void export_thumbnail(QTMovie *movie, char *dest)
{
  [movie setAttribute:[NSValue valueWithSize: NSMakeSize(240, 180)]
         forKey: QTMovieCurrentSizeAttribute];
  
  QTTime time = QTTimeFromString(@"00:00:00:10.00/1");
  NSLog(@"Thumbnail will be extracted at: %@", QTStringFromTime(time));
  
  NSImage *image = [movie frameImageAtTime:time];
  NSLog(@"Thumbnail size: %@", NSStringFromSize([image size]));
  
  NSString *dest_with_jpg_extension =
    append_path_extension([NSString stringWithCString:dest], @"jpg");
  
  [[image TIFFRepresentationUsingCompression:NSJPEGFileType factor:80.0]
      writeToFile:dest_with_jpg_extension atomically:YES];
}

int main (int ac, char**av)
{  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Hack to avoid warning. Startup function to call when running Cocoa code
  //  from a Carbon application.
  NSApplicationLoad();
 
  char *input;
  char *output; 
  
  // Parse the arguments
  if (parse_arguments(ac, av, &input, &output) != -1)
  {
    // Open the movie
    QTMovie *movie = open_movie(input);
    if ((int)movie != -1)
    {
      // Export movie and thumbnail
      encode_movie(movie, output);
      export_thumbnail(movie, output);
    }  
  }  
  

  [pool release];
  
  exit(1);
}