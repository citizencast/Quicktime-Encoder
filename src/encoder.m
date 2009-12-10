//$ cc -o encoder encoder.m -framework QTKit -framework Foundation -framework AppKit -W

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

NSSize resize_with_aspect_ratio(NSSize current_size, NSSize ideal_size)
{
	float current_width = current_size.width;
	float current_height = current_size.height;
	float adjust_width = 1.0;
	float adjust_height = 1.0;

  if (current_width > 320) {
		adjust_width = 320 / current_width;
  }

  if (current_height > 240) {
		adjust_height = 240 / current_height;
  }

	float adjust = adjust_height < adjust_width ? adjust_height : adjust_width;

	return(NSMakeSize(current_width * adjust, current_height * adjust));
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
  NSSize encoded_movie_dimensions =
    resize_with_aspect_ratio(
      [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue],
      NSMakeSize(320, 240));
  
  NSLog(@"Encoded video dimensions: %@", NSStringFromSize(encoded_movie_dimensions));
  
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
  
  NSData *imageData = [image  TIFFRepresentation];
  NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
  NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
  imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
  [imageData writeToFile:dest_with_jpg_extension atomically:NO];
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
    else
    {
      exit(-1);
    }
  }  
  
  [pool release];
  exit(0);
}