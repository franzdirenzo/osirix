/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/


#import "MSRGWindowController.h"

@implementation MSRGWindowController
- (id) initWithMarkerViewer:(ViewerController*) v andViewersList:(NSMutableArray*)list 
{
	NSLog(@"int MSRGWindowController !");
	self = [super initWithWindowNibName:@"MSRGPanel"];
	viewer = v;
	BoundingROIStart=0L;
	BoundingROIEnd=0L;
	/*
	 msrgSeg=[[MSRGSegmentation alloc] initWithViewerList:viewersList currentViewer:self];
	 [msrgSeg startMSRGSegmentation];
	 */
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver: self
           selector: @selector(CloseViewerNotification:)
               name: @"CloseViewerNotification"
             object: nil];
			 
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiChange"
             object: nil];
	[nc addObserver: self
           selector: @selector(roiRemoved:)
               name: @"removeROI"
             object: nil];
	
	return self;
}

- (IBAction)startMSRG:(id)sender
{
	
}

// if bounding box is activated check if there is always a rectangle ROI with name Bounding box
- (void) roiChange: (NSNotification*) note
{
	if ([ActivateBoundingBoxButton state]==NSOnState)
	{
		if ([[RadioMatrix selectedCell] tag]==0)
		{
			BOOL res=[self checkBoundingBoxROIPresentOnCurrentSlice];
		}
		else
		{
			BOOL res=[self checkBoundingBoxROIPresentOnStack];
		}
	}
}

- (void) roiRemoved: (NSNotification*) note
{
	if ([ActivateBoundingBoxButton state]==NSOnState)
	{
		if ([[RadioMatrix selectedCell] tag]==0)
		{
			if ( [note object]==BoundingROIStart)
			{
				NSRunAlertPanel( NSLocalizedString( @"Bounding Box Removed", 0L), NSLocalizedString( @"You've just removed your bounding box !", 0), nil, nil, nil);
				[ActivateBoundingBoxButton setState:NSOffState];
			}
		} else
		{
			if (( [note object]==BoundingROIStart) || ( [note object]==BoundingROIEnd))
			{
				NSRunAlertPanel( NSLocalizedString( @"Bounding Volume Removed", 0L), NSLocalizedString( @"You've just removed your bounding Volume !", 0), nil, nil, nil);
				[ActivateBoundingBoxButton setState:NSOffState];
			}
			
		}
	}
}
-(BOOL)checkBoundingBoxROIPresentOnStack
{
	int nbImages=[[viewer pixList] count];
	int i,j,begin,end;
	NSMutableArray	*curRoiList;
	BOOL isBoundingBox=NO;
	for(i=0;i<nbImages;i++)
	{
		curRoiList= [[viewer roiList] objectAtIndex: i];
		for( j = 0; j < [curRoiList count]; j++)
		{
			ROI* currentROI=[curRoiList objectAtIndex:j];
			if( ([[currentROI name] isEqualToString:@"Bounding Box"]) && ([currentROI type]==tROI))
			{
				if(!isBoundingBox) //first time we find a ROI Bounding Box
				{
					begin=i;
					BoundingROIStart=currentROI;
				}
				end=i;
				BoundingROIEnd=currentROI;
				isBoundingBox=YES;
				NSRect rect=[currentROI rect];
				NSPoint origin=rect.origin;
				NSSize size=rect.size;
				[startEndText setStringValue:[NSString stringWithFormat:@"From slice: %d to %d",begin,end]];
			}
		}
	}
	if (!isBoundingBox)		
	{
		[ActivateBoundingBoxButton setState:NSOffState];
		NSRunAlertPanel( NSLocalizedString( @"NO Bounding Volume", 0L), NSLocalizedString( @"Sorry, but there is no ROI with name: Bounding Box on the current slice", 0), nil, nil, nil);
		
	}
	if ((isBoundingBox) && (BoundingROIStart==BoundingROIEnd))	
	{
		[ActivateBoundingBoxButton setState:NSOffState];
		NSRunAlertPanel( NSLocalizedString( @"No bounding Volume", 0L), NSLocalizedString( @"Sorry, but there is just one ROI with name: Bounding Box on the stack", 0), nil, nil, nil);
		
	}
	return isBoundingBox;
}
-(BOOL)checkBoundingBoxROIPresentOnCurrentSlice
{	
	NSLog(@"2D");
	int i;
	// Check if there is a ROI which name is BoundingBox
	NSMutableArray	*curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
	BOOL isBoundingBox=NO;
	for( i = 0; i < [curRoiList count]; i++)
	{
		ROI* currentROI=[curRoiList objectAtIndex:i];
		if( ([[currentROI name] isEqualToString:@"Bounding Box"]) && ([currentROI type]==tROI))
		{
			isBoundingBox=YES;
			BoundingROIStart=currentROI;
			NSRect rect=[currentROI rect];
			NSPoint origin=rect.origin;
			NSSize size=rect.size;
			[startEndText setStringValue:[NSString stringWithFormat:@"Slice number:%d",i]];
			NSLog([NSString stringWithFormat:@"Slice number:%d, (x=%d,y=%d,width=%d,height=%d)",i,(int)origin.x,(int)origin.y,(int)size.width,(int)size.height]);
		}
	}
	if (!isBoundingBox)		
	{
		[ActivateBoundingBoxButton setState:NSOffState];
		NSRunAlertPanel( NSLocalizedString( @"NO Bounding Box", 0L), NSLocalizedString( @"Sorry, but there is no ROI with name: Bounding Box on the current slice", 0), nil, nil, nil);
		
	}
	return isBoundingBox;
}

- (IBAction)activateBoundingBox:(id)sender
{
	if ([ActivateBoundingBoxButton state]==NSOnState)
	{
		// 2D
		if ([[RadioMatrix selectedCell] tag]==0)
		{
			BOOL res=[self checkBoundingBoxROIPresentOnCurrentSlice];
		}
		else
		{
			BOOL res=[self checkBoundingBoxROIPresentOnStack];
		}
	}
	
}
-(void) CloseViewerNotification:(NSNotification*) note
{	
	if( [note object] == viewer)
	{
		[self close];
	}
}


- (IBAction)CreateDeleteMarkers:(id)sender
{
	// retrieve image dim
	int nbImages=[[viewer pixList] count];
	DCMPix	*curPix = [[viewer pixList] objectAtIndex: [[viewer imageView] curImage]];
	int height=[curPix pheight];
	int width=[curPix pwidth];
	
	NSMutableArray	*curRoiList;
	/*
	 * Create MARKER FRAME Activated so, create one excep if one already exist
	 */
	if ([AddMarkerFrameButton state]==NSOnState)
	{
		int i,j;
		BOOL cleanStack=NO;
		// Create a frameROI based on the bounding box if one ...
		
		// I-  first find if a "FrameMarker" ROI already exist ?
		
		
		// if yes do noting else create one ...
		// There are many cases to test if we are in 3D with bounding box ...
		
		BOOL createOne=YES;
		if ([[RadioMatrix selectedCell] tag]==0)
		{
			// 2D
			curRoiList = [[viewer roiList] objectAtIndex: [[viewer imageView] curImage]];
			for( i = 0; i < [curRoiList count]; i++)
			{
				ROI* currentROI=[curRoiList objectAtIndex:i];
				if ([[currentROI name] isEqualToString:@"FrameMarker"])
					createOne=NO;
			}
			
		}
		else
		{
			//3D
			
			// check if we are in a bounding box mode ...
			if ([ActivateBoundingBoxButton state]==NSOnState)
			{
				// retrieve all rois at BoundingROIStart position ...
				curRoiList = [[viewer roiList] objectAtIndex:[[BoundingROIStart curView] curImage]];
				for( i = 0; i < [curRoiList count]; i++)
				{
					ROI* currentROI=[curRoiList objectAtIndex:i];
					if ([[currentROI name] isEqualToString:@"FrameMarker"])
						createOne=NO;
				}
				// if we find a FrameMarker at the first Bounding Box, we have to check at the second bounding box ...
				if (!createOne)
				{
					BOOL secondROI=NO;
					curRoiList = [[viewer roiList] objectAtIndex:[[BoundingROIEnd curView] curImage]];
					for( i = 0; i < [curRoiList count]; i++)
					{
						ROI* currentROI=[curRoiList objectAtIndex:i];
						if ([[currentROI name] isEqualToString:@"FrameMarker"])
							secondROI=YES;
					}
					// there is no FrameMarker at the end position of the bounding Box !!
					// In such case, we clean all FrameMarkers to create a clean stack
					if (!secondROI)
					{
						cleanStack=YES;
					}
				}
				
			} else
			{
				// We are not in the bounding box state, so just check FrameMarker from begin to end	
				for(i=0;i<nbImages;i++)
				{
					curRoiList= [[viewer roiList] objectAtIndex: i];
					for( j = 0; j < [curRoiList count]; j++)
					{
						ROI* currentROI=[curRoiList objectAtIndex:j];
						if( !(([[currentROI name] isEqualToString:@"Bounding Box"]) && ([currentROI type]==tROI)))
							cleanStack=YES;
					}
				}
			}
		}
		
		// 1.5 if cleanStack means there are some dirty things so clean the stack from previous FrameMarker
		if (cleanStack)
		{
			[self cleanStackFromMarkerFrame];	
		}
		
		//2- if there is no FrameMarker create one 
		if (createOne)
		{
			//2D
			if ([[RadioMatrix selectedCell] tag]==0)
			{
				// bounding box activated ?
				if ([ActivateBoundingBoxButton state]==NSOnState)
				{
					// create a marker Image with bounding box size
					NSRect rect=[BoundingROIStart rect];
					NSPoint origin=rect.origin;
					NSSize size=rect.size;
					int widthBounding=(int)size.width;
					int heightBounding=(int)size.height;
					int startBoundingX=(int)origin.x;
					int startBoundingY=(int)origin.y;
					[self createMarkerROIWithWidth:widthBounding andHeight:heightBounding atPosX:startBoundingX andY:startBoundingY];					
				}
				else
				{
					// no bounding box so create a maker image with image size
					[self createMarkerROIWithWidth:width andHeight:height atPosX:0 andY:0];
				}
			}
			else //3D
			{
				if ([ActivateBoundingBoxButton state]==NSOnState)
				{
					
					// create a 3D marker image with bounding box size
				} else {
					// create a 3D marker image with stack size
				}
				
			}
			
		}
	} else
	{
		[self cleanStackFromMarkerFrame];
		
	}
}
-(void) cleanStackFromMarkerFrame
{
	int i,j;
	NSMutableArray	*curRoiList;
	int nbImages=[[viewer pixList] count];
	for(i=0;i<nbImages;i++)
	{
		curRoiList= [[viewer roiList] objectAtIndex: i];
		for( j = 0; j < [curRoiList count]; j++)
		{
			ROI* currentROI=[curRoiList objectAtIndex:j];
			if ([[currentROI name] isEqualToString:@"FrameMarker"])
			{
				[curRoiList removeObjectAtIndex:j];
			}
		} 
	}
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateView" object:0L userInfo: 0L];
}

-(void)createMarkerROIWithWidth:(int)w andHeight:(int)h atPosX:(int)x andY:(int)y
{
	int i,j;
	DCMPix	*curPix = [[viewer pixList] objectAtIndex: [[viewer imageView] curImage]];	
	unsigned char *buffer=(unsigned char*)malloc(w*h*sizeof(unsigned char));
	// clear buffer
	for (i=0;i<w*h;i++)
		buffer[i]=0x00;
	int thickness=[SliderThickness intValue];
	for(j=0;j<h;j++)
	{
		for (i=0;i<thickness;i++)
		{
			buffer[i+j*w]=0xFF;
			buffer[w-i-1+j*w]=0xFF;
		}
	}
	for(i=0;i<w;i++)
	{
		for (j=0;j<thickness;j++)
		{
			buffer[i+j*w]=0xFF;
			buffer[i+h*(w-1)-j*w]=0xFF;
		}
	}
	ROI* theNewROI = [[[ROI alloc] initWithTexture:buffer  textWidth:w textHeight:h textName:@"FrameMarker"
										 positionX:x positionY:y
										  spacingX:[curPix pixelSpacingX]  spacingY:[curPix pixelSpacingY]
									   imageOrigin:NSMakePoint( [curPix originX], [curPix originY])] autorelease];
	free(buffer);
	[[[viewer roiList] objectAtIndex: [[viewer imageView] curImage]] addObject:theNewROI];	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:theNewROI userInfo: 0L];
}
- (IBAction)frameThicknessChange:(id)sender
{
	
}

-(void) dealloc
{
	NSLog(@"MSRGWindowController dealloc");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[msrgSeg release];
	[super dealloc];
}
@end
